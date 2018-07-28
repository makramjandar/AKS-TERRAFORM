variable "resource_group_name" {
  default     = "hclaks"
}
variable "location" {
  default     = "westeurope"
}

variable "client_id" {
  default     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "client_secret" {
  default     = "xxxxxxxxxxxxxxx"
}

variable "cluster_name" {
  default     = "hclaks"
}

variable "dns_prefix" {
  default     = "hclaks"
}

variable "ssh_public_key" {
  default     = "/id_rsa.pub"
}
variable "admin_username" {
  default     = "aksadmin"
}

variable "agent_count" {
  default     = "3"
}
