#!/bin/bash

# Applies the ArgoCD SOPS Plugin configuration to the cluster.
# IMPORTANT: Ensure your PRIVATE age key is correctly placed in
#            ../sops-age-key-secret.yaml before running this script!

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT="${SCRIPT_DIR}/.."
ARGOCD_NAMESPACE="argocd"
SECRET_FILE="${REPO_ROOT}/sops-age-key-secret.yaml"
CONFIGMAP_FILE="${REPO_ROOT}/argocd-sops-plugin-configmap.yaml"
PATCH_FILE="${REPO_ROOT}/argocd-sops-plugin-patch.yaml"

check_private_key() {
    echo "🔑 Checking for private key placeholder in ${SECRET_FILE}..."
    if grep -q "AGE-SECRET-KEY-...." "${SECRET_FILE}" || ! grep -q "AGE-SECRET-KEY-" "${SECRET_FILE}"; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "🚨 ERROR: Private key placeholder found or key missing in ${SECRET_FILE} 🚨"
        echo "Please EDIT the file '${SECRET_FILE}' and replace the placeholder"
        echo "line under 'keys.txt:' with your ACTUAL private age key."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
        exit 1
    fi
    echo "✅ Private key seems to be present in ${SECRET_FILE} (basic check passed)."
}

apply_configs() {
    echo "📄 Applying SOPS Plugin ConfigMap..."
    kubectl apply -f "${CONFIGMAP_FILE}"

    echo "🔐 Applying SOPS Age Key Secret..."
    kubectl apply -f "${SECRET_FILE}"

    echo "🛠️ Patching ArgoCD Repo Server deployment for SOPS plugin..."
    kubectl patch deployment argocd-repo-server -n "${ARGOCD_NAMESPACE}" --patch-file "${PATCH_FILE}"

    echo "⏳ Waiting for deployment rollout..."
    kubectl rollout status deployment/argocd-repo-server -n "${ARGOCD_NAMESPACE}" --timeout=300s
}

echo "🧩 --- Running ArgoCD SOPS Plugin Setup --- 🧩"
check_private_key
apply_configs
echo "🎉 --- ArgoCD SOPS Plugin Setup Complete --- 🎉"
