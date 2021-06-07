
variable "project_id" {
  type        = string
  description = "Project ID in which to deploy"
}

variable "region" {
  type        = string
  description = "Region in which to deploy"

  default = "europe-west1" # Belgium, slightly cheaper than London
}
