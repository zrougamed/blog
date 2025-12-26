#!/bin/bash
#
# teardown-network.sh - Remove QEMU test lab network configuration
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Tearing down QEMU test lab network...${NC}"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}This script requires root privileges. Running with sudo...${NC}"
  exec sudo "$0" "$@"
fi

# Remove TAP interfaces
for i in 0 1 2; do
  if ip link show tap$i &>/dev/null; then
    echo "Removing TAP interface tap$i..."
    ip link set tap$i down 2>/dev/null || true
    ip link delete tap$i 2>/dev/null || true
    echo -e "${GREEN}✓ tap$i removed${NC}"
  fi
done

# Remove bridge
if ip link show br-testlab &>/dev/null; then
  echo "Removing bridge br-testlab..."
  ip link set br-testlab down 2>/dev/null || true
  ip link delete br-testlab 2>/dev/null || true
  echo -e "${GREEN}✓ Bridge removed${NC}"
fi

# Optional: Remove NAT rules if they were added
# Uncomment if you enabled NAT in setup-network.sh
# INTERNET_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
# if [ -n "$INTERNET_IF" ]; then
#   echo "Removing NAT rules..."
#   iptables -t nat -D POSTROUTING -s 10.0.100.0/24 -o $INTERNET_IF -j MASQUERADE 2>/dev/null || true
#   iptables -D FORWARD -i br-testlab -o $INTERNET_IF -j ACCEPT 2>/dev/null || true
#   iptables -D FORWARD -i $INTERNET_IF -o br-testlab -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
#   echo -e "${GREEN}✓ NAT rules removed${NC}"
# fi

echo ""
echo -e "${GREEN}Test lab network removed successfully${NC}"