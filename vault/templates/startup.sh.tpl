#! /usr/bin/env bash
set -xe
set -o pipefail

# Only run the script once
if [ -f ~/.startup-script-complete ]; then
  echo "Startup script already ran, exiting"
  exit 0
fi

# Data
LOCAL_IP="$(curl -sf -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)"

# Deps
export DEBIAN_FRONTEND=noninteractive


# Vault config
mkdir -p /etc/vault.d
mkdir /etc/vault.d/plugins
cat <<"EOF" > /etc/vault.d/config.hcl
${config}
EOF
chmod 0600 /etc/vault.d/config.hcl

# Sub in local IP
# $$ is correct here because we are in terraform template
sed -i "s/LOCAL_IP/$${LOCAL_IP}/g" /etc/vault.d/config.hcl

# Service environment
cat <<"EOF" > /etc/vault.d/vault.env
VAULT_ARGS=
EOF
chmod 0600 /etc/vault.d/vault.env

# Download TLS files from GCS
mkdir -p /etc/vault.d/tls
gsutil cp "gs://${vault_tls_bucket}/ca.crt" /etc/vault.d/tls/ca.crt
gsutil cp "gs://${vault_tls_bucket}/vault.crt" /etc/vault.d/tls/vault.crt
gsutil cp "gs://${vault_tls_bucket}/vault.key" /etc/vault.d/tls/vault.key

# Disabled as GCS access is restricted and the TLS certs are held in a separate project
# Decrypt the Vault private key
#base64 --decode < /etc/vault.d/tls/vault.key.enc | gcloud kms decrypt \
#  --project="$#{kms_project}" \
#  --key="$#{kms_crypto_key}" \
#  --plaintext-file=/etc/vault.d/tls/vault.key \
#  --ciphertext-file=-

# Make sure Vault owns everything
chmod 700 /etc/vault.d/tls
chmod 600 /etc/vault.d/tls/vault.key
chown -R vault:vault /etc/vault.d
#rm /etc/vault.d/tls/vault.key.enc

# Make audit files
mkdir -p /var/log/vault
touch /var/log/vault/{audit,server}.log
chmod 0640 /var/log/vault/{audit,server}.log
chown -R vault:adm /var/log/vault

# Add the TLS ca.crt to the trusted store so plugins dont error with TLS
# handshakes
cp /etc/vault.d/tls/ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

systemctl daemon-reload
systemctl enable vault
systemctl start vault

## AT THIS POINT VAULT HEALTH CHECKS SHOULD START PASSING

# Setup vault env
cat <<"EOF" > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:${vault_port}"

# Ignore history from any Vault commands
export HISTIGNORE="&:vault*"
EOF
chmod 644 /etc/profile.d/vault.sh
source /etc/profile.d/vault.sh


systemctl restart rsyslog

systemctl enable google-fluentd
systemctl restart google-fluentd

systemctl enable stackdriver-agent
service stackdriver-agent restart


# Signal this script has run
touch ~/.startup-script-complete
