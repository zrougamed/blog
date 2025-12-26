#!/bin/bash
#
# run-attacker.sh - Start the attacker/testing VM
#
# This VM has one network interface:
# - eth0: Connected to internal test network (br-testlab)
# - IP: 10.0.100.20
# - Gateway: 10.0.100.1 (gateway VM)
#

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"

VM_IMAGE="$IMAGE_DIR/attacker.qcow2"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if image exists
if [ ! -f "$VM_IMAGE" ]; then
  echo -e "${RED}Error: Attacker VM image not found at $VM_IMAGE${NC}"
  echo "Create it first with: ./scripts/clone-vm.sh gateway attacker"
  exit 1
fi

# Check if network is set up
if ! ip link show br-testlab &>/dev/null; then
  echo -e "${YELLOW}Warning: Test lab network not configured${NC}"
  echo "Setting up network..."
  "$SCRIPT_DIR/setup-network.sh"
fi

# Check if tap2 exists
if ! ip link show tap2 &>/dev/null; then
  echo -e "${RED}Error: tap2 interface not found${NC}"
  echo "Run: ./scripts/setup-network.sh"
  exit 1
fi

echo -e "${GREEN}Starting Attacker VM...${NC}"
echo "Network: eth0=tap2 (10.0.100.20)"
echo "Console: attached (Ctrl+A then X to quit)"
echo ""

qemu-system-x86_64 \
  -name attacker \
  -m 1024 \
  -smp 2 \
  -hda "$VM_IMAGE" \
  -enable-kvm \
  -netdev tap,id=net0,ifname=tap2,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:20 \
  -nographic \
  -serial mon:stdio