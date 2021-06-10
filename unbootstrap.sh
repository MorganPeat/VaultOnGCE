#! /usr/bin/env bash
set -xe
set -o pipefail

# Destroy infra
pushd vault
terraform destroy -auto-approve || true
popd

pushd bootstrap
terraform destroy -auto-approve
popd


# Remove SA credentials
gcloud auth revoke

# Re-auth back to my master account
#gcloud config set account mogpeat@gmail.com
gcloud config set account betty.thedog.peat@gmail.com

# Delete the project
PROJECT_ID="$(gcloud config get-value core/project)"
if [[ ! $PROJECT_ID =~ vault-on-gcp-.* ]]; then
    echo "Oh no you don't!"
    exit 1
fi

gcloud projects delete $PROJECT_ID --quiet
gcloud beta billing projects unlink "${PROJECT_ID}"


# Tidy up
rm ./key.json || true
rm ./bootstrap/terraform.tfstate* || true
rm ./bootstrap/terraform.tfvars || true
rm ./packer/vault.auto.pkrvars.hcl || true
rm ./vault/terraform.tfstate* || true
rm ./vault/terraform.tfvars || true
rm ./vault/ca.crt || true
