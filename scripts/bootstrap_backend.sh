#!/bin/bash
set -e

# Configurações - Altere o PROJECT_NAME se desejar
PROJECT_NAME="url-shortener-tf-state"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT_NAME}-${ACCOUNT_ID}"
DYNAMO_TABLE="${PROJECT_NAME}-lock"

echo "Iniciando Bootstrap do Backend Terraform..."
echo "Bucket S3: $BUCKET_NAME"
echo "Tabela DynamoDB: $DYNAMO_TABLE"

# 1. Criar Bucket S3 (se não existir)
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
  aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
  
  # Bloquear acesso público (Segurança Básica)
  aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
  # Habilitar Versionamento (Para recuperação de desastres do state)
  aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
  
  echo "Bucket criado e configurado."
else
  echo " Bucket já existe."
fi

# 2. Criar Tabela DynamoDB para Lock (se não existir)
if ! aws dynamodb describe-table --table-name $DYNAMO_TABLE --region $REGION > /dev/null 2>&1; then
  aws dynamodb create-table \
    --table-name $DYNAMO_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region $REGION
  echo "Tabela de Lock criada."
else
  echo " Tabela de Lock já existe."
fi

echo "Bootstrap concluído! Use os detalhes abaixo no seu backend.tf:"
echo "bucket = \"$BUCKET_NAME\""
echo "dynamodb_table = \"$DYNAMO_TABLE\""
4. Configuração do Provider (Exemplo para Dev) Agora, configure o Terraform para usar essa infraestrutura. Arquivo: environments/dev/main.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # O backend será preenchido dinamicamente ou via arquivo de config parcial
  # mas deixamos o esqueleto aqui.
  backend "s3" {
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # Bucket e Table são passados via -backend-config no init
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "URLShortener"
      Environment = "Dev"
      ManagedBy   = "Terraform"
    }
  }
}
