#!/usr/bin/env bash
#set -eu
#docker run -ti docker4x/create-sp-azure:latest poc-aks poc-aks westeurope
#https://github.com/dwaiba/aks-terraform

SP_NAME='aksadmin'
SP_OBJECT=$(az ad sp create-for-rbac -n $SP_NAME)
SP_ID=$(echo "$SP_OBJECT" | jq -r .appId)
SP_PWD=$(echo "$SP_OBJECT" | jq -r .password)
PUB_PATH="${1:-"$HOME/.ssh/id_rsa.pub"}" ; shift
TF_VER="${1:-'1.0.11'}" ; shift

run_it () {
  RELEASE="0.1"
  
  echo " +++++ $RELEASE"
  
  TF_URL="https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip"

  # Let's display everything on stderr.
  #exec 1>&2
  echo "============"
  echo -e "Please note that docker should be installed local along with the terraform binary and your id_rsa.pub should be present in the present dir. and keep your Azure client_id and secret handy. Happy k8sing !\n"
  read -rp "Enter your name or BU Name for aks creation: " yournameorBU
  echo "$yournameorBU"

  docker run -dti --name=azure-cli-python-$yournameorBU --restart=always mcr.microsoft.com/azure-cli
  docker cp "$(pwd)" "azure-cli-python-$yournameorBU:/root/aks-terraform"
  docker cp "$PUB_PATH" "azure-cli-python-$yournameorBU:/root/aks-terraform"

  docker exec -ti "azure-cli-python-$yournameorBU" bash -c "
    az login \
    && cd ~/aks-terraform \
    && wget $TF_URL -O temp.zip \
    && unzip temp.zip \
    && mv terraform /usr/bin \
    && export TF_VAR_client_id=$SP_ID TF_VAR_client_secret=$SP_PWD \
    && terraform init \
    && terraform plan -out run.plan \
    && terraform apply run.plan \
    && bash
    "
  trap - EXIT
}

run_it "$@"
#az ad sp delete --id $SP_ID