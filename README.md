# ArgoCD GitOps Repository with SOPS Encryption

This repository contains Kubernetes manifests managed by ArgoCD, utilizing SOPS with age for encrypting sensitive information.

## Tech Stack

*   **Kubernetes:** Likely k3s (based on previous context)
*   **GitOps:** ArgoCD
*   **Application Packaging:** Helm (applications defined as ArgoCD Application resources)
*   **Secret Management:** SOPS (Secrets OPerationS) with age encryption
*   **Secrets Plugin:** ArgoCD SOPS Plugin (custom configuration)

## Architecture

1.  **Git Repository (This Repo):** Serves as the single source of truth for desired Kubernetes state.
    *   Contains ArgoCD `Application` manifests (e.g., `wallabag.yaml`, `cloudflare-tunnel.yaml`).
    *   Sensitive values within these manifests (specifically Helm `values`) are encrypted using SOPS.
    *   Includes configuration for SOPS (`.sops.yaml`) and the ArgoCD SOPS plugin (`argocd-sops-plugin-*.yaml`).
2.  **ArgoCD:** Deployed in the Kubernetes cluster.
    *   Monitors this Git repository.
    *   Detects changes to the manifests.
3.  **ArgoCD Repo Server (with SOPS Plugin):**
    *   When ArgoCD syncs an application, the repo-server checks out the relevant manifests.
    *   The custom SOPS plugin detects `.sops.yaml` and encrypted data.
    *   It uses the age private key (mounted from the `sops-age-key` Kubernetes Secret) to decrypt the SOPS-encrypted fields *in memory*.
4.  **Helm:** ArgoCD uses Helm to render the final Kubernetes manifests using the (now decrypted) values.
5.  **Kubernetes Cluster:** ArgoCD applies the rendered, decrypted manifests to the cluster, creating/updating resources like Deployments, Services, etc.

## Directory Structure & Key Files

*   `wallabag.yaml`: ArgoCD Application manifest for Wallabag (SOPS encrypted).
*   `cloudflare-tunnel.yaml`: ArgoCD Application manifest for Cloudflare Tunnel (SOPS encrypted).
*   `.sops.yaml`: SOPS configuration. Defines which files/keys to encrypt and which age public key to use.
*   `argocd-sops-plugin-configmap.yaml`: ConfigMap defining the custom SOPS plugin behavior for ArgoCD.
*   `argocd-sops-plugin-patch.yaml`: Kubernetes patch file to modify the `argocd-repo-server` deployment, adding the SOPS plugin container and necessary volume mounts.
*   `sops-age-key-secret.yaml`: Kubernetes Secret definition. **Crucially, this file in the *cluster* must contain the age PRIVATE key**. See Security Considerations about committing this file.
*   `keys.txt`: **(Sensitive)** Raw age private key file. Should **NOT** be committed to Git.
*   `.gitignore`: Should be configured to prevent committing `keys.txt` and potentially `sops-age-key-secret.yaml`.
*   `*.bak`: Backup files, usually safe to ignore/delete once confirmed working.

## Deployed Applications

This repository manages the deployment of the following applications:

*   **Wallabag (`wallabag.yaml`):** A self-hosted read-it-later application. It allows you to save web articles and read them later, similar to Pocket or Instapaper. The configuration uses a Helm chart referenced in the ArgoCD Application manifest.
*   **Cloudflare Tunnel (`cloudflare-tunnel.yaml`):** Creates a secure, outbound-only connection between your Kubernetes services and Cloudflare's edge. This allows you to expose services (like Wallabag) to the internet without opening inbound firewall ports.

## Workflows

### 1. Initial Setup (One Time)

*   Ensure ArgoCD is running in the cluster.
*   Create the age keypair if you haven't already (`age-keygen`).
*   Configure `.sops.yaml` with the desired encryption rules and the **public** age key.
*   Prepare `sops-age-key-secret.yaml` with the **private** age key.
*   Apply the plugin configuration and the secret to the cluster:
    ```bash
    kubectl apply -f argocd-sops-plugin-configmap.yaml
    kubectl apply -f sops-age-key-secret.yaml # Ensure private key is correct here!
    kubectl patch deployment argocd-repo-server -n argocd --patch-file argocd-sops-plugin-patch.yaml
    ```

### 2. Adding/Modifying Secrets in an Application

*   **Edit the Manifest:** Modify the *plaintext* values within the target application manifest (e.g., edit the inline `values:` section in `wallabag.yaml`).
*   **Encrypt:** Use the SOPS CLI to encrypt the modified file *in place*. The `.sops.yaml` configuration will guide the encryption.
    ```bash
    # Example: Encrypting wallabag.yaml after changes
    sops -e -i wallabag.yaml
    ```
*   **Commit:** Add the modified, *encrypted* manifest file and `.sops.yaml` (if changed) to Git and push.
    ```bash
    git add wallabag.yaml .sops.yaml
    git commit -m "Update Wallabag configuration with encrypted secrets"
    git push
    ```
*   **Sync:** ArgoCD will detect the change and automatically sync. The SOPS plugin will handle decryption during the sync process.

### 3. Verifying/Viewing Encrypted Values

*   To view the decrypted content of a file locally (requires your private key configured for the SOPS CLI):
    ```bash
    sops -d wallabag.yaml
    ```
*   To apply manually (bypassing ArgoCD sync, for testing):
    ```bash
    sops -d wallabag.yaml | kubectl apply -f -
    ```

## Automated Setup Scripts

This repository includes scripts in the `scripts/` directory to automate the setup process:

1.  **`scripts/00-install-tools.sh`**: Installs `age` and `sops` CLIs (requires adjustments based on your OS).
2.  **`scripts/01-install-argocd.sh`**: Installs ArgoCD into your current Kubernetes context.
3.  **`scripts/02-setup-sops-plugin.sh`**: Configures the ArgoCD SOPS plugin. **Requires you to manually edit `sops-age-key-secret.yaml` with your private key BEFORE running.**
4.  **`scripts/03-deploy-apps.sh`**: Applies the ArgoCD Application manifests from this repository (`wallabag.yaml`, `cloudflare-tunnel.yaml`) to the cluster.
5.  **`scripts/main-setup.sh`**: Runs all the above scripts in sequence.

**To run the full setup:**

```bash
# Ensure you have kubectl access to your cluster
# Manually edit sops-age-key-secret.yaml with your PRIVATE age key first!
cd scripts
./main-setup.sh
```

Made with ❤️, 🤖 and 🐈🐾