#! /usr/bin/env bash
set -xe
set -o pipefail

export PROJECT_ID="vault-on-gcp-${RANDOM}"

echo "Creating new GCP project ${PROJECT_ID} ..."
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

# Attach the project to a billing account so chargeable resources can be created
export BILLING_ACCOUNT="$(gcloud beta billing accounts list --limit=1 --format="value(ACCOUNT_ID)")"
gcloud beta billing projects link "${PROJECT_ID}" --billing-account "${BILLING_ACCOUNT}"

# Create a SA with scope limited to the current project and set it up for use
gcloud iam service-accounts create automation-sa --display-name="Automation SA"

# Compute API must be enabled before terraform scripts will work (google_compute_zones data resource prevents tf plan)
# (This also gives some time for the SA to be created)
gcloud services enable --project "${PROJECT_ID}" compute.googleapis.com

# Grant "Owner" so the SA can do anything in this project
# (Ideally this would follow PoLP but this is just a poc...)
SA_EMAIL="$(gcloud iam service-accounts list --filter="email ~ automation-sa" --format="value(email)")"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${SA_EMAIL}" --role=roles/owner

# Generate a SA key so it can be used by terraform & packer
gcloud iam service-accounts keys create key.json --iam-account="${SA_EMAIL}"

# Authenticate using the SA - it will be used from here
gcloud auth activate-service-account --key-file=key.json



# Get current external IP address - used to ensure limited connectivity to GCP resources
EXTERNAL_IP="$(curl -s http://whatismyip.akamai.com/)"

# Set terraform variables
cat > ./bootstrap/terraform.tfvars <<EOF
project_id             = "${PROJECT_ID}"
allowed_external_cidrs = ["${EXTERNAL_IP}/32"]
EOF

cat > ./vault/terraform.tfvars <<EOF
project_id                = "${PROJECT_ID}"
allowed_external_cidrs    = ["${EXTERNAL_IP}/32"]
vault_instance_base_image = "insert_image_name_here"
EOF


# Bootstrap the project using terraform
pushd bootstrap
terraform init
terraform apply -auto-approve
SUBNETWORK="$(terraform output -raw packer_subnetwork)"
popd

# Configure packer parameters
cat > ./packer/vault.auto.pkrvars.hcl <<EOF
project_id = "${PROJECT_ID}"
subnetwork = "${SUBNETWORK}"
EOF

echo "Bootstrap complete!"
