## AKS Settings
AKS_RG=""

## Custom Domain Settings 
CUSTOM_DOMAIN_NAME=""
AKS_APP_DNS_NAME=""

## App FQDN
APP_FQDN="$AKS_APP_DNS_NAME.$CUSTOM_DOMAIN_NAME"
APP_ADMIN_EMAIL=""

## Cert Manager Settings
CERT_MANAGER_TAG=v1.5.4
CERT_MANAGER_IMAGE_CONTROLLER=jetstack/cert-manager-controller
CERT_MANAGER_IMAGE_WEBHOOK=jetstack/cert-manager-webhook
CERT_MANAGER_IMAGE_CAINJECTOR=jetstack/cert-manager-cainjector
