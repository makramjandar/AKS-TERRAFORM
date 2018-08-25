variable "cluster_name" {
  description = "Please input the GKE cluster name "
}

variable "cluster_location" {
  description = "Please input the cluster location like us-east1 "
}

variable "node_count" {
  description = "Please enter the node count "
}

variable "master_auth_username" {
  description = "Please enter the master auth username "
}

variable "master_auth_password" {
  description = "Please enter the master auth password "
}

variable "cluster_label" {
  description = "Please enter the cluster label "
}

variable "cluster_tag" {
  description = "Please enter the cluster tag "
}
