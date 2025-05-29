# WireGuard-UI Auto Installation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Script-green.svg)](https://en.wikipedia.org/wiki/Shell_script)
[![WireGuard](https://img.shields.io/badge/WireGuard-VPN-blue.svg)](https://www.wireguard.com/)

A comprehensive bash script that automatically installs and configures WireGuard-UI on various Linux distributions with just one command.

## 🚀 Features

- **Multi-Distribution Support**: Works on Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux, openSUSE, and Alpine Linux
- **Two Installation Methods**: 
  - Docker installation (recommended)
  - Build from source
- **Automatic Service Management**: Sets up systemd/OpenRC services with auto-restart functionality
- **Firewall Configuration**: Automatically configures UFW or Firewalld
- **IP Forwarding**: Enables kernel IP forwarding for VPN routing
- **Web Interface**: Easy-to-use web UI for managing WireGuard configurations
- **Auto-Restart**: Automatically restarts WireGuard when configuration changes
- **Comprehensive Logging**: All installation steps logged to `/WireGuardInstall.log`

## 📋 Requirements

- Linux server with root access
- Internet connection
- Supported Linux distributions:
  - Ubuntu/Debian (apt)
  - CentOS/RHEL/Fedora (yum/dnf)
  - Arch Linux (pacman)
  - openSUSE (zypper)
  - Alpine Linux (apk)

## 🛡️ Recommended VPS Provider

For reliable VPS hosting, we recommend **[myhbd.net](https://myhbd.net)** - offering servers in multiple locations worldwide with one-click deployment options. Perfect for setting up your WireGuard VPN server!

### Why myhbd.net?
- ✅ Multiple server locations globally
- ✅ One-click server deployment
- ✅ Competitive pricing
- ✅ High-performance SSD storage
- ✅ 24/7 technical support

## ⚡ Quick Installation

Run this single command as root to install WireGuard-UI:

```bash
curl -fsSL https://raw.githubusercontent.com/itsredbull/wireguard-ui-installer/main/install.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/itsredbull/wireguard-ui-installer/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 🔧 Installation Process

The script will:

1. **Detect your OS** and package manager
2. **Install dependencies** (WireGuard, curl, wget, git, etc.)
3. **Enable IP forwarding** for VPN routing
4. **Prompt for installation method**:
   - Option 1: Docker installation (recommended)
   - Option 2: Build from source
5. **Configure services** for auto-start and auto-restart
6. **Set up firewall rules** (ports 51820/udp and 5000/tcp)
7. **Create initial WireGuard configuration**
8. **Start all services**

## 🌐 Accessing the Web Interface

After successful installation:

**Access URL**: `http://YOUR-SERVER-IP:5000`

**Default Credentials**:
- Username: `admin`
- Password: `admin`

⚠️ **IMPORTANT**: Change the default password immediately after first login!

## 📁 File Locations

- **Configuration**: `/etc/wireguard/wg0.conf`
- **Web UI Files**: `/opt/wireguard-ui/` (source install) or Docker container
- **Docker Compose**: `/etc/wireguard-ui/docker-compose.yml` (Docker install)
- **Installation Log**: `/WireGuardInstall.log`
- **Service Files**: `/etc/systemd/system/wireguard-ui.service`

## 🔄 Service Management

### Docker Installation
```bash
# Start
docker compose -f /etc/wireguard-ui/docker-compose.yml up -d

# Stop
docker compose -f /etc/wireguard-ui/docker-compose.yml down

# View logs
docker logs wireguard-ui
```

### Source Installation (systemd)
```bash
# Start/Stop/Status
sudo systemctl start wireguard-ui
sudo systemctl stop wireguard-ui
sudo systemctl status wireguard-ui

# Enable/Disable auto-start
sudo systemctl enable wireguard-ui
sudo systemctl disable wireguard-ui
```

### Source Installation (OpenRC - Alpine Linux)
```bash
# Start/Stop/Status
sudo rc-service wireguard-ui start
sudo rc-service wireguard-ui stop
sudo rc-service wireguard-ui status
```

## 🔥 Firewall Ports

The script automatically opens these ports:
- **51820/udp**: WireGuard VPN traffic
- **5000/tcp**: Web UI access

## 🛠️ Manual Configuration

### Environment Variables (Source Install)
Edit `/etc/systemd/system/wireguard-ui.service`:
```ini
Environment=WGUI_SERVER_INTERFACE_ADDRESSES=10.252.1.0/24
Environment=WGUI_SERVER_LISTEN_PORT=51820
Environment=WGUI_CONFIG_FILE_PATH=/etc/wireguard/wg0.conf
```

### Docker Environment Variables
Edit `/etc/wireguard-ui/docker-compose.yml`:
```yaml
environment:
  - BIND_ADDRESS=0.0.0.0:5000
  - WGUI_USERNAME=admin
  - WGUI_PASSWORD=admin
  - WGUI_CONFIG_FILE_PATH=/etc/wireguard/wg0.conf
```

## 📊 Monitoring and Logs

- **Installation Log**: `tail -f /WireGuardInstall.log`
- **Service Logs** (systemd): `journalctl -u wireguard-ui -f`
- **Docker Logs**: `docker logs -f wireguard-ui`
- **WireGuard Status**: `sudo wg show`

## 🔧 Troubleshooting

### Common Issues

1. **Port 5000 already in use**
   ```bash
   sudo netstat -tlnp | grep :5000
   sudo kill -9 <PID>
   ```

2. **WireGuard interface not starting**
   ```bash
   sudo wg-quick up wg0
   sudo systemctl status wg-quick@wg0
   ```

3. **Web UI not accessible**
   - Check if service is running: `sudo systemctl status wireguard-ui`
   - Verify firewall: `sudo ufw status` or `sudo firewall-cmd --list-ports`
   - Check logs: `journalctl -u wireguard-ui`

4. **Permission issues**
   ```bash
   sudo chown -R root:root /etc/wireguard/
   sudo chmod 600 /etc/wireguard/wg0.conf
   ```

## 🔄 Uninstallation

### Docker Installation
```bash
docker compose -f /etc/wireguard-ui/docker-compose.yml down
docker rmi ngoduykhanh/wireguard-ui:latest
sudo rm -rf /etc/wireguard-ui
```

### Source Installation
```bash
sudo systemctl stop wireguard-ui
sudo systemctl disable wireguard-ui
sudo rm /etc/systemd/system/wireguard-ui.service
sudo rm -rf /opt/wireguard-ui
sudo systemctl daemon-reload
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WireGuard](https://www.wireguard.com/) - Fast, modern, secure VPN tunnel
- [WireGuard-UI](https://github.com/ngoduykhanh/wireguard-ui) - Web interface for WireGuard
- [myhbd.net](https://myhbd.net) - Recommended VPS hosting provider

## 📞 Support

If you encounter any issues:
1. Check the installation log: `/WireGuardInstall.log`
2. Review the troubleshooting section above
3. Open an issue on GitHub with detailed error information

---

**⭐ If this script helped you, please consider giving it a star!**
