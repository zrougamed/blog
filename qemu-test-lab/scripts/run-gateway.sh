#!/bin/bash
#
# run-gateway.sh - Start the gateway VM
#
# This VM has two network interfaces:
# - eth0: Connected to internal test network (br-testlab)
# - eth1: NAT to internet for updates
#

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"

VM_IMAGE="$IMAGE_DIR/gateway.qcow2"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if image exists
if [ ! -f "$VM_IMAGE" ]; then
  echo -e "${RED}Error: Gateway VM image not found at $VM_IMAGE${NC}"
  echo "Create it first with: ./scripts/create-vm.sh gateway"
  exit 1
fi

# Check if network is set up
if ! ip link show br-testlab &>/dev/null; then
  echo -e "${YELLOW}Warning: Test lab network not configured${NC}"
  echo "Setting up network..."
  "$SCRIPT_DIR/setup-network.sh"
fi

# Check if tap0 exists
if ! ip link show tap0 &>/dev/null; then
  echo -e "${RED}Error: tap0 interface not found${NC}"
  echo "Run: ./scripts/setup-network.sh"
  exit 1
fi

echo -e "${GREEN}Starting Gateway VM...${NC}"
echo "Network: eth0=tap0 (10.0.100.1), eth1=NAT"
echo "Console: attached (Ctrl+A then X to quit)"
echo ""

qemu-system-x86_64 \
  -name gateway \
  -m 1024 \
  -smp 2 \
  -hda "$VM_IMAGE" \
  -enable-kvm \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:00 \
  -netdev user,id=net1 \
  -device virtio-net-pci,netdev=net1,mac=52:54:00:12:34:01 \
  -nographic \
  -serial mon:stdio