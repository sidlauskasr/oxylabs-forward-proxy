# Oxylabs Forward Proxy - Infrastructure Automation

Complete Ansible automation for deploying Squid forward proxy with SSL bumping (MITM) on VirtualBox VMs.

## Features

✅ **VirtualBox VM Provisioning**
- Automated Debian installation
- Unattended setup (~15 minutes)
- Bridged network with automatic IP detection

✅ **Squid Forward Proxy with SSL Bumping**
- HTTP and HTTPS proxy support
- SSL/TLS traffic inspection (MITM)
- Custom header injection
- Basic authentication
- Network-based access control

✅ **Custom Headers**
- `X-Forwarded-User: {username}` - Authenticated user
- `X-Client-Ip: {client_ip}` - Client IP address
- `X-Oxylabs-Homework: Rytis` - Custom header for homework

## Quick Start

### Option 1: Deploy to Existing VM (2-3 minutes)
```bash
# 1. Configure inventory
cp inventory/hosts.ini.example inventory/hosts.ini
nano inventory/hosts.ini  # Add your VM IP

# 2. Deploy Squid proxy
ansible-playbook -i inventory/hosts.ini deploy_squid_existing.yml

# 3. Test
curl -x 192.168.32.188:8888 -U proxyuser:SecurePass123! http://ip.oxylabs.io/headers
```

### Option 2: Full Deployment with VM Creation (~18 minutes)
```bash
# Creates new VM, installs Debian, deploys Squid
./quick_deploy.sh

# Or manually
ansible-playbook deploy_squid_proxy.yml
```

## Testing

### HTTP Test
```bash
curl -x PROXY_IP:8888 -U proxyuser:SecurePass123! http://ip.oxylabs.io/headers
```

**Expected output:**
```
GET /headers HTTP/1.1
X-Client-Ip: YOUR_IP
X-Forwarded-User: proxyuser
X-Oxylabs-Homework: Rytis
```

### HTTPS Test (with SSL bumping)
```bash
# Ignore certificate (quick test)
curl -k -x PROXY_IP:8888 -U proxyuser:SecurePass123! https://ip.oxylabs.io/headers

# Or install CA certificate for proper validation
sudo cp files/squid-ca.crt /usr/local/share/ca-certificates/squid-proxy.crt
sudo update-ca-certificates

# Now test with CA validation
curl -x PROXY_IP:8888 -U proxyuser:SecurePass123! https://ip.oxylabs.io/headers
```

## Configuration

### Proxy Settings

Edit `roles/squid_proxy/defaults/main.yml`:
```yaml
# Port
squid_proxy_port: 8888

# Authentication
squid_proxy_user: proxyuser
squid_proxy_pass: SecurePass123!

# Allowed networks
squid_allowed_networks:
  - 192.168.0.0/16
  - 10.0.0.0/8

# Custom headers
squid_extra_headers:
  - name: X-My-Custom-Header
    value: "MyValue"
```

### VM Settings

Edit `roles/virtualbox_debian/defaults/main.yml`:
```yaml
vm_name: squid-proxy
vm_memory: 2048  # MB
vm_cpus: 2
vm_network_type: bridged
vm_network_adapter: eth0  # Your host adapter
```

## Requirements

### System Requirements
- **Host OS**: Windows 11 with WSL2 or Linux
- **VirtualBox**: 6.0+
- **Ansible**: 2.9+
- **Network**: Bridged adapter configured

### Installation (WSL2)
```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible sshpass

# VirtualBox alias (WSL2)
echo 'alias VBoxManage="/mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe"' >> ~/.bashrc
source ~/.bashrc

# Verify
VBoxManage --version
ansible --version
```

## Project Structure
```
infrastructure-automation/
├── deploy_squid_proxy.yml      # Full deployment (VM + Squid)
├── deploy_squid_existing.yml   # Deploy to existing VM
├── quick_deploy.sh             # One-command deployment
├── ansible.cfg                 # Ansible configuration
├── inventory/
│   ├── hosts.ini               # Your VMs (gitignored)
│   └── hosts.ini.example       # Template
├── group_vars/
│   └── all.yml                 # Global variables
├── files/
│   └── squid-ca.crt           # Generated CA certificate
└── roles/
    ├── squid_proxy/            # Squid forward proxy with SSL bumping
    │   ├── defaults/           # Default variables
    │   ├── tasks/              # Deployment tasks
    │   ├── templates/          # Squid config template
    │   └── handlers/           # Service handlers
    └── virtualbox_debian/      # VirtualBox VM provisioning
        ├── defaults/           # VM configuration
        ├── tasks/              # VM creation tasks
        └── meta/               # Role metadata
```

## How It Works

### SSL Bumping (MITM)

1. Client connects to proxy with HTTPS request
2. Proxy intercepts the connection
3. Proxy establishes SSL with target server
4. Proxy decrypts traffic, inspects/modifies it
5. Proxy re-encrypts and forwards to target
6. Custom headers are injected during this process

**Note**: Clients must trust the proxy's CA certificate for HTTPS to work without warnings.

### Architecture
```
Client → Squid Proxy (SSL Bumping) → Target Server
         - Decrypts HTTPS
         - Injects custom headers
         - Authenticates users
         - Logs requests
```

## Troubleshooting

### Squid not listening on port 8888
```bash
ssh user@proxy-vm
sudo journalctl -u squid -n 50
sudo netstat -tlnp | grep squid
```

### SSL certificate errors
```bash
# Reinstall CA certificate
sudo cp files/squid-ca.crt /usr/local/share/ca-certificates/squid-proxy.crt
sudo update-ca-certificates
```

### VM provisioning fails
```bash
# Check VirtualBox
VBoxManage list vms
VBoxManage showvminfo VM_NAME

# Check VM logs
VBoxManage showvminfo VM_NAME --log 0
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **SSL Bumping is MITM** - Only use in controlled environments
2. **Store CA key securely** - `/etc/squid/ssl/ca.key` on proxy server
3. **Change default passwords** - Never use defaults in production
4. **Restrict network access** - Configure `squid_allowed_networks`
5. **Monitor logs** - Check `/var/log/squid/access.log` regularly

## License

MIT

## Author

Created for infrastructure automation and proxy deployment learning.
