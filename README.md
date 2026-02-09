#Inicio do projeto

O problema do "ovo e da galinha": O Terraform precisa de um Bucket S3 para guardar seu estado, mas quem cria esse Bucket? 
Solução: Criaremos um script de bootstrap em Bash que usa a AWS CLI para provisionar esses recursos iniciais apenas uma vez. 
Isso garante que qualquer desenvolvedor novo possa clonar o repo, rodar o script e estar pronto para o terraform init.

Dê permissão de execução ao script (chmod +x scripts/bootstrap_backend.sh) e rode-o
