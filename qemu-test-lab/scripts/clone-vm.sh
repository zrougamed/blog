#!/bin/bash
#
# clone-vm.sh - Clone an existing VM using backing images
#
# Usage: ./clone-vm.sh <source-vm> <new-vm-name>
#

set -e

SOURCE_VM=$1
NEW_VM=$2

if [ -z "$SOURCE_VM" ] || [ -z "$NEW_VM" ]; then
  echo "Usage: $0 <source-vm> <new-vm-name>"
  echo "Example: $0 gateway app"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SOURCE_IMAGE="$IMAGE_DIR/${SOURCE_VM}.qcow2"
NEW_IMAGE="$IMAGE_DIR/${NEW_VM}.qcow2"

# Check if source exists
if [ ! -f "$SOURCE_IMAGE" ]; then
  echo -e "${RED}Error: Source image $SOURCE_IMAGE does not exist${NC}"
  exit 1
fi

# Check if destination already exists
if [ -f "$NEW_IMAGE" ]; then
  echo -e "${YELLOW}Warning: Image $NEW_IMAGE already exists!${NC}"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
  fi
  rm "$NEW_IMAGE"
fi

# Create backing image
echo -e "${GREEN}Cloning $SOURCE_VM to $NEW_VM using backing image...${NC}"
qemu-img create -f qcow2 -b "$SOURCE_IMAGE" -F qcow2 "$NEW_IMAGE"

echo ""
echo -e "${GREEN}✓ VM cloned successfully!${NC}"
echo ""
echo "Backing image: $SOURCE_IMAGE"
echo "New image: $NEW_IMAGE"
echo ""
echo "Note: Changes in $NEW_VM won't affect $SOURCE_VM"
echo "      Both VMs share the base disk to save space"
echo ""
echo "Next steps:"
echo "  1. Boot the VM and configure network settings"
echo "  2. Change hostname to avoid conflicts"