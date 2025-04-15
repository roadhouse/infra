#!/bin/bash

# Script to deploy Wallabag application to ArgoCD

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}/.."
APP_FILE="${REPO_ROOT}/wallabag.yaml"

deploy_wallabag() {
    echo "📚 Deploying Wallabag application..."
    kubectl apply -f "${APP_FILE}"
    echo "✅ Wallabag application deployed successfully"
}

echo "☁️ --- Wallabag Application Deployment --- ☁️"
deploy_wallabag
echo "🎉 --- Wallabag Application Deployment Complete --- 🎉"
