#!/bin/bash
#
# manage-lab.sh - Master control script for QEMU test lab
#
# Usage:
#   ./manage-lab.sh start   - Start all VMs in tmux sessions
#   ./manage-lab.sh stop    - Stop all VMs and cleanup
#   ./manage-lab.sh reset   - Reset all VMs to clean-install snapshot
#   ./manage-lab.sh status  - Show status of VMs and network
#

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS="$SCRIPT_DIR/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_usage() {
  echo "Usage: $0 {start|stop|reset|status}"
  echo ""
  echo "Commands:"
  echo "  start   - Start all VMs in tmux sessions"
  echo "  stop    - Stop all VMs and cleanup network"
  echo "  reset   - Reset all VMs to clean-install snapshot"
  echo "  status  - Show current lab status"
  echo ""
  echo "VM Access:"
  echo "  tmux attach -t gateway"
  echo "  tmux attach -t app"
  echo "  tmux attach -t attacker"
  echo "  (Ctrl+B then D to detach from tmux)"
  exit 1
}

check_dependencies() {
  local missing=0
  
  if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo -e "${RED}Error: QEMU not installed${NC}"
    missing=1
  fi
  
  if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}Warning: tmux not installed (recommended for managing multiple VMs)${NC}"
    echo "Install with: sudo apt install tmux"
  fi
  
  if [ $missing -eq 1 ]; then
    exit 1
  fi
}

start_lab() {
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Starting QEMU Test Lab${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  
  # Setup network
  if ! ip link show br-testlab &>/dev/null; then
    echo "Setting up network..."
    "$SCRIPTS/setup-network.sh"
    echo ""
  else
    echo -e "${YELLOW}Network already configured${NC}"
    echo ""
  fi
  
  # Check if VMs exist
  if [ ! -f "$SCRIPT_DIR/images/gateway.qcow2" ]; then
    echo -e "${RED}Error: Gateway VM not found${NC}"
    echo "Please create VMs first. See README.md for setup instructions."
    exit 1
  fi
  
  # Start VMs in tmux sessions
  echo "Starting VMs in tmux sessions..."
  echo ""
  
  # Gateway
  if tmux has-session -t gateway 2>/dev/null; then
    echo -e "${YELLOW}Gateway VM session already exists${NC}"
  else
    echo "Starting Gateway VM..."
    tmux new-session -d -s gateway "$SCRIPTS/run-gateway.sh"
    sleep 2
  fi
  
  # App (if exists)
  if [ -f "$SCRIPT_DIR/images/app.qcow2" ]; then
    if tmux has-session -t app 2>/dev/null; then
      echo -e "${YELLOW}App VM session already exists${NC}"
    else
      echo "Starting App VM..."
      tmux new-session -d -s app "$SCRIPTS/run-app.sh"
      sleep 2
    fi
  else
    echo -e "${YELLOW}App VM not found, skipping${NC}"
  fi
  
  # Attacker (if exists)
  if [ -f "$SCRIPT_DIR/images/attacker.qcow2" ]; then
    if tmux has-session -t attacker 2>/dev/null; then
      echo -e "${YELLOW}Attacker VM session already exists${NC}"
    else
      echo "Starting Attacker VM..."
      tmux new-session -d -s attacker "$SCRIPTS/run-attacker.sh"
      sleep 2
    fi
  else
    echo -e "${YELLOW}Attacker VM not found, skipping${NC}"
  fi
  
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Lab started successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Access VMs with:"
  echo "  tmux attach -t gateway"
  echo "  tmux attach -t app"
  echo "  tmux attach -t attacker"
  echo ""
  echo "Detach from tmux: Ctrl+B then D"
  echo "Stop lab: ./manage-lab.sh stop"
  echo ""
}

stop_lab() {
  echo -e "${YELLOW}Stopping QEMU Test Lab...${NC}"
  echo ""
  
  # Kill tmux sessions
  for session in gateway app attacker; do
    if tmux has-session -t $session 2>/dev/null; then
      echo "Stopping $session VM..."
      tmux kill-session -t $session 2>/dev/null || true
    fi
  done
  
  # Wait a moment for clean shutdown
  sleep 2
  
  # Teardown network
  if ip link show br-testlab &>/dev/null; then
    echo "Removing network configuration..."
    "$SCRIPTS/teardown-network.sh"
  fi
  
  echo ""
  echo -e "${GREEN}Lab stopped successfully${NC}"
}

reset_lab() {
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}Resetting Lab to Clean Snapshots${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""
  echo -e "${RED}Warning: This will reset all VMs to their clean-install state${NC}"
  echo -e "${RED}All current VM data will be lost!${NC}"
  echo ""
  read -p "Continue? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
  fi
  
  # Stop VMs first
  stop_lab
  echo ""
  
  # Reset each VM
  for vm in gateway app attacker; do
    if [ -f "$SCRIPT_DIR/images/${vm}.qcow2" ]; then
      echo "Resetting $vm VM..."
      if qemu-img snapshot -l "$SCRIPT_DIR/images/${vm}.qcow2" 2>/dev/null | grep -q clean-install; then
        qemu-img snapshot -a clean-install "$SCRIPT_DIR/images/${vm}.qcow2"
        echo -e "${GREEN}✓ $vm reset to clean-install${NC}"
      else
        echo -e "${YELLOW}Warning: No clean-install snapshot found for $vm${NC}"
      fi
    fi
  done
  
  echo ""
  echo -e "${GREEN}Reset complete!${NC}"
  echo "Start the lab again with: ./manage-lab.sh start"
}

show_status() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}QEMU Test Lab Status${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  
  # Network status
  echo -e "${BLUE}Network Status:${NC}"
  if ip link show br-testlab &>/dev/null; then
    echo -e "  Bridge: ${GREEN}UP${NC} (br-testlab)"
    ip addr show br-testlab | grep "inet " | awk '{print "  IP: " $2}'
    
    for i in 0 1 2; do
      if ip link show tap$i &>/dev/null; then
        echo -e "  tap$i: ${GREEN}UP${NC}"
      else
        echo -e "  tap$i: ${RED}DOWN${NC}"
      fi
    done
  else
    echo -e "  Bridge: ${RED}DOWN${NC}"
  fi
  
  echo ""
  echo -e "${BLUE}VM Status:${NC}"
  
  # Check tmux sessions
  for vm in gateway app attacker; do
    if [ -f "$SCRIPT_DIR/images/${vm}.qcow2" ]; then
      if tmux has-session -t $vm 2>/dev/null; then
        echo -e "  $vm: ${GREEN}RUNNING${NC} (tmux session active)"
      else
        echo -e "  $vm: ${YELLOW}STOPPED${NC}"
      fi
      
      # Show disk size
      local size=$(du -h "$SCRIPT_DIR/images/${vm}.qcow2" | cut -f1)
      echo "         Disk: $size"
      
      # Show snapshots
      local snapshots=$(qemu-img snapshot -l "$SCRIPT_DIR/images/${vm}.qcow2" 2>/dev/null | tail -n +3 | wc -l)
      if [ $snapshots -gt 0 ]; then
        echo "         Snapshots: $snapshots"
      fi
    else
      echo -e "  $vm: ${RED}NOT CREATED${NC}"
    fi
  done
  
  echo ""
  echo -e "${BLUE}Quick Actions:${NC}"
  echo "  Start lab:  ./manage-lab.sh start"
  echo "  Stop lab:   ./manage-lab.sh stop"
  echo "  Reset VMs:  ./manage-lab.sh reset"
  echo ""
}

# Main script logic
if [ $# -eq 0 ]; then
  show_usage
fi

check_dependencies

case "$1" in
  start)
    start_lab
    ;;
  stop)
    stop_lab
    ;;
  reset)
    reset_lab
    ;;
  status)
    show_status
    ;;
  *)
    echo -e "${RED}Error: Unknown command '$1'${NC}"
    echo ""
    show_usage
    ;;
esac