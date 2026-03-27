#!/bin/bash
# Script to test CI/CD workflows locally before pushing to GitHub

echo "=========================================="
echo "Testing valueJudgementCE CI/CD Workflows Locally"
echo "=========================================="
echo ""

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "❌ 'act' is not installed."
    echo ""
    echo "To install act:"
    echo "  macOS:   brew install act"
    echo "  Linux:   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    echo "  Windows: choco install act-cli"
    echo ""
    echo "Or visit: https://github.com/nektos/act"
    exit 1
fi

echo "✅ 'act' is installed"
echo ""

# Function to run a specific workflow
run_workflow() {
    workflow_name=$1
    workflow_file=$2
    
    echo "=========================================="
    echo "Testing: $workflow_name"
    echo "=========================================="
    
    # Run the workflow with act
    # -P flag specifies which platform to use (ubuntu-latest by default)
    # --container-architecture linux/amd64 for M1/M2 Macs
    act -W .github/workflows/$workflow_file \
        --container-architecture linux/amd64 \
        -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
    
    if [ $? -eq 0 ]; then
        echo "✅ $workflow_name passed"
    else
        echo "❌ $workflow_name failed"
        return 1
    fi
    echo ""
}

# Run each workflow
echo "Which workflow would you like to test?"
echo "1) R-CMD-check (most important)"
echo "2) Lint"
echo "3) Style"
echo "4) Test Coverage"
echo "5) Document"
echo "6) All workflows"
echo ""
read -p "Enter choice (1-6): " choice

case $choice in
    1)
        run_workflow "R-CMD-check" "R-CMD-check.yaml"
        ;;
    2)
        run_workflow "Lint" "lint.yaml"
        ;;
    3)
        run_workflow "Style" "style.yaml"
        ;;
    4)
        run_workflow "Test Coverage" "test-coverage.yaml"
        ;;
    5)
        run_workflow "Document" "document.yaml"
        ;;
    6)
        echo "Running all workflows..."
        run_workflow "R-CMD-check" "R-CMD-check.yaml" || true
        run_workflow "Lint" "lint.yaml" || true
        run_workflow "Style" "style.yaml" || true
        run_workflow "Test Coverage" "test-coverage.yaml" || true
        run_workflow "Document" "document.yaml" || true
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Testing complete!"
echo "=========================================="
