#!/bin/bash
#
# download-alpine.sh - Download Alpine Linux ISO for VM installation
#

set -e

# Alpine version
ALPINE_VERSION="3.19.1"
ALPINE_ARCH="x86_64"
ALPINE_VARIANT="virt"  # Minimal virtual machine variant

ISO_NAME="alpine-${ALPINE_VARIANT}-${ALPINE_VERSION}-${ALPINE_ARCH}.iso"
DOWNLOAD_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION%.*}/releases/${ALPINE_ARCH}/${ISO_NAME}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$PROJECT_DIR/iso"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create ISO directory
mkdir -p "$ISO_DIR"

ISO_PATH="$ISO_DIR/$ISO_NAME"

# Check if already downloaded
if [ -f "$ISO_PATH" ]; then
  echo -e "${YELLOW}Alpine Linux ISO already exists at:${NC}"
  echo "$ISO_PATH"
  echo ""
  read -p "Re-download? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Using existing ISO."
    exit 0
  fi
  rm "$ISO_PATH"
fi

# Download ISO
echo -e "${GREEN}Downloading Alpine Linux ${ALPINE_VERSION}...${NC}"
echo "From: $DOWNLOAD_URL"
echo "To: $ISO_PATH"
echo ""

wget -O "$ISO_PATH" "$DOWNLOAD_URL"

echo ""
echo -e "${GREEN}✓ Download complete!${NC}"
echo ""
echo "ISO location: $ISO_PATH"
echo "Size: $(du -h "$ISO_PATH" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Create a VM: ./scripts/create-vm.sh gateway"
echo "  2. Install OS: ./scripts/install-vm.sh gateway"
echo ""
echo "Note: You can also download Debian or other distributions manually"
echo "      and place them in the iso/ directory"