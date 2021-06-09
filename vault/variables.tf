#
# Project settings
#

variable "project_id" {
  type        = string
  description = "Project ID in which to deploy"
}

variable "region" {
  type        = string
  description = "Region in which to deploy"

  default = "europe-west1" # Belgium, slightly cheaper than London
}

variable "project_services" {
  type        = set(string)
  description = "List of services to enable on the project where Vault will run. These services are required in order for this Vault setup to function."

  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

#
# Network settings
#

variable "allowed_external_cidrs" {
  type        = set(string)
  description = "List of CIDR blocks to allow access to the Vault nodes. Since the load balancer is a pass-through load balancer, this must also include all IPs from which you will access Vault. The default is unrestricted (any IP address can access Vault). It is recommended that you reduce this to a smaller list."

  default = ["0.0.0.0/0"]
}

#
# Vault server settings
#

variable "vault_instance_base_image" {
  type        = string
  description = "Baked OS image to use for Vault VM"
}

