#! /usr/bin/env bash
set -e
set -o pipefail

# Permission the terraform CLI for Terraform Cloud
export TERRAFORM_CONFIG="/c/Users/morga/AppData/Roaming/terraform.d/credentials.tfrc.json"

# Show output in color
green=`tput setaf 2`
reset=`tput sgr0`

# Create a random(-ish) new project ID
export PROJECT_ID="vault-on-gcp-${RANDOM}"




echo "${green}**************************************************"
echo "Creating new GCP project ${PROJECT_ID} ..."
echo "**************************************************${reset}"

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
# Terraform uses Application Default Credentials which can be picked up using this env var
export GOOGLE_APPLICATION_CREDENTIALS="$(realpath key.json)"

# Grab an Oath token for the SA so it can be used to authN Terraform Cloud vs GCP APIs
export GOOGLE_OATH_TOKEN="$(gcloud auth application-default print-access-token)"




echo "${green}**************************************************"
echo "Bootstrapping the project using terraform"
echo "**************************************************${reset}"


# Get current external IP address - used to ensure limited connectivity to external-facing GCP resources
EXTERNAL_IP="$(curl -s http://whatismyip.akamai.com/)"

# Construct the name of the packer image - means it can be pre-set as a workspace variable by bootsrapper
IMAGE_NAME="${PROJECT_ID}-${RANDOM}"

# Set terraform variables
# Nasty use of oath token - would love to use vault here :(
cat > ./bootstrap/terraform.tfvars <<EOF
project_id                = "${PROJECT_ID}"
allowed_external_cidr     = "${EXTERNAL_IP}/32"
vault_instance_base_image = "${IMAGE_NAME}"
google_oath_token         = "${GOOGLE_OATH_TOKEN}"
EOF


pushd bootstrap
terraform init
terraform apply -auto-approve
SUBNETWORK="$(terraform output -raw packer_subnetwork)"
popd




echo "${green}**************************************************"
echo "Baking Vault image using Packer"
echo "**************************************************${reset}"


# Configure packer parameters
cat > ./packer/vault.auto.pkrvars.hcl <<EOF
project_id = "${PROJECT_ID}"
subnetwork = "${SUBNETWORK}"
image_name = "${IMAGE_NAME}"
EOF

pushd packer
packer init .
packer build .
popd



echo "${green}**************************************************"
echo "Creating the Vault cluster"
echo "**************************************************${reset}"

# Configure tf cloud backend for vault workspace - workspace name is unique to this project
cat > ./vault/backend.hcl <<EOF
organization = "morgan-peat"
workspaces { name = "${PROJECT_ID}" }
EOF


pushd vault

terraform init -backend-config=backend.hcl -migrate-state
terraform apply -auto-approve

LB_ADDRESS="$(terraform output -raw lb_address)"
LB_PORT="$(terraform output -raw lb_port)"
terraform output -raw ca_cert > ca.crt

echo "${green}"
echo "export VAULT_CACERT=\"./vault/ca.crt\""
echo "export VAULT_ADDR=\"https://${LB_ADDRESS}:${LB_PORT}\""
echo "export VAULT_TOKEN="
echo "${reset}"

popd

echo "${green}**************************************************"
echo "Bootstrap complete!"
echo "**************************************************${reset}"

