# Complete Infrastructure Automation

Fully automated VirtualBox VM provisioning + HAProxy HTTP proxy deployment.

## Quick Start

```bash
# Deploy everything
ansible-playbook deploy.yml

# Wait for completion (~15 minutes)
# VM will be created, Debian installed, HAProxy configured automatically
```

## Test

```bash
# Test proxy functionality
ansible-playbook test_proxy.yml

# Manual test
curl -x http://proxy-ip:8888 -U proxyuser:SecurePass123! https://ip.oxylabs.io
```

## Configuration

Edit `group_vars/proxy_servers.yml`:
- Users and passwords
- IP whitelist
- Custom headers
- Performance tuning

## Features

- ✅ Zero manual intervention
- ✅ Automatic IP detection
- ✅ HTTP/HTTPS proxy with authentication
- ✅ IP whitelisting support
- ✅ Custom header injection
- ✅ Statistics dashboard
- ✅ Minimal Debian server (no GUI)
- ✅ Automated testing

## Requirements

- Windows 11 with WSL2
- VirtualBox installed
- Ansible in WSL
- Bridged network adapter configured

## Project Structure

```
infrastructure-automation/
├── deploy.yml              # Main deployment
├── test_proxy.yml          # Automated tests
├── inventory/
│   └── hosts.ini
├── group_vars/
│   ├── all.yml
│   └── proxy_servers.yml
└── roles/
    ├── virtualbox_debian/  # VM provisioning
    └── haproxy_proxy/      # Proxy deployment
```
