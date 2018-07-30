# aks-terraform (Azure Kubernetes Service with Terraform)


Table of Contents
=================

1. [ServicePrincipal and Subscription ID](#serviceprincipal-and-subscription-id)
2. [Install terraform locally](#install-terraform-locally)
3. [ Run Azure cli container and  copy terraform binary along with id_rsa to it](#run-azure-cli-container-and-copy-terraform-binary-along-with-id_rsa-to-it)
4. [Clone this repo in the azure-cli-python container and install kubectl](#clone-this-repo-in-the-azure-cli-python-container-and-install-kubectl)
5. [Fill in the variables.tf](#fill-in-the-variables-file)
6. [Terraform for aks](#terraform-for-aks)
7. [kube_config](#kube_config)
8. [Sanity](#sanity)

### ServicePrincipal and Subscription ID
`docker run -ti docker4x/create-sp-azure openshiftsp`

`Your access credentials ==================================================`

`AD ServicePrincipal App ID:       xxxxxx `

`AD ServicePrincipal App Secret:   xxxxxx `

`AD ServicePrincipal Tenant ID:   xxxxxx`

### Install terraform locally
`wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip -O temp.zip; unzip temp.zip; rm temp.zip ;sudo cp terraform /usr/local/bin`

### Run Azure cli container and copy terraform binary along with id_rsa to it

`docker run -dti --name=azurecli-python --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python:/ && docker cp ~/.ssh/id_rsa azure-cli-python:/ && docker exec -ti azure-cli-python bash -c "az login && bash"`

### Clone this repo in the azure-cli-python container and install kubectl
`git clone https://github.com/dwaiba/aks-terraform`

`curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;`

`chmod +x ./kubectl;`

`mv ./kubectl /usr/local/bin/kubectl;`

### Fill in the variables file

### Terraform for aks
`mv ~/terraform aks-terraform/`
`cd aks-terraform`
`terraform init`

`terraform plan -out run.plan`

`terraform apply "run.plan"`

### kube_config
`echo "$(terraform output kube_config)" > ~/.kube/azurek8s`

`export KUBECONFIG=~/.kube/azurek8s`

### Sanity
`kubectl get nodes`

`kubectl proxy`

Dashboard available at `http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default`
