# Packer

Bakes a GCP VM image with Vault

## Resources

1. Packer creates a VM in the specified zone, using a bog-standard GCP Debian 10 image

1. Packer connects via SSH (port 22 opened by the bootstrapper)

1. Configuration bash script is copied across and executed. This is so that the script can be run using `sudo`

1. Vault version to install is passed via parameter

1. Installation script pre-installs software (Vault & Stackdriver) and pre-configures as much as it can (i.e. anything that won't vary by environment)

![Vault on GCE](../vault-on-gce-packer.png "Vault on GCE")