# Oxylabs Forward Proxy - Infrastructure Automation

Complete Ansible automation for deploying Squid forward proxy with SSL bumping (MITM) on VirtualBox VMs.

## Features

✅ **VirtualBox VM Provisioning**
- Auto-downloads latest Debian netinst ISO
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
# VM Hardware
vm_name: squid-proxy
vm_memory: 2048  # MB
vm_cpus: 2
vm_disk_size: 20480  # MB
vm_vram: 128

# Network
vm_network_type: bridged  # or nat, hostonly
vm_network_adapter: "Intel(R) Wi-Fi 6E AX211 160MHz"  # Your adapter name

# Storage paths (WSL2 example)
download_dir: "/mnt/c/temp"           # ISO download location
vbox_vms_dir: "/mnt/d/VM"             # VMs storage directory
vm_disk_path: "{{ vbox_vms_dir }}/{{ vm_name }}/{{ vm_name }}.vdi"
iso_download_timeout: 600             # Seconds to wait for ISO download

# OS Configuration
vm_username: test-oxylabs
vm_password: changeme
vm_hostname: "{{ vm_name }}"
vm_timezone: Europe/Vilnius
vm_locale: en_US
```

**Important for WSL2 users:**
- `download_dir` and `vbox_vms_dir` must be Windows paths mounted in WSL
- Use `/mnt/c/` for C: drive, `/mnt/d/` for D: drive
- Ensure directories exist and have write permissions
- VirtualBox requires Windows-formatted paths

## Requirements

### System Requirements
- **Host OS**: Windows 11 with WSL2 or Linux
- **VirtualBox**: 6.0+
- **Ansible**: 2.9+
- **Disk Space**: ~10GB for VM + ISO
- **Network**: Bridged adapter configured

### Installation (WSL2)
```bash
# Install Ansible
sudo apt update
sudo apt install -y ansible sshpass

# VirtualBox alias (WSL2)
echo 'alias VBoxManage="/mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe"' >> ~/.bashrc
source ~/.bashrc

# Create storage directories
mkdir -p /mnt/c/temp /mnt/d/VM

# Verify
VBoxManage --version
ansible --version
```

### Installation (Native Linux)
```bash
# Install requirements
sudo apt update
sudo apt install -y ansible sshpass virtualbox

# Create storage directories
mkdir -p ~/VirtualBox\ VMs ~/Downloads

# Update paths in roles/virtualbox_debian/defaults/main.yml:
# download_dir: "~/Downloads"
# vbox_vms_dir: "~/VirtualBox VMs"
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

### VM Provisioning Flow

1. Downloads Debian netinst ISO (~400MB)
2. Creates VirtualBox VM with specified resources
3. Configures unattended installation
4. Starts VM and waits for installation (~15 min)
5. Retrieves VM IP from VirtualBox guest properties
6. Adds VM to Ansible inventory
7. Proceeds with Squid deployment

## Troubleshooting

### VM Creation Issues
```bash
# Check VirtualBox VMs
VBoxManage list vms
VBoxManage showvminfo VM_NAME

# Check storage paths exist
ls -la /mnt/c/temp
ls -la /mnt/d/VM

# Verify VBoxManage works from WSL
VBoxManage --version

# Check network adapters
VBoxManage list bridgedifs
```

### Squid not listening on port 8888
```bash
ssh user@proxy-vm
sudo journalctl -u squid -n 50
sudo netstat -tlnp | grep squid

# Check if debian.conf is interfering
sudo cat /etc/squid/squid.conf | grep include
```

### SSL certificate errors
```bash
# Reinstall CA certificate
sudo cp files/squid-ca.crt /usr/local/share/ca-certificates/squid-proxy.crt
sudo update-ca-certificates

# Verify installation
ls -la /usr/local/share/ca-certificates/
```

### ISO download timeout

If ISO download is slow, increase timeout:
```yaml
# In roles/virtualbox_debian/defaults/main.yml
iso_download_timeout: 1200  # 20 minutes
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **SSL Bumping is MITM** - Only use in controlled environments
2. **Store CA key securely** - `/etc/squid/ssl/ca.key` on proxy server
3. **Change default passwords** - Never use defaults in production
4. **Restrict network access** - Configure `squid_allowed_networks`
5. **Monitor logs** - Check `/var/log/squid/access.log` regularly
6. **Private repository** - Keep credentials out of public repos

## Performance Tuning

For high-traffic scenarios, adjust in `roles/squid_proxy/defaults/main.yml`:
```yaml
# SSL bump workers
squid_ssl_bump_children: 10  # Increase for more concurrent SSL connections

# Cache size
squid_ssl_bump_cache_size: 8MB  # Increase for better performance
```

## License

MIT

## Author

Created for Oxylabs infrastructure automation homework.
