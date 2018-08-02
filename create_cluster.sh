read -p "Enter your name or BU Name for aks creation: " yournameorBU
echo $yournameorBU
docker run -dti --name=azure-cli-python-$yournameorBU --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python-$yournameorBU:/ && docker cp id_rsa.pub azure-cli-python-$yournameorBU:/ && docker exec -ti azure-cli-python-$yournameorBU bash -c "az login && git clone https://github.com/dwaiba/aks-terraform && cp id_rsa.pub /aks-terraform/ && cp terraform /usr/bin && cd /aks-terraform/ && terraform init && terraform plan -out run.plan && terraform apply "run.plan" && bash"
