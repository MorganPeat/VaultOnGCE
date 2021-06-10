provider "tfe" {
  hostname = "app.terraform.io"
}

resource "tfe_workspace" "vault" {
  name         = var.project_id
  organization = "morgan-peat"
}

resource "tfe_variable" "vault_project_id" {
  key          = "project_id"
  value        = var.project_id
  category     = "terraform"
  workspace_id = tfe_workspace.vault.id
}

resource "tfe_variable" "vault_external_cidrs" {
  key          = "allowed_external_cidr"
  value        = var.allowed_external_cidr
  category     = "terraform"
  workspace_id = tfe_workspace.vault.id
}

resource "tfe_variable" "vault_image" {
  key          = "vault_instance_base_image"
  value        = var.vault_instance_base_image
  category     = "terraform"
  workspace_id = tfe_workspace.vault.id
}

resource "tfe_variable" "google_creds" {
  key          = "GOOGLE_OAUTH_ACCESS_TOKEN"
  value        = var.google_oath_token
  category     = "env"
  workspace_id = tfe_workspace.vault.id

  sensitive = true
}
