variable "cluster_name" {
  description = "Please input the GKE cluster name "
}

variable "cluster_location" {
  description = "Please input the cluster location like us-central1 "
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

variable "project" {
  description = "The Project name"
  default     = "maximal-furnace-202714"
}

variable "gcp_machine_type" {
  description = "The Machine type"
  default     = "n1-standard-2"
}

variable "helm_install_jenkins" {
  description = "Please input whether to install Jenkins by default- true or false"
}
