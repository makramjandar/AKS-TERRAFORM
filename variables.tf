variable "resource_group_name" {
  default     = "hclaks"
}
variable "location" {
  default     = "westeurope"
}

variable "client_id" {
  default     = "68865d62-eae7-4873-ac84-2b3a0bc35344"
}

variable "client_secret" {
  default     = "3fUpt2Fmvl6RWnLZSJUSSoQfj1hjPatJ"
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

variable "resource_storage_acct" {
  default     = "acisa12345"
}

variable "resource_aci-dev-share" {
  default     = "aci-dev-share"
}
variable "resource_aci-hw" {
  default     = "aci-helloworld"
}
variable "resource_dns_aci-label" {
  default     = "aci-dev-hw"
}
