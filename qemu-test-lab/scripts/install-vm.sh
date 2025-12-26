#!/bin/bash
#
# install-vm.sh - Boot VM with ISO for OS installation
#
# Usage: ./install-vm.sh <vm-name> [iso-name]
#

set -e

VM_NAME=$1
ISO_NAME=${2:-alpine-virt-3.19.1-x86_64.iso}

if [ -z "$VM_NAME" ]; then
  echo "Usage: $0 <vm-name> [iso-name]"
  echo "Example: $0 gateway"
  echo "         $0 gateway debian-12.4.0-amd64-netinst.iso"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"
ISO_DIR="$PROJECT_DIR/iso"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VM_IMAGE="$IMAGE_DIR/${VM_NAME}.qcow2"
ISO_PATH="$ISO_DIR/$ISO_NAME"

# Check if VM image exists
if [ ! -f "$VM_IMAGE" ]; then
  echo -e "${RED}Error: VM image $VM_IMAGE does not exist${NC}"
  echo "Create it first with: ./scripts/create-vm.sh $VM_NAME"
  exit 1
fi

# Check if ISO exists
if [ ! -f "$ISO_PATH" ]; then
  echo -e "${RED}Error: ISO $ISO_PATH does not exist${NC}"
  echo "Download it first with: ./scripts/download-alpine.sh"
  echo "Or specify a different ISO file"
  exit 1
fi

echo -e "${GREEN}Booting $VM_NAME for OS installation...${NC}"
echo "ISO: $ISO_NAME"
echo ""
echo -e "${YELLOW}Installation Tips:${NC}"
echo "  - For Alpine: Login as 'root' (no password), run 'setup-alpine'"
echo "  - Choose 'sys' installation mode for full install"
echo "  - After install completes, type 'poweroff'"
echo "  - Press Ctrl+A then X to force quit if needed"
echo ""
read -p "Press Enter to continue..."

# Boot with ISO
qemu-system-x86_64 \
  -name "$VM_NAME-install" \
  -m 1024 \
  -smp 2 \
  -hda "$VM_IMAGE" \
  -cdrom "$ISO_PATH" \
  -boot d \
  -enable-kvm \
  -nic user,model=virtio \
  -nographic

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Create a clean snapshot: ./scripts/snapshot.sh $VM_NAME clean-install"
echo "  2. Boot the VM: ./scripts/run-${VM_NAME}.sh (if script exists)"
echo "  3. Configure network settings inside the VM"