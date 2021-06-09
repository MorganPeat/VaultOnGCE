#! /usr/bin/env bash
set -xe
set -o pipefail

# Remove SA credentials
gcloud auth revoke

# Re-auth back to my master account
gcloud config set account mogpeat@gmail.com

# Delete the project
PROJECT_ID="$(gcloud config get-value core/project)"
if [[ ! $PROJECT_ID =~ vault-on-gcp-.* ]]; then
    echo "Oh no you don't!"
    exit 1
fi

gcloud projects delete $PROJECT_ID --quiet
gcloud beta billing projects unlink "${PROJECT_ID}"


# Tidy up
rm ./key.json
rm ./bootstrap/terraform.tfstate*
rm ./bootstrap/terraform.tfvars
rm ./packer/vault.auto.pkrvars.hcl
rm ./vault/terraform.tfstate*
rm ./vault/terraform.tfvars