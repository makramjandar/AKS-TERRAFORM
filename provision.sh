#!/usr/bin/env bash


# KUBECTL
KUBECTL="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
rm -rf ~/.kube \
&& rm -rf /root/.kube \
&& az aks get-credentials -g "$1" -n "$2" \
&& curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL}/bin/linux/amd64/kubectl \
&& chmod +x ./kubectl \
&& export PATH=/usr/local/bin:$PATH \
&& mv ./kubectl /usr/local/bin/kubectl \
&& cp /usr/local/bin/kubectl /usr/bin/kubectl

# helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh \
&& chmod 700 get_helm.sh \
&& ./get_helm.sh \
&& cp /usr/local/bin/helm /usr/bin/helm \
&& kubectl config use-context "$2" \
&& helm init --upgrade \
&& kubectl create -f helm-rbac.yaml \
&& sleep 120 \
&& kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\""$3"\"

# charts
helm repo add azure-samples https://azure-samples.github.io/helm-charts/ \
&& helm repo add gitlab https://charts.gitlab.io/ \
&& helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/ \
&& helm repo add bitnami https://charts.bitnami.com/bitnami \
&& helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/ \
&& helm repo update \
&& helm install azure-samples/aks-helloworld \
&& wget -qO- https://azuredraft.blob.core.windows.net/draft/draft-v0.16.0-linux-amd64.tar.gz | tar xvz \
&& cp linux-amd64/draft /usr/local/bin/draft && cp linux-amd64/draft /usr/bin/draft \
&& draft init \
&& draft config set registry "$4.azurecr.io"

# kube
kube_major=$(echo ${var.kube_version}|cut -d'.' -f 1-2)
[ "$kube_major" = "1.11" ] || [ "$kube_major" = "1.10" ] || [ "$kube_major" = "1.9" ] && sleep 180 
echo "${var.kube_version}"

# prometheus
helm install coreos/prometheus-operator --name prometheus-operator --wait --namespace monitoring --set global.rbacEnable=false \
&& helm install coreos/kube-prometheus --name kube-prometheus --wait --namespace monitoring --set global.rbacEnable=false
[ "${var.patch_svc_lbr_external_ip}" = "true" ] \
&& kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}' --namespace kube-system \
&& kubectl patch svc aks-helloworld -p '{"spec":{"type":"LoadBalancer"}}' \
&& kubectl patch svc kube-prometheus-grafana -p '{"spec":{"type":"LoadBalancer"}}' --namespace monitoring
echo "${var.patch_svc_lbr_external_ip}"

#suitecrm
kubectl create namespace sugarcrm \
&& helm install --name sugarcrm-dev --set allowEmptyPassword=false,mariadb.rootUser.password=secretpassword,mariadb.db.password=secretpassword stable/suitecrm --namespace sugarcrm \
&& sleep 240
export APP_HOST="$(kubectl get svc --namespace sugarcrm sugarcrm-dev-suitecrm --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")"
export APP_PASSWORD="$(kubectl get secret --namespace sugarcrm sugarcrm-dev-suitecrm -o jsonpath="{.data.suitecrm-password}" | base64 -d)"
export APP_DATABASE_PASSWORD="$(kubectl get secret --namespace sugarcrm sugarcrm-dev-mariadb -o jsonpath="{.data.mariadb-password}" | base64 -d)"
helm upgrade sugarcrm-dev stable/suitecrm --set suitecrmHost="$APP_HOST",suitecrmPassword="$APP_PASSWORD",mariadb.db.password="$APP_DATABASE_PASSWORD"