# Artefact Mirror: A Declarative Mirroring Tool for Container Images & Helm Charts

[![Mirror Container Images](https://github.com/scalevector-io/artefact-mirror/actions/workflows/mirror-images.yaml/badge.svg)](https://github.com/scalevector-io/artefact-mirror/actions/workflows/mirror-images.yaml)
[![Mirror Helm Charts](https://github.com/scalevector-io/artefact-mirror/actions/workflows/mirror-charts.yaml/badge.svg)](https://github.com/scalevector-io/artefact-mirror/actions/workflows/mirror-charts.yaml)

A simple, fast, and declarative utility for mirroring public container images and Helm charts to GitHub Container Registry using a GitHub Actions matrix strategy.

## Overview

This repository automatically mirrors container images and Helm charts to GitHub Container Registry (`ghcr.io`) using a declarative, parallel, and secure approach with GitHub Actions.

## Features

- 🚀 **Parallel Mirroring**: Uses a **matrix strategy** for high-speed, parallel execution.
- 🛡️ **Security Scanning**: Automatically scans all mirrored container images for vulnerabilities with **Trivy** (non-blocking).
- 🔄 **Automated Mirroring**: Weekly scheduled runs via GitHub Actions.
- 📦 **Container Images**: Mirrors to GitHub Container Registry, with multi-platform support.
- ⚙️ **Helm Charts**: Mirrors to GitHub Container Registry as OCI artifacts.
- 📝 **Declarative Configuration**: All artifacts are defined in simple YAML files.
- ⚡ **Error Isolation**: `fail-fast: false` ensures that the failure of a single artifact does not stop the entire workflow.

## How It Works

The workflows are designed for maximum efficiency and clarity:

1.  **Prepare Matrix**: A preliminary job reads the YAML configuration files (`configs/images.yaml` and `configs/charts.yaml`).
2.  **Dynamic Matrix Generation**: It uses `yq` to generate a JSON matrix of every possible combination of artifact and version.
3.  **Parallel Execution**: The main `mirror` job uses this JSON to spawn a separate, parallel job for each artifact in the matrix.
4.  **Multi-Platform Support**: For container images, each job creates a single multi-platform manifest supporting all requested architectures.
5.  **Security Scanning**: Each mirrored container image is scanned by Trivy with non-blocking vulnerability reporting.

This architecture provides significant benefits over a sequential loop:
- **Speed**: All artifacts are mirrored concurrently.
- **Resilience**: A single failure won't halt other jobs.
- **Clarity**: The Actions UI provides a clear, individual status for every artifact.
- **Security**: Comprehensive vulnerability scanning with multiple reporting formats.

## Quick Start

### 1. Run Workflows

The workflows can be triggered in several ways:

- **Automatically**: Weekly on Monday at 3:00 AM (images) and 4:00 AM (charts) UTC.
- **Manually**: Go to the **Actions** tab, select the desired workflow (**Mirror Container Images** or **Mirror Helm Charts**), and click **Run workflow**.

### 2. Access Mirrored Artifacts

#### Container Images
After the workflow runs, images will be available at:
```
ghcr.io/scalevector-io/IMAGE_NAME:TAG
```

Example:
```bash
docker pull ghcr.io/scalevector-io/hashicorp/vault:1.19.0
docker pull ghcr.io/scalevector-io/hashicorp/vault-k8s:1.7.0
```

#### Helm Charts
Charts are stored as OCI artifacts in GitHub Container Registry:
```bash
# Install directly from OCI registry
helm install my-vault oci://ghcr.io/scalevector-io/hashicorp/vault --version 0.30.0

# Or add as repository
helm repo add scalevector-vault oci://ghcr.io/scalevector-io/hashicorp
helm repo update
helm install my-vault scalevector-vault/vault --version 0.30.0
```

## Current Mirrored Artifacts

### Container Images
- **HashiCorp Vault**: `1.19.0`, `1.19.5` (linux/amd64, linux/arm64)
- **Vault Kubernetes**: `1.6.2`, `1.7.0` (linux/amd64, linux/arm64)
- **Vault CSI Provider**: `1.5.0` (linux/amd64, linux/arm64)

### Helm Charts
- **HashiCorp Vault**: `0.29.0`, `0.29.1`, `0.30.0`

## Configuration

Configuration is managed in the `configs` directory.

### Adding Container Images

Edit `configs/images.yaml`:
```yaml
images:
  - name: 'hashicorp/vault'
    versions: ['1.19.0', '1.19.5']
    source_registry: 'docker.io'
    platforms: ['linux/amd64', 'linux/arm64']
  # Add your new image here:
  - name: 'hashicorp/consul'
    versions: ['1.17.0']
    source_registry: 'docker.io'
```

### Adding Helm Charts

Edit `configs/charts.yaml`:
```yaml
charts:
  - name: 'vault'
    versions: ['0.29.0', '0.30.0']
    repo_name: 'hashicorp'
    repo_url: 'https://helm.releases.hashicorp.com'
  # Add your new chart here:
  - name: 'consul'
    versions: ['1.3.0']
    repo_name: 'hashicorp'
    repo_url: 'https://helm.releases.hashicorp.com'
```

## Monitoring

- **Actions Tab**: View workflow runs and the status of each individual matrix job.
- **Packages Tab**: View mirrored artifacts in your GitHub organization.
- **Workflow Artifacts**: Download detailed vulnerability reports from completed workflow runs.
- **Logs**: Detailed vulnerability scan results and mirroring logs are available for each job.

### Security Scanning

Each mirrored container image is automatically scanned for vulnerabilities:

- **Non-blocking**: Vulnerabilities don't prevent mirroring
- **Smart Annotations**: Warnings only appear when Critical or High vulnerabilities are found
- **Multiple Reports**: Console logs (table format), workflow summaries, and downloadable artifacts
- **Severity tracking**: Critical, High, and Medium vulnerabilities
- **Multiple formats**: Text summaries for reading, JSON reports for automation
- **Artifact Storage**: Both human-readable and machine-readable formats available as workflow artifacts (30-day retention)

## Contributing

1. Fork the repository.
2. Edit the appropriate YAML file in the `configs` directory.
3. Add your artifacts.
4. Submit a pull request.

## Security

- Uses GitHub's built-in `GITHUB_TOKEN` for authentication.
- All container images are scanned for vulnerabilities using Trivy.
- No external secrets required.
- Artifacts are publicly accessible after mirroring.

## License

This project is licensed under the MIT License - see the LICENSE file for details.