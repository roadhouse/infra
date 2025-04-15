#!/bin/bash

# Script to deploy Cloudflare Tunnel application to ArgoCD
# This includes creating the secret from Cloudflare tunnel credentials

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}/.."
APP_FILE="${REPO_ROOT}/cloudflare-tunnel.yaml"
NAMESPACE="cloudflare"

create_cloudflare_secret() {
    echo "🔐 Creating Cloudflare tunnel credentials secret..."
    
    if [ -z "$1" ]; then
        echo "❌ Error: No credential file provided."
        echo "Usage: $0 /path/to/tunnel-credentials.json"
        exit 1
    fi
    
    CRED_FILE="$1"
    
    if [ ! -f "${CRED_FILE}" ]; then
        echo "❌ Error: Credential file ${CRED_FILE} does not exist."
        exit 1
    fi
    
    # Read the credentials file
    TUNNEL_CREDS=$(cat "${CRED_FILE}")
    TUNNEL_ID=$(echo "${TUNNEL_CREDS}" | grep -o '"TunnelID":"[^"]*"' | cut -d '"' -f 4)
    #
    # Create the secret
    echo "🔑 Creating Kubernetes secret for Cloudflare tunnel..."
    kubectl create secret generic cloudflare-tunnel \
        --from-file=credentials.json="${TUNNEL_CREDS}" \
        -n "${NAMESPACE}"
    
    echo "✅ Cloudflare tunnel secret created successfully with ID: ${TUNNEL_ID}"
}

deploy_cloudflare_tunnel() {
    echo "🚀 Deploying Cloudflare tunnel application..."
    kubectl apply -f "${APP_FILE}"
    echo "✅ Cloudflare tunnel application deployed successfully"
}

echo "☁️ --- Cloudflare Tunnel Deployment --- ☁️"

# Check if credential file was provided
if [ $# -eq 1 ]; then
    create_cloudflare_secret "$1"
else
    echo "ℹ️ No credential file provided. Skipping secret creation."
    echo "ℹ️ To create the secret, run: $0 /path/to/tunnel-credentials.json"
    echo "ℹ️ Continuing with application deployment..."
fi

deploy_cloudflare_tunnel

echo "🎉 --- Cloudflare Tunnel Deployment Complete --- 🎉"
