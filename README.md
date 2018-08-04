Table of Contents (Azure Kubernetes Service with Terraform)
=================

1. [ServicePrincipal and Subscription ID](#serviceprincipal-and-subscription-id)
2. [Install terraform locally](#install-terraform-locally)
3. [Automatic provisioning](#automatic-provisioning)
   * [All in one with docker azure-cli-python](#all-in-one-with-docker-azure-cli-python)
   * [Semi-auto with docker azure-cli-python](#semi-auto-with-docker-azure-cli-python)
4. [Manual stepped provisioning](#manual-stepped-provisioning)
   * [ Run Azure cli container and copy terraform binary along with id_rsa to it](#run-azure-cli-container-and-copy-terraform-binary-along-with-id_rsa-to-it)
   * [Clone this repo in the azure-cli-python container](#clone-this-repo-in-the-azure-cli-python-container)
   * [Fill in the variables.tf with default values](#fill-in-the-variables-file-with-default-values)
   * [Terraform for aks](#terraform-for-aks)
   * [kube_config](#kube_config)
   * [Sanity](#sanity)

### ServicePrincipal and Subscription ID
`docker run -ti docker4x/create-sp-azure aksadmin`

`Your access credentials ==================================================`

`AD ServicePrincipal App ID:       xxxxxx `

`AD ServicePrincipal App Secret:   xxxxxx `

`AD ServicePrincipal Tenant ID:   xxxxxx`

### Install terraform locally
`wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip -O temp.zip; unzip temp.zip; rm temp.zip ;sudo cp terraform /usr/local/bin`
### Automatic provisioning 
#### All in one with docker azure-cli-python
Please note **docker** should be installed with **terraform** binary and your **id_rsa.pub** present in directory for running the following.

>**Terraform locally installed has binary in `/usr/local/bin`**

**`wget https://raw.githubusercontent.com/dwaiba/aks-terraform/master/create_cluster.sh && chmod +x create_cluster && ./create_cluster.sh`**

Recreate new cluster - Please note **terraform** binary and your **id_rsa.pub** should be present in directory

`docker run -dti --name=azure-cli-python-$yournameorBU --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python-$yournameorBU:/ && docker cp id_rsa.pub azure-cli-python-$yournameorBU:/ && docker exec -ti azure-cli-python-$yournameorBU bash -c "az login && git clone https://github.com/dwaiba/aks-terraform && cp id_rsa.pub /aks-terraform/ && cp terraform /usr/bin && cd /aks-terraform/ && terraform init && terraform plan -out run.plan && terraform apply "run.plan" && bash"`

Terraform will now prompt for the 6 variables as below in sequence:

* resource_group_name
* client_id
* client_secret
* cluster_name
* dns_prefix
* azure_container_registry_name

Values and conventions for the 6 variables are as follows : 

* resource_group_name as "--org--_aks_--yournameorBU--"
* client_id which is the sp client Id
* client_secret which is the secret for the above as creted in pre-req
* cluster_name as "--org--_aks_--yournameorBU--"
* dns_prefix as "--org--aks--yournameorBU--"
* azure_container_registry_name as "alphanumeric"
> The DNSPrefix must contain between 3 and 45 characters and can contain only letters, numbers, and hyphens.  It must start with a letter and must end with a letter or a number. 

> Only alpha numeric characters only are allowed in azure_container_registry_name.

>Expected account_tier for storage to be one of **Standard** **Premium** with max **GRS** and **not RAGRS**. Azure Container Registry sku should be **Classic** or **Premium** according to storage account. 
  
After Cluster creation  all you need to do is perform "kubectl get svc" to get url for jenkins and obtain jenkins password as follows- preferably from within the container prompt post creation:

`printf $(kubectl get secret --namespace default hclaks-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d);echo`


#### Semi-auto with docker azure-cli-python
Please destroy cluster as such :
`export yournameorBU="yournameorBU"`

`docker exec -ti azure-cli-python-$yournameorBU bash -c "az login && cd /aks-terraform && terraform destroy && bash"`

`docker kill azure-cli-python-$yournameorBU`

`docker rm azure-cli-python-$yournameorBU`

Recreate new cluster - Please note **terraform** binary and your **id_rsa.pub** should be present in directory

`docker run -dti --name=azure-cli-python-$yournameorBU --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python-$yournameorBU:/ && docker cp id_rsa.pub azure-cli-python-$yournameorBU:/ && docker exec -ti azure-cli-python-$yournameorBU bash -c "az login && git clone https://github.com/dwaiba/aks-terraform && cp id_rsa.pub /aks-terraform/ && cp terraform /usr/bin && cd /aks-terraform/ && terraform init && terraform plan -out run.plan && terraform apply "run.plan" && bash"`

Terraform will now prompt for the 6 variables as below in sequence:

* resource_group_name
* client_id
* client_secret
* cluster_name
* dns_prefix
* azure_container_registry_name

Values and conventions for the 6 variables are as follows : 

* resource_group_name as "--org--_aks_--yournameorBU--"
* client_id which is the sp client Id
* client_secret which is the secret for the above as creted in pre-req
* cluster_name as "--org--_aks_--yournameorBU--"
* dns_prefix as "--org--aks--yournameorBU--"
* azure_container_registry_name as "alphanumeric"
> The DNSPrefix must contain between 3 and 45 characters and can contain only letters, numbers, and hyphens.  It must start with a letter and must end with a letter or a number. 

> Only alpha numeric characters only are allowed in azure_container_registry_name.

>Expected account_tier for storage to be one of **Standard** **Premium** with max **GRS** and **not RAGRS**. Azure Container Registry sku should be **Classic** or **Premium** according to storage account. 
  
After Cluster creation  all you need to do is perform "kubectl get svc" to get url for jenkins and obtain jenkins password as follows- preferably from within the container prompt post creation:

`printf $(kubectl get secret --namespace default hclaks-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d);echo`


### Manual stepped provisioning
#### Run Azure cli container and copy terraform binary along with id_rsa to it

`docker run -dti --name=azurecli-python --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python:/ && docker cp ~/.ssh/id_rsa azure-cli-python:/ && docker exec -ti azure-cli-python bash -c "az login && bash"`

#### Clone this repo in the azure-cli-python container
`git clone https://github.com/dwaiba/aks-terraform`

`curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;`

Optionally, you can also install kubectl locally. This repo installs kubectl in the azure-cli-python container.


`chmod +x ./kubectl;`

`mv ./kubectl /usr/local/bin/kubectl;`

`mv /id_rsa.pub /aks-terraform;`

#### Fill in the variables file with default values

#### Terraform for aks
`mv ~/terraform aks-terraform/`
`cd aks-terraform`
`terraform init`

`terraform plan -out run.plan`

`terraform apply "run.plan"`

#### kube_config
`echo "$(terraform output kube_config)" > ~/.kube/azurek8s`

Also one can echo and copy content to local kubectl config.


`export KUBECONFIG=~/.kube/azurek8s`

#### Sanity
`kubectl get nodes`

`kubectl proxy`

Dashboard available at `http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default`
