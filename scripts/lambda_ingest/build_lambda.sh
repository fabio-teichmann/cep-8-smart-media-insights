#!/bin/bash
set -e

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths
BUILD_DIR="${SCRIPT_DIR}/build"
ZIP_PATH="${SCRIPT_DIR}/lambda_ingest.zip"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.txt"

# Clean previous build
rm -rf "$BUILD_DIR"
# Clean previous zip
rm -rf "$ZIP_PATH"

# Start new build
mkdir -p "$BUILD_DIR"

# Copy Python files
cp "$SCRIPT_DIR"/*.py "$BUILD_DIR/"

# Install dependencies into build dir
if [ -f "$REQUIREMENTS_FILE" ]; then
    pip install --upgrade pip && pip install -r "$REQUIREMENTS_FILE" --target "$BUILD_DIR/"
fi

# Zip everything inside build dir
cd "$BUILD_DIR"
zip -r9 "$ZIP_PATH" . > /dev/null
cd "$SCRIPT_DIR"

echo "✅ Lambda package created at: $ZIP_PATH"
