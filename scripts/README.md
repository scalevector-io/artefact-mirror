# Development Scripts

This directory contains local development and testing scripts for the Artefact Mirror project.

## Available Scripts

### `validate-config.sh`

Local configuration validation script that mirrors the GitHub Actions validation workflow.

**Purpose**: Validate YAML configuration files before committing changes.

**Usage**:
```bash
# Run from project root
./scripts/validate-config.sh
```

**Features**:
- ✅ Dependency checking (yq, jq, yamllint)
- ✅ YAML syntax validation
- ✅ Schema validation for both images.yaml and charts.yaml
- ✅ Matrix generation testing
- ✅ Colored output with detailed reporting
- ✅ Summary report with artifact counts

**Dependencies**:
- `yq` - [Installation guide](https://github.com/mikefarah/yq#install)
- `jq` - [Installation guide](https://stedolan.github.io/jq/download/)
- `yamllint` - `pip install yamllint`

## Development Workflow

1. **Before making changes**:
   ```bash
   # Validate current configuration
   ./scripts/validate-config.sh
   ```

2. **After editing configurations**:
   ```bash
   # Edit configs/images.yaml or configs/charts.yaml
   # Then validate
   ./scripts/validate-config.sh
   ```

3. **Before committing**:
   ```bash
   # Final validation
   ./scripts/validate-config.sh
   ```

## Integration with GitHub Actions

The local scripts use the same validation logic as the GitHub Actions workflows:

- **Local validation** → `scripts/validate-config.sh`
- **CI validation** → `.github/workflows/validate-config.yaml`
- **Matrix generation** → `.github/workflows/generate-matrix.yml`
- **Tool setup** → `.github/actions/setup-tools`

This ensures consistency between local development and CI environments.

## Error Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | All validations passed |
| 1 | Validation failure or missing dependencies |

## Tips

- Run validation scripts regularly during development
- The validation workflow will run automatically on pull requests
- Matrix generation testing helps catch configuration issues early
- Colored output makes it easy to spot issues quickly 