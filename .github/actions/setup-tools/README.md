# Setup Tools Action

A composite action that installs and configures the essential tools required for YAML/JSON processing in the Artefact Mirror workflows.

## What it does

- Installs `yq` (YAML processor) from the latest release
- Installs `jq` (JSON processor) via apt
- Verifies installations and displays versions

## Usage

```yaml
steps:
  - name: Setup tools
    uses: ./.github/actions/setup-tools
```

## Tools Installed

| Tool | Version | Purpose |
|------|---------|---------|
| `yq` | Latest | YAML parsing and processing |
| `jq` | System package | JSON parsing and manipulation |

## Requirements

- Ubuntu runner (uses `apt-get` for package installation)
- `sudo` permissions (for installing packages)

## Used by

- `.github/workflows/generate-matrix.yml`
- `.github/workflows/validate-config.yaml`
- Local development scripts (when tools are available)

This action centralizes tool installation to ensure consistency across all workflows and reduce duplication. 