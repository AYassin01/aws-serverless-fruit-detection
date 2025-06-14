#!/bin/bash
set -e

# Variables
LAYER_DIR="boto3_layer"
PYTHON_VERSION="python3.9" # Match your Lambda runtime
PYTHON_DIR_IN_LAYER="python" # Standard structure for Python layers

# Clean any previous build
echo "Cleaning up old layer directory..."
rm -rf ${LAYER_DIR}
mkdir -p ${LAYER_DIR}/${PYTHON_DIR_IN_LAYER}/lib/${PYTHON_VERSION}/site-packages

# Install boto3 in the layer directory
echo "Installing boto3 into layer structure..."
pip install boto3>=1.34.0 --target ${LAYER_DIR}/${PYTHON_DIR_IN_LAYER}/lib/${PYTHON_VERSION}/site-packages

# Remove unnecessary files to reduce size
echo "Cleaning up unnecessary files (errors will be ignored to prevent file-locking issues)..."
find ${LAYER_DIR}/${PYTHON_DIR} -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find ${LAYER_DIR}/${PYTHON_DIR} -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
find ${LAYER_DIR}/${PYTHON_DIR} -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
# Add more cleanup if needed (e.g., botocore/data for very small layers, but usually not needed for boto3 itself)

echo "Boto3 layer content created successfully in ${LAYER_DIR}"
echo "Directory structure:"
ls -R ${LAYER_DIR}