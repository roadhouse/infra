#!/bin/bash

# Applies the SOPS-encrypted ArgoCD Application manifests from this repository.
# Assumes ArgoCD and the SOPS plugin are already configured.

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}/.."

# Find all top-level YAML files that are likely ArgoCD Apps (excluding plugin/secret configs)
APP_FILES=$(find "${REPO_ROOT}" -maxdepth 1 -name '*.yaml' -not -name '*plugin*' -not -name '*secret*' -print)

if [ -z "${APP_FILES}" ]; then
    echo "🤔 No application manifest files found to apply in ${REPO_ROOT}"
    exit 0
fi

apply_apps() {
    echo "🚢 Applying ArgoCD Application manifests:"
    for app_file in ${APP_FILES}; do
        echo "   📄 Applying $(basename "${app_file}")..."
        # We apply the encrypted file directly. ArgoCD (with the plugin) will handle it.
        kubectl apply -f "${app_file}"
    done
}

echo "☁️ --- Running Application Deployment --- ☁️"
apply_apps
echo "🎉 --- Application Deployment Complete (ArgoCD will sync based on these definitions) --- 🎉"
