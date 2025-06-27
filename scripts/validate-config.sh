#!/bin/bash

# Artefact Mirror - Local Configuration Validation Script
# This script validates configuration files locally before committing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v yq &> /dev/null; then
        missing_deps+=(yq)
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=(jq)
    fi
    
    if ! command -v yamllint &> /dev/null; then
        missing_deps+=(yamllint)
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install them:"
        echo "  - yq: https://github.com/mikefarah/yq#install"
        echo "  - jq: https://stedolan.github.io/jq/download/"
        echo "  - yamllint: pip install yamllint"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Validate YAML syntax
validate_yaml_syntax() {
    print_status "Validating YAML syntax..."
    
    if yamllint configs/images.yaml; then
        print_success "images.yaml syntax is valid"
    else
        print_error "images.yaml has syntax errors"
        return 1
    fi
    
    if yamllint configs/charts.yaml; then
        print_success "charts.yaml syntax is valid"
    else
        print_error "charts.yaml has syntax errors"
        return 1
    fi
}

# Validate images.yaml schema
validate_images_schema() {
    print_status "Validating images.yaml schema..."
    
    # Check root structure
    if ! yq eval '.images' configs/images.yaml > /dev/null 2>&1; then
        print_error "images.yaml must have 'images' root key"
        return 1
    fi
    
    # Validate each image entry
    local image_count
    local version_count=0
    
    image_count=$(yq eval '.images | length' configs/images.yaml)
    
    for ((i=0; i<image_count; i++)); do
        local current_idx=$((i + 1))
        
        # Check required fields
        if ! yq eval ".images[$i].name" configs/images.yaml > /dev/null 2>&1; then
            print_error "Image entry #$current_idx missing 'name' field"
            return 1
        fi
        
        if ! yq eval ".images[$i].versions" configs/images.yaml > /dev/null 2>&1; then
            print_error "Image entry #$current_idx missing 'versions' field"
            return 1
        fi
        
        if ! yq eval ".images[$i].source_registry" configs/images.yaml > /dev/null 2>&1; then
            print_error "Image entry #$current_idx missing 'source_registry' field"
            return 1
        fi
        
        # Validate types
        if ! yq eval ".images[$i].versions | type" configs/images.yaml | grep -qE "(!!seq|array)"; then
            print_error "Image entry #$current_idx 'versions' field must be an array"
            return 1
        fi
        
        if yq eval ".images[$i] | has(\"platforms\")" configs/images.yaml | grep -q "true"; then
            if ! yq eval ".images[$i].platforms | type" configs/images.yaml | grep -qE "(!!seq|array)"; then
                print_error "Image entry #$current_idx 'platforms' field must be an array"
                return 1
            fi
        fi
        
        # Count versions
        local img_versions
        img_versions=$(yq eval ".images[$i].versions | length" configs/images.yaml)
        version_count=$((version_count + img_versions))
        
    done
    
    print_success "images.yaml schema is valid ($image_count images, $version_count versions)"
}

# Validate charts.yaml schema
validate_charts_schema() {
    print_status "Validating charts.yaml schema..."
    
    # Check root structure
    if ! yq eval '.charts' configs/charts.yaml > /dev/null 2>&1; then
        print_error "charts.yaml must have 'charts' root key"
        return 1
    fi
    
    # Validate each chart entry
    local chart_count
    local version_count=0
    
    chart_count=$(yq eval '.charts | length' configs/charts.yaml)
    
    for ((i=0; i<chart_count; i++)); do
        local current_idx=$((i + 1))
        
        # Check required fields
        if ! yq eval ".charts[$i].name" configs/charts.yaml > /dev/null 2>&1; then
            print_error "Chart entry #$current_idx missing 'name' field"
            return 1
        fi
        
        if ! yq eval ".charts[$i].versions" configs/charts.yaml > /dev/null 2>&1; then
            print_error "Chart entry #$current_idx missing 'versions' field"
            return 1
        fi
        
        if ! yq eval ".charts[$i].repo_name" configs/charts.yaml > /dev/null 2>&1; then
            print_error "Chart entry #$current_idx missing 'repo_name' field"
            return 1
        fi
        
        if ! yq eval ".charts[$i].repo_url" configs/charts.yaml > /dev/null 2>&1; then
            print_error "Chart entry #$current_idx missing 'repo_url' field"
            return 1
        fi
        
        # Validate types
        if ! yq eval ".charts[$i].versions | type" configs/charts.yaml | grep -qE "(!!seq|array)"; then
            print_error "Chart entry #$current_idx 'versions' field must be an array"
            return 1
        fi
        
        # Validate URL format
        local repo_url
        repo_url=$(yq eval ".charts[$i].repo_url" configs/charts.yaml)
        if ! echo "$repo_url" | grep -E '^https?://' > /dev/null; then
            print_error "Chart entry #$current_idx 'repo_url' must be a valid HTTP/HTTPS URL"
            return 1
        fi
        
        # Count versions
        local chart_versions
        chart_versions=$(yq eval ".charts[$i].versions | length" configs/charts.yaml)
        version_count=$((version_count + chart_versions))
        
    done
    
    print_success "charts.yaml schema is valid ($chart_count charts, $version_count versions)"
}

# Test matrix generation
test_matrix_generation() {
    print_status "Testing matrix generation..."
    
    # Test images matrix
    local images_matrix
    images_matrix=$(yq -o=json '[
        .images[]
        | . as $img
        | $img.versions[] as $v
        | {
            "name": $img.name,
            "source_registry": $img.source_registry,
            "version": $v,
            "platforms": ($img.platforms // ["linux/amd64", "linux/arm64"])
          }
    ]' ./configs/images.yaml | jq -c .)
    
    if ! echo "$images_matrix" | jq . > /dev/null 2>&1; then
        print_error "Generated images matrix is not valid JSON"
        return 1
    fi
    
    if [ "$images_matrix" = "[]" ]; then
        print_warning "Generated images matrix is empty"
    fi
    
    # Test charts matrix
    local charts_matrix
    charts_matrix=$(yq -o=json '[
        .charts[]
        | .versions[] as $v
        | {
            "name": .name,
            "repo_name": .repo_name,
            "repo_url": .repo_url,
            "version": $v
          }
    ]' ./configs/charts.yaml | jq -c .)
    
    if ! echo "$charts_matrix" | jq . > /dev/null 2>&1; then
        print_error "Generated charts matrix is not valid JSON"
        return 1
    fi
    
    if [ "$charts_matrix" = "[]" ]; then
        print_warning "Generated charts matrix is empty"
    fi
    
    local images_count
    local charts_count
    images_count=$(echo "$images_matrix" | jq '. | length')
    charts_count=$(echo "$charts_matrix" | jq '. | length')
    
    print_success "Matrix generation successful ($images_count image jobs, $charts_count chart jobs)"
}

# Generate summary report
generate_summary() {
    print_status "Generating validation summary..."
    
    local image_count
    local chart_count
    local image_versions
    local chart_versions
    
    image_count=$(yq eval '.images | length' configs/images.yaml)
    chart_count=$(yq eval '.charts | length' configs/charts.yaml)
    image_versions=$(yq eval '[.images[].versions[]] | length' configs/images.yaml)
    chart_versions=$(yq eval '[.charts[].versions[]] | length' configs/charts.yaml)
    
    echo ""
    echo "========================================="
    echo "      VALIDATION SUMMARY REPORT"
    echo "========================================="
    echo ""
    echo "📦 Container Images: $image_count artifacts, $image_versions versions"
    echo "📊 Helm Charts: $chart_count artifacts, $chart_versions versions"
    echo "🔄 Total Mirror Jobs: $((image_versions + chart_versions))"
    echo ""
    echo "✅ All validations passed!"
    echo "🚀 Configuration is ready for mirroring"
    echo ""
}

# Main execution
main() {
    echo "🔍 Artefact Mirror - Configuration Validator"
    echo "============================================="
    echo ""
    
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    # Run validations
    check_dependencies
    validate_yaml_syntax
    validate_images_schema
    validate_charts_schema
    test_matrix_generation
    generate_summary
    
    print_success "All validations completed successfully! ✨"
}

# Run main function
main "$@" 