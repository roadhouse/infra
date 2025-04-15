#!/bin/bash

# Installs age and sops CLIs

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
SOPS_VERSION="v3.7.3"
ARCH="amd64"
# ---------------------

install_age() {
    if command -v age &> /dev/null; then
        echo "✅ age already installed."
        return
    fi
    echo "⏳ Installing age..."
    sudo apt-get update && sudo apt-get install -y age
}

install_sops() {
    if command -v sops &> /dev/null; then
        echo "✅ sops already installed."
        return
    fi
    echo "⏳ Installing sops ${SOPS_VERSION}..."
    local sops_url="https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH}"
    local install_path="/usr/local/bin/sops"

    echo "⬇️ Downloading from ${sops_url}"
    if curl -L "${sops_url}" -o sops_temp; then
        chmod +x sops_temp
        if sudo mv sops_temp "${install_path}"; then
            echo "✅ sops installed successfully to ${install_path}"
        else
            echo "❌ Error: Failed to move sops to ${install_path}. Check permissions."
            rm -f sops_temp
            exit 1
        fi
    else
        echo "Error: Failed to download sops. Check URL or network connection."
        exit 1
    fi
}

echo "🔧 --- Running Tool Installation --- 🔧"
install_age
install_sops
echo "🎉 --- Tool Installation Complete --- 🎉"
