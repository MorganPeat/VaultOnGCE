# Vault on GCE

Demo repository to show how to get HashiCorp Vault up and running in GCP with the minimum amount of fuss.

This code started from, and is based on, the public module https://registry.terraform.io/modules/terraform-google-modules/vault/google/latest.

## Usage

1. Create a new GCP project using the Cloud Console (https://console.cloud.google.com/)

1. Create a new Service Account with "Owner" permission using the Cloud Console (https://console.cloud.google.com/iam-admin/serviceaccounts)

1. Generate a json key for the SA and save it to a file.

1. Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to the SA key file so the GCP API can authenticate (e.g. `export GOOGLE_APPLICATION_CREDENTIALS="/c/Users/morga/Documents/Work/Github/VaultOnGCE/key.json"`).

1. Run `terraform apply`

## Issues & TODOs

1. The compute API must be enabled manually. This is because the module contains the google provider block so cannot depend on a terraform enablement of the service.

1. Resource graph incorrect: e.g. "Error 403: Cloud Key Management Service (KMS) API has not been used in project 560570260940 before or it is disabled." succeeds on re-apply

1. TLS managed by the module - keys in state

1. Network managed by module

1. Vault open to everyone on the internet

1. Packer!

1. Remote tf state - GCS? TF Cloud?