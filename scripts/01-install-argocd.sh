#!/bin/bash

# Installs ArgoCD into the currently configured Kubernetes cluster

set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="stable" # Or specify a version like "v2.4.0"

install_argocd() {
    echo "🔍 Checking if ArgoCD namespace '${ARGOCD_NAMESPACE}' exists..."
    if kubectl get namespace "${ARGOCD_NAMESPACE}" &> /dev/null; then
        echo "✅ ArgoCD namespace '${ARGOCD_NAMESPACE}' already exists. Skipping creation."
    else
        echo "✨ Creating ArgoCD namespace '${ARGOCD_NAMESPACE}'..."
        kubectl create namespace "${ARGOCD_NAMESPACE}"
    fi

    echo "📄 Applying ArgoCD manifests (version: ${ARGOCD_VERSION})..."
    kubectl apply -n "${ARGOCD_NAMESPACE}" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

    echo "⏳ Waiting briefly for ArgoCD resources to settle..."
    sleep 15

    echo "📊 Checking ArgoCD server deployment status..."
    kubectl wait --for=condition=available deployment/argocd-server -n "${ARGOCD_NAMESPACE}" --timeout=300s

    echo "✅ ArgoCD installation appears successful."
    echo "ℹ️ Note: You may need to configure ingress/port-forwarding and retrieve the admin password separately."
    echo "🔗 See: https://argo-cd.readthedocs.io/en/stable/getting_started/"
}

echo "🚀 --- Running ArgoCD Installation --- 🚀"
install_argocd
echo "🎉 --- ArgoCD Installation Complete --- 🎉"
