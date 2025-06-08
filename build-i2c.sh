#!/usr/bin/env bash

set -euo pipefail

# --- Style Definitions for clear output ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions for logging ---

# Prints an informational message.
# @param {string} message - The message to print.
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# --- Download i2c-tools from Official Source ---
I2C_TOOLS_DIR="i2c-tools-src"
I2C_TOOLS_REPO="https://git.kernel.org/pub/scm/utils/i2c-tools/i2c-tools.git"

if [ -d "$I2C_TOOLS_DIR" ]; then
    info "i2c-tools source directory already exists. Skipping download."
else
    info "Cloning i2c-tools from ${BLUE}${I2C_TOOLS_REPO}${NC}..."
    git clone "$I2C_TOOLS_REPO" "$I2C_TOOLS_DIR" || error "Failed to clone the i2c-tools repository."
fi

pushd ${I2C_TOOLS_DIR}
git checkout tags/v4.1

make DESTDIR=/opt/i2c_bin install
