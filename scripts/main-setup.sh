#!/bin/bash

# Main setup script to orchestrate the installation of tools, ArgoCD,
# the SOPS plugin, and application deployment.

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "==========================================="
echo "✨ Starting Full ArgoCD + SOPS Setup ✨"


echo "
🔧 --- Step 0: Installing Required Tools --- 🔧"
"${SCRIPT_DIR}/00-install-tools.sh"

echo "
🚀 --- Step 1: Installing ArgoCD --- 🚀"
"${SCRIPT_DIR}/01-install-argocd.sh"

echo "
🧩 --- Step 2: Setting up ArgoCD SOPS Plugin --- 🧩"
# IMPORTANT: This step requires manual preparation of sops-age-key-secret.yaml
"${SCRIPT_DIR}/02-setup-sops-plugin.sh"

echo "
☁️ --- Step 3: Deploying Applications via ArgoCD Definitions --- ☁️"
echo "
🌐 --- Step 3.1: Deploying Cloudflare Tunnel --- 🌐"
echo "Note: To create Cloudflare tunnel secret, provide the credentials file path:"
echo "${SCRIPT_DIR}/deploy-cloudflare-tunnel.sh /path/to/tunnel-credentials.json"
"${SCRIPT_DIR}/deploy-cloudflare-tunnel.sh"

echo "
📚 --- Step 3.2: Deploying Wallabag Application --- 📚"
"${SCRIPT_DIR}/deploy-wallabag.sh"

echo "
==========================================="
echo "🎉 Setup Complete! 🎉"
echo "ArgoCD should now be running and configured with the SOPS plugin."
echo "It will begin syncing the applications defined in the repository."
echo "Monitor sync status via ArgoCD UI or CLI."
