data "google_container_engine_versions" "gce_version_zone" {
  zone = "${var.cluster_location}-a"
}

resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${var.cluster_location}-a"
  initial_node_count = "${var.node_count}"
  min_master_version = "${data.google_container_engine_versions.gce_version_zone.latest_node_version}"
  node_version       = "${data.google_container_engine_versions.gce_version_zone.latest_node_version}"

  additional_zones = [
    "${var.cluster_location}-b",
    "${var.cluster_location}-c",
  ]

  master_auth {
    username = "${var.master_auth_username}"
    password = "${var.master_auth_password}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      foo = "${var.cluster_label}"
    }

    tags = ["${var.cluster_tag}"]
  }
}

resource "null_resource" "provision" {
  provisioner "local-exec" {
    command = <<EOF
            sleep 30
      EOF
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.cluster_location}-a --project ${var.project}"
  }

  provisioner "local-exec" {
    command = "kubectl create serviceaccount -n kube-system tiller && kubectl create clusterrolebinding tiller-binding --clusterrole=cluster-admin --serviceaccount kube-system:tiller"
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
    command = "helm init --service-account tiller --upgrade"
  }

  provisioner "local-exec" {
    command = <<EOF
            if [ "${var.helm_install_jenkins}" = "true" ]; then
                helm install -n ${var.cluster_name} stable/jenkins -f ../jenkins-values.yaml --version 0.16.18
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
    command = <<EOF
            if [ "${var.patch_svc_lbr_external_ip}" = "true" ]; then
                kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"LoadBalancer"}}' --namespace kube-system
            else
                echo ${var.patch_svc_lbr_external_ip}
            fi
      EOF
  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster.
output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}
