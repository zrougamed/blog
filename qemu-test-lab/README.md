# QEMU Test Lab for Network Security Testing

A complete, scriptable QEMU-based test lab environment for testing network security tools, infrastructure, and DevSecOps workflows.

![banner](assets/banner-qemu.png)


## Overview

This repository contains scripts and configurations to quickly spin up an isolated multi-VM test environment using QEMU. Perfect for:

- Testing network monitoring and security tools
- Validating firewall rules and network policies
- Experimenting with eBPF-based packet filtering
- Simulating attack scenarios safely
- Testing container orchestration in isolated networks
- CI/CD pipeline testing

## Architecture

The lab consists of three VMs connected via an isolated bridge network:

```
┌─────────────────────────────────────────────────┐
│                   Host System                   │
│  ┌──────────────────────────────────────────┐  │
│  │         br-testlab (10.0.100.1/24)       │  │
│  └────┬──────────────┬──────────────┬────────┘  │
│       │              │              │           │
│  ┌────▼─────┐  ┌────▼─────┐  ┌─────▼────┐     │
│  │ Gateway  │  │   App    │  │ Attacker │     │
│  │  VM      │  │   VM     │  │    VM    │     │
│  │.100.1    │  │.100.10   │  │.100.20   │     │
│  │          │  │          │  │          │     │
│  │ eth0│eth1│  │   eth0   │  │   eth0   │     │
│  └─────┴────┘  └──────────┘  └──────────┘     │
│        │                                        │
│        └─ NAT to Internet                      │
└─────────────────────────────────────────────────┘
```

- **Gateway VM**: Dual-homed router/firewall (10.0.100.1)
- **Application VM**: Simulated production server (10.0.100.10)
- **Attacker VM**: Security testing platform (10.0.100.20)

## Prerequisites

- Linux host system (Ubuntu/Debian/Fedora/Arch)
- QEMU/KVM installed
- At least 8GB RAM
- 20GB free disk space
- Basic command-line knowledge

## Quick Start

1. **Clone this repository**:
```bash
git clone https://github.com/zrougamed/blog.git
cd blog/qemu-test-lab
```

2. **Install QEMU** (if not already installed):
```bash
# Ubuntu/Debian
sudo apt install qemu-kvm qemu-utils libvirt-daemon-system bridge-utils

# Fedora/RHEL
sudo dnf install qemu-kvm qemu-img libvirt

# Arch
sudo pacman -S qemu libvirt
```

3. **Add your user to necessary groups**:
```bash
sudo usermod -aG libvirt,kvm $USER
# Log out and back in
```

4. **Download OS image** (Alpine Linux recommended for lightweight testing):
```bash
./scripts/download-alpine.sh
```

5. **Create and install the first VM**:
```bash
./scripts/create-vm.sh gateway
```

6. **Start the lab**:
```bash
./manage-lab.sh start
```

## Detailed Setup

### Initial VM Creation

Create the gateway VM and install the OS:

```bash
# Create gateway VM disk
./scripts/create-vm.sh gateway

# Boot and install (follow Alpine setup prompts)
./scripts/install-vm.sh gateway

# Create snapshot after clean install
./scripts/snapshot.sh gateway clean-install
```

Clone for additional VMs:

```bash
# Create app and attacker VMs from gateway template
./scripts/clone-vm.sh gateway app
./scripts/clone-vm.sh gateway attacker
```

### Network Configuration

The network is automatically configured when you start the lab, but you can manually manage it:

```bash
# Setup isolated network bridge
./scripts/setup-network.sh

# Teardown network
./scripts/teardown-network.sh
```

### Running Individual VMs

```bash
# Start gateway VM
./scripts/run-gateway.sh

# Start application VM
./scripts/run-app.sh

# Start attacker VM  
./scripts/run-attacker.sh
```

### Using the Management Script

The `manage-lab.sh` script provides easy control:

```bash
# Start entire lab (all VMs in tmux sessions)
./manage-lab.sh start

# Access a specific VM console
tmux attach -t gateway
tmux attach -t app
tmux attach -t attacker

# Stop all VMs
./manage-lab.sh stop

# Reset all VMs to clean snapshot
./manage-lab.sh reset

# Show lab status
./manage-lab.sh status
```

## VM Configuration

### Default Network Settings

| VM | IP Address | Role | Network Interfaces |
|----|------------|------|-------------------|
| Gateway | 10.0.100.1 | Router/Firewall | eth0 (internal), eth1 (NAT) |
| App | 10.0.100.10 | Application Server | eth0 (internal) |
| Attacker | 10.0.100.20 | Security Testing | eth0 (internal) |

### Accessing VMs

All VMs run in console mode. To access:

```bash
# If using tmux (recommended with manage-lab.sh start)
tmux attach -t gateway

# Detach from tmux: Ctrl+B, then D
```

### Inside VM Configuration

After first boot, configure each VM's network:

