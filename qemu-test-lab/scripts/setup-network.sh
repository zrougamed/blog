#!/bin/bash
#
# setup-network.sh - Create isolated bridge network for QEMU test lab
#
# Creates:
# - br-testlab bridge (10.0.100.1/24)
# - TAP interfaces (tap0, tap1, tap2)
# - IP forwarding enabled
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up QEMU test lab network...${NC}"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}This script requires root privileges. Running with sudo...${NC}"
  exec sudo "$0" "$@"
fi

# Create bridge interface
if ip link show br-testlab &>/dev/null; then
  echo -e "${YELLOW}Bridge br-testlab already exists, skipping creation${NC}"
else
  echo "Creating bridge br-testlab..."
  ip link add name br-testlab type bridge
  ip addr add 10.0.100.1/24 dev br-testlab
  ip link set br-testlab up
  echo -e "${GREEN}✓ Bridge created${NC}"
fi

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo -e "${GREEN}✓ IP forwarding enabled${NC}"

# Create TAP interfaces
for i in 0 1 2; do
  if ip link show tap$i &>/dev/null; then
    echo -e "${YELLOW}TAP interface tap$i already exists, skipping${NC}"
  else
    echo "Creating TAP interface tap$i..."
    ip tuntap add tap$i mode tap user $SUDO_USER
    ip link set tap$i master br-testlab
    ip link set tap$i up
    echo -e "${GREEN}✓ tap$i created and attached to bridge${NC}"
  fi
done

# Optional: Add NAT for internet access through host
# Uncomment if you want VMs to access internet through host
# INTERNET_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
# if [ -n "$INTERNET_IF" ]; then
#   echo "Setting up NAT via $INTERNET_IF..."
#   iptables -t nat -A POSTROUTING -s 10.0.100.0/24 -o $INTERNET_IF -j MASQUERADE
#   iptables -A FORWARD -i br-testlab -o $INTERNET_IF -j ACCEPT
#   iptables -A FORWARD -i $INTERNET_IF -o br-testlab -m state --state RELATED,ESTABLISHED -j ACCEPT
#   echo -e "${GREEN}✓ NAT configured${NC}"
# fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test lab network ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Bridge: br-testlab (10.0.100.1/24)"
echo "TAP interfaces: tap0, tap1, tap2"
echo ""
echo "Network topology:"
echo "  tap0 -> Gateway VM (10.0.100.1)"
echo "  tap1 -> App VM (10.0.100.10)"
echo "  tap2 -> Attacker VM (10.0.100.20)"
echo ""
echo "Use 'ip addr show br-testlab' to verify"
echo -e "${GREEN}========================================${NC}"