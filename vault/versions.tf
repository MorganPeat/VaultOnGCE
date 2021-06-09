terraform {
  required_version = ">= 0.12.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.69.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "2.1.1"
    }

  }
}