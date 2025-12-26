#!/bin/bash
#
# create-vm.sh - Create a new QEMU VM disk image
#
# Usage: ./create-vm.sh <vm-name> [size-in-GB]
#

set -e

VM_NAME=$1
SIZE=${2:-20}  # Default 20GB

if [ -z "$VM_NAME" ]; then
  echo "Usage: $0 <vm-name> [size-in-GB]"
  echo "Example: $0 gateway 20"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create images directory if it doesn't exist
mkdir -p "$IMAGE_DIR"

IMAGE_PATH="$IMAGE_DIR/${VM_NAME}.qcow2"

# Check if image already exists
if [ -f "$IMAGE_PATH" ]; then
  echo -e "${YELLOW}Warning: Image $IMAGE_PATH already exists!${NC}"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
  fi
  rm "$IMAGE_PATH"
fi

# Create the disk image
echo -e "${GREEN}Creating ${SIZE}GB disk image for $VM_NAME...${NC}"
qemu-img create -f qcow2 "$IMAGE_PATH" "${SIZE}G"

echo ""
echo -e "${GREEN}✓ VM disk created: $IMAGE_PATH${NC}"
echo ""
echo "Next steps:"
echo "  1. Download an OS ISO: ./scripts/download-alpine.sh"
echo "  2. Install OS: ./scripts/install-vm.sh $VM_NAME"
echo "  3. Create snapshot: ./scripts/snapshot.sh $VM_NAME clean-install"