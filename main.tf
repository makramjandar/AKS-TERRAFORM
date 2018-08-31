resource "azurerm_resource_group" "k8s" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  dns_prefix          = "${var.dns_prefix}"
  kubernetes_version  = "${var.kube_version}"

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.agent_count}"
    vm_size         = "${var.azurek8s_sku}"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}

/**
resource "azurerm_storage_account" "acrstorageacc" {
  name                     = "${var.resource_storage_acct}"
  resource_group_name      = "${azurerm_resource_group.k8s.name}"
  location                 = "${azurerm_resource_group.k8s.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
**/
resource "azurerm_container_registry" "acrtest" {
  name                = "${var.azure_container_registry_name}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  admin_enabled       = true
  sku                 = "Premium"

  /** storage_account_id  = "${azurerm_storage_account.acrstorageacc.id}" **/
}

resource "null_resource" "provision" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.k8s.name} -g ${azurerm_resource_group.k8s.name}"
  }

  provisioner "local-exec" {
    command = "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;"
  }

  provisioner "local-exec" {
    command = "chmod +x ./kubectl;"
  }

  provisioner "local-exec" {
    command = "mv ./kubectl /usr/local/bin/kubectl;"
  }

  provisioner "local-exec" {
    command = "curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh"
  }

  provisioner "local-exec" {
    command = "chmod 700 get_helm.sh"
  }

  provisioner "local-exec" {
    command = "./get_helm.sh"
  }

  provisioner "local-exec" {
    command = "kubectl config use-context ${azurerm_kubernetes_cluster.k8s.name}"
  }

  /**
                                                                          provisioner "local-exec" {
                                                                            command = "echo "$(terraform output kube_config)" > ~/.kube/azurek8s && export KUBECONFIG=~/.kube/azurek8s"
                                                                          } 
                                                                        **/
  provisioner "local-exec" {
    command = "helm init --upgrade"
  }

  provisioner "local-exec" {
    command = "kubectl create -f helm-rbac.yaml"
  }

  provisioner "local-exec" {
    command = <<EOF
            sleep 60
      EOF
  }

  provisioner "local-exec" {
    command = "helm install stable/cert-manager  --set ingressShim.defaultIssuerName=letsencrypt-staging  --set ingressShim.defaultIssuerKind=ClusterIssuer --set rbac.create=false  --set serviceAccount.create=false"
  }

  provisioner "local-exec" {
    command = "kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"${local.username}\""
  }

  /**
                                                            provisioner "local-exec" {
                                                              command = "kubectl create -f azure-load-balancer.yaml"
                                                            }
                                                    **/
  provisioner "local-exec" {
    command = "helm repo add azure-samples https://azure-samples.github.io/helm-charts/ && helm repo add gitlab https://charts.gitlab.io/ && helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/ && helm repo add bitnami https://charts.bitnami.com/bitnami"
  }

  provisioner "local-exec" {
    command = "helm repo update"
  }

  provisioner "local-exec" {
    command = "helm install stable/nginx-ingress --namespace kube-system --set rbac.create=false"
  }

  provisioner "local-exec" {
    command = "helm install azure-samples/aks-helloworld"
  }

  provisioner "local-exec" {
    command = "wget -qO- https://azuredraft.blob.core.windows.net/draft/draft-v0.15.0-linux-amd64.tar.gz | tar xvz"
  }

  provisioner "local-exec" {
    command = "cp linux-amd64/draft /usr/local/bin/draft"
  }

  provisioner "local-exec" {
    command = "draft init"
  }

  provisioner "local-exec" {
    command = "draft config set registry ${azurerm_container_registry.acrtest.name}.azurecr.io"
  }

  provisioner "local-exec" {
    command = "helm repo add brigade https://azure.github.io/brigade"
  }

  provisioner "local-exec" {
    command = "helm install brigade/brigade --name brigade-server"
  }

  provisioner "local-exec" {
    command = <<EOF
            if [ "${var.helm_install_jenkins}" = "true" ]; then
                helm install -n ${azurerm_kubernetes_cluster.k8s.name} stable/jenkins -f jenkins-values.yaml --version 0.16.18
            else
                echo ${var.helm_install_jenkins}
            fi
      EOF

    timeouts {
      create = "20m"
      delete = "20m"
    }
  }

  provisioner "local-exec" {
    command = "git clone https://github.com/coreos/prometheus-operator.git"
  }

  provisioner "local-exec" {
    command = <<EOF
            sleep 240
      EOF
  }

  provisioner "local-exec" {
    command = "cd prometheus-operator && kubectl apply -f bundle.yaml"
  }

  /**
                      provisioner "local-exec" {
                        command = "cd prometheus-operator && helm install helm/prometheus-operator --name prometheus-operator --namespace monitoring --set rbacEnable=false --wait --timeout 1000"

                        timeouts {
                          create = "16m"
                          delete = "16m"
                        }
                      }
                    **/
  provisioner "local-exec" {
    command = "cd prometheus-operator && mkdir -p helm/kube-prometheus/charts"
  }

  provisioner "local-exec" {
    command = "cd prometheus-operator && helm package -d helm/kube-prometheus/charts helm/alertmanager helm/grafana helm/prometheus  helm/exporter-kube-dns helm/exporter-kube-scheduler helm/exporter-kubelets helm/exporter-node helm/exporter-kube-controller-manager helm/exporter-kube-etcd helm/exporter-kube-state helm/exporter-coredns helm/exporter-kubernetes"
  }

  provisioner "local-exec" {
    command = <<EOF
            sleep 60
      EOF
  }

  provisioner "local-exec" {
    command = "cd prometheus-operator && helm install helm/kube-prometheus --name kube-prometheus --wait --namespace monitoring --set global.rbacEnable=false"

    timeouts {
      create = "20m"
      delete = "20m"
    }
  }

  provisioner "local-exec" {
    command = <<EOF
            if [ "${var.patch_svc_lbr_external_ip}" = "true" ]; then
                kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}' --namespace kube-system && kubectl patch svc aks-helloworld -p '{"spec":{"type":"LoadBalancer"}}' && kubectl patch svc kube-prometheus-grafana -p '{"spec":{"type":"LoadBalancer"}}' --namespace monitoring
            else
                echo ${var.patch_svc_lbr_external_ip}
            fi
      EOF
}
}

/**
resource "azurerm_storage_account" "aci-sa" {
  name                     = "${var.resource_storage_acct}"
  resource_group_name      = "${azurerm_resource_group.k8s.name}"
  location                 = "${azurerm_resource_group.k8s.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "aci-share" {
  name = "${var.resource_aci-dev-share}"

  resource_group_name  = "${azurerm_resource_group.k8s.name}"
  storage_account_name = "${azurerm_storage_account.aci-sa.name}"

  quota = 50
}

resource "azurerm_container_group" "aci-helloworld" {
  name                = "${var.resource_aci-hw}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  ip_address_type     = "public"
  dns_name_label      = "${var.resource_dns_aci-label}"
  os_type             = "linux"

  container {
    name   = "hw"
    image  = "seanmckenna/aci-hellofiles"
    cpu    = "0.5"
    memory = "1.5"
    port   = "80"

    environment_variables {
      "NODE_ENV" = "dev"
    }

    command = "/bin/bash -c '/path to/myscript.sh'"

    volume {
      name       = "logs"
      mount_path = "/aci/logs"
      read_only  = false
      share_name = "${var.resource_aci-dev-share}"

      storage_account_name = "${azurerm_storage_account.aci-sa.name}"
      storage_account_key  = "${azurerm_storage_account.aci-sa.primary_access_key}"
    }
  }

  container {
    name   = "sidecar"
    image  = "microsoft/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"
  }

  tags {
    environment = "Dev"
  }
}
**/

