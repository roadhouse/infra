# Apps of Apps Pattern

This directory contains ArgoCD Application resources following the App of Apps pattern.

## Structure

- `root-app.yaml`: The main application that manages all other applications
- Application directories (e.g., `atuin/`) containing application definition files

## Adding a New Application

To add a new application:

1. Create a new directory for your application: `mkdir -p apps/new-app`
2. Create a YAML file in the new directory with the appropriate ArgoCD Application resource
3. Commit and push the changes
4. ArgoCD will automatically detect and deploy the new application

## Applications

### Atuin

Atuin is a shell history synchronization tool. The application is configured to use the Helm chart from https://helm-charts.rm3l.org.

Location: `/apps/atuin/atuin.yaml`
