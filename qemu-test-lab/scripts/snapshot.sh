#!/bin/bash
#
# snapshot.sh - Manage QEMU VM snapshots
#
# Usage:
#   ./snapshot.sh <vm-name> create <snapshot-name>
#   ./snapshot.sh <vm-name> list
#   ./snapshot.sh <vm-name> apply <snapshot-name>
#   ./snapshot.sh <vm-name> delete <snapshot-name>
#

set -e

VM_NAME=$1
ACTION=$2
SNAPSHOT_NAME=$3

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_DIR="$PROJECT_DIR/images"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
  echo "Usage: $0 <vm-name> <action> [snapshot-name]"
  echo ""
  echo "Actions:"
  echo "  create <name>  - Create a new snapshot"
  echo "  list          - List all snapshots"
  echo "  apply <name>  - Rollback to a snapshot"
  echo "  delete <name> - Delete a snapshot"
  echo ""
  echo "Examples:"
  echo "  $0 gateway create clean-install"
  echo "  $0 gateway list"
  echo "  $0 gateway apply clean-install"
  echo "  $0 gateway delete old-snapshot"
  exit 1
}

if [ -z "$VM_NAME" ] || [ -z "$ACTION" ]; then
  show_usage
fi

VM_IMAGE="$IMAGE_DIR/${VM_NAME}.qcow2"

# Check if VM image exists
if [ ! -f "$VM_IMAGE" ]; then
  echo -e "${RED}Error: VM image $VM_IMAGE does not exist${NC}"
  exit 1
fi

case "$ACTION" in
  create)
    if [ -z "$SNAPSHOT_NAME" ]; then
      echo -e "${RED}Error: Snapshot name required${NC}"
      show_usage
    fi
    echo -e "${GREEN}Creating snapshot '$SNAPSHOT_NAME' for $VM_NAME...${NC}"
    qemu-img snapshot -c "$SNAPSHOT_NAME" "$VM_IMAGE"
    echo -e "${GREEN}✓ Snapshot created${NC}"
    ;;
    
  list)
    echo -e "${GREEN}Snapshots for $VM_NAME:${NC}"
    echo ""
    qemu-img snapshot -l "$VM_IMAGE"
    ;;
    
  apply)
    if [ -z "$SNAPSHOT_NAME" ]; then
      echo -e "${RED}Error: Snapshot name required${NC}"
      show_usage
    fi
    echo -e "${YELLOW}Rolling back $VM_NAME to snapshot '$SNAPSHOT_NAME'...${NC}"
    echo -e "${YELLOW}Warning: Current VM state will be lost!${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting."
      exit 1
    fi
    qemu-img snapshot -a "$SNAPSHOT_NAME" "$VM_IMAGE"
    echo -e "${GREEN}✓ Rollback complete${NC}"
    ;;
    
  delete)
    if [ -z "$SNAPSHOT_NAME" ]; then
      echo -e "${RED}Error: Snapshot name required${NC}"
      show_usage
    fi
    echo -e "${YELLOW}Deleting snapshot '$SNAPSHOT_NAME'...${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborting."
      exit 1
    fi
    qemu-img snapshot -d "$SNAPSHOT_NAME" "$VM_IMAGE"
    echo -e "${GREEN}✓ Snapshot deleted${NC}"
    ;;
    
  *)
    echo -e "${RED}Error: Unknown action '$ACTION'${NC}"
    show_usage
    ;;
esac