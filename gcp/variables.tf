variable "var.cluster_name" {
  description = "Please input the GKE cluster name "
}

variable "var.cluster_location" {
  description = "Please input the cluster location like us-east1 "
}

variable "var.node_count" {
  description = "Please enter the node count "
}

variable "var.master_auth_username" {
  description = "Please enter the master auth username "
}

variable "var.master_auth_password" {
  description = "Please enter the master auth password "
}

variable "var.cluster_label" {
  description = "Please enter the cluster label "
}

variable "var.cluster_tag" {
  description = "Please enter the cluster tag "
}