**Gateway VM:**
```bash
# Static IP on internal network
# eth0: 10.0.100.1/24
# eth1: DHCP (internet access)

# Enable forwarding and NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

**App/Attacker VMs:**
```bash
# Static IPs with gateway
# See scripts/configs/ for complete network configs
```

## Use Cases

### 1. Testing Network Monitoring Tools

Install and test monitoring solutions on the gateway:

```bash
# On gateway VM
apk add tcpdump
tcpdump -i eth0 -w /tmp/capture.pcap

# Generate traffic from attacker
# Analyze on gateway
```

### 2. Firewall Rule Testing

```bash
# Add restrictive rules on gateway
iptables -I FORWARD -s 10.0.100.20 -d 10.0.100.10 -j DROP

# Test from attacker
ping 10.0.100.10  # Should fail

# Verify rules work as expected
```

### 3. eBPF Development and Testing

Perfect isolated environment for developing and testing eBPF-based network tools:

```bash
# Install BCC tools or compile custom eBPF programs ( https://github.com/zrougamed/cerberus )
# Test packet filtering without affecting host
```

### 4. Container Security Testing

```bash
# Install Docker on app VM
# Test container networking and security policies
# Simulate attacks from attacker VM
```

### 5. Multi-Node Cluster Testing

```bash
# Clone additional VMs
# Test Kubernetes, Docker Swarm, or distributed databases
# Validate cluster networking and security
```

## Snapshots and Rollback

Create snapshots at key points:

```bash
# Create snapshot
./scripts/snapshot.sh gateway my-snapshot-name

# List snapshots
./scripts/snapshot.sh gateway list

# Rollback to snapshot
./scripts/snapshot.sh gateway apply my-snapshot-name

# Delete snapshot
./scripts/snapshot.sh gateway delete my-snapshot-name
```

## Advanced Configuration

### Customizing VM Resources

Edit the run scripts to adjust:
- RAM allocation (`-m` flag)
- CPU cores (`-smp` flag)
- Disk size (when creating with `qemu-img create`)

### Adding More VMs

```bash
# Clone existing VM
./scripts/clone-vm.sh gateway new-vm-name

# Create run script
cp scripts/run-gateway.sh scripts/run-new-vm.sh
# Edit MAC address and tap interface
```

### Custom Network Topologies

Modify `setup-network.sh` to create:
- Multiple isolated networks
- VLAN configurations
- Complex routing scenarios

## Performance Tips

1. **Always enable KVM**: Ensure `-enable-kvm` flag is used
2. **Use virtio drivers**: Already configured in scripts
3. **Appropriate resource allocation**: Don't over-provision RAM
4. **SSD storage**: Use SSD for VM images for better I/O
5. **CPU pinning**: For consistent performance in benchmarks

## Troubleshooting

### KVM not available
```bash
# Check if KVM modules are loaded
lsmod | grep kvm

# Enable in BIOS if missing (Intel VT-x or AMD-V)
```

### Network issues
```bash
# Verify bridge exists
ip link show br-testlab

# Check TAP interfaces
ip link show | grep tap

# Verify routing
ip route show
```

### VM won't start
```bash
# Check if image file exists
ls -lh images/

# Verify QEMU installation
qemu-system-x86_64 --version

# Check for permission issues
groups | grep kvm
```

### Performance issues
```bash
# Verify KVM is being used
ps aux | grep qemu | grep kvm

# Check available resources
free -h
df -h
```

## Repository Structure

```
qemu-test-lab/
├── README.md              # This file
├── manage-lab.sh          # Master control script
├── scripts/
│   ├── setup-network.sh   # Create bridge and TAP interfaces
│   ├── teardown-network.sh # Remove network configuration
│   ├── create-vm.sh       # Create new VM disk image
│   ├── clone-vm.sh        # Clone existing VM
│   ├── install-vm.sh      # Boot VM for OS installation
│   ├── run-gateway.sh     # Start gateway VM
│   ├── run-app.sh         # Start application VM
│   ├── run-attacker.sh    # Start attacker VM
│   ├── snapshot.sh        # Manage VM snapshots
│   ├── download-alpine.sh # Download Alpine Linux ISO
│   └── configs/           # Network configuration templates
│       ├── gateway-interfaces
│       ├── app-interfaces
│       └── attacker-interfaces
├── images/                # VM disk images (created at runtime)
└── iso/                   # OS installation media (created at runtime)
```

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Author

**Mohamed Zrouga**
- Senior Software Engineer 
- Website: [zrouga.email](https://zrouga.email)
- GitHub: [@zrougamed](https://github.com/zrougamed)
- Linkeding: [https://www.linkedin.com/in/zrouga-mohamed/](https://www.linkedin.com/in/zrouga-mohamed/)

## Related Articles

- [Building a Security Test Lab with QEMU: From Zero to Network Monitoring](https://dev.to/zrouga/building-a-security-test-lab-with-qemu-from-zero-to-network-monitoring-4onm) - Complete tutorial

## Acknowledgments

- Alpine Linux team for the lightweight distribution
- QEMU/KVM developers
- The broader DevOps and security testing community

---

**Questions or issues?** Open an issue or reach out!