# Cannot hard-code plugin versions due to https://github.com/hashicorp/packer-plugin-googlecompute/issues/15
/*
packer {
  required_plugins {
    googlecompute = {
      version = "0.0.1-pre-3"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}
*/



###########################


variable "project_id" {
  type = string
}

variable "image_name" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "vault_version" {
  type    = string
  default = "1.6.0"
}

###########################


source "googlecompute" "vault" {
  image_name = var.image_name

  project_id = var.project_id
  zone       = "europe-west1-c"

  # Packer subnet controls who can SSH
  subnetwork = var.subnetwork
  tags       = ["allow-ssh"]

  machine_type = "e2-standard-2"
  disk_size    = 50
  ssh_username = "packer"

  # Base off latest image in the family
  source_image_project_id = ["debian-cloud"]
  source_image_family     = "debian-10"
}


###########################


build {
  sources = [
    "source.googlecompute.vault"
  ]

  # Configuration script is copied over so it can run under sudo
  provisioner "file" {
    source      = "./configure_vault.sh"
    destination = "/tmp/configure_vault.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "VAULT_VERSION=${var.vault_version}",
    ]
    inline = ["sudo --preserve-env bash /tmp/configure_vault.sh"]
  }
}
