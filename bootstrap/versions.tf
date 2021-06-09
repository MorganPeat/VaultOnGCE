terraform {
  required_version = ">= 0.12.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.71.0"
    }
  }
}