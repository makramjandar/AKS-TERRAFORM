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

