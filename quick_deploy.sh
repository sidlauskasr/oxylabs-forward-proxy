#!/bin/bash
set -e

VM_NAME="${1:-squid-proxy-$(date +%Y%m%d-%H%M%S)}"
VM_MEMORY="${2:-2048}"
VM_CPUS="${3:-2}"

echo "════════════════════════════════════════"
echo "🚀 Squid Proxy Deployment Starting"
echo "════════════════════════════════════════"
echo "  VM Name: $VM_NAME"
echo "  Memory: $VM_MEMORY MB"
echo "  CPUs: $VM_CPUS"
echo "════════════════════════════════════════"
echo ""

cd ~/infrastructure-automation

ansible-playbook deploy_squid_proxy.yml \
  -e "vm_name=$VM_NAME" \
  -e "vm_memory=$VM_MEMORY" \
  -e "vm_cpus=$VM_CPUS"
