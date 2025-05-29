#!/bin/bash

# WireGuard-UI Installation Script
# This script installs WireGuard-UI on various Linux distributions
# Logs and instructions are saved to /WireGuardInstall.log

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /WireGuardInstall.log
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR: This script must be run as root"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        log "Detected OS: $OS $VERSION"
    else
        log "ERROR: Cannot detect OS"
        exit 1
    fi
}

# Function to install required packages
install_dependencies() {
    log "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        log "Using apt package manager"
        apt-get update
        apt-get install -y wireguard wireguard-tools curl wget git unzip systemd
    elif command -v yum &> /dev/null; then
        log "Using yum package manager"
        yum install -y epel-release
        yum install -y wireguard-tools curl wget git unzip systemd
    elif command -v dnf &> /dev/null; then
        log "Using dnf package manager"
        dnf install -y wireguard-tools curl wget git unzip systemd
    elif command -v pacman &> /dev/null; then
        log "Using pacman package manager"
        pacman -Sy --noconfirm wireguard-tools curl wget git unzip systemd
    elif command -v zypper &> /dev/null; then
        log "Using zypper package manager"
        zypper install -y wireguard-tools curl wget git unzip systemd
    elif command -v apk &> /dev/null; then
        log "Using apk package manager"
        apk add --no-cache wireguard-tools curl wget git unzip openrc inotify-tools
        USE_OPENRC=true
    else
        log "ERROR: Unsupported package manager"
        exit 1
    fi
    
    log "Dependencies installed successfully"
}

# Function to enable IP forwarding
enable_ip_forwarding() {
    log "Enabling IP forwarding..."
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf
    log "IP forwarding enabled"
}

# Function to download and install WireGuard-UI using git
install_wireguard_ui_from_source() {
    log "Installing WireGuard-UI from source..."
    
    # Install Go if it's not already installed
    if ! command -v go &> /dev/null; then
        log "Installing Go..."
        
        # Download and install Go
        wget -q https://go.dev/dl/go1.20.5.linux-amd64.tar.gz -O /tmp/go.tar.gz
        tar -C /usr/local -xzf /tmp/go.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        
        # Add Go to PATH permanently
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
        chmod +x /etc/profile.d/go.sh
        source /etc/profile.d/go.sh
        
        log "Go installed successfully"
    fi
    
    # Clone the repository
    log "Cloning WireGuard-UI repository..."
    git clone https://github.com/ngoduykhanh/wireguard-ui.git /tmp/wireguard-ui
    
    # Build the application
    log "Building WireGuard-UI..."
    cd /tmp/wireguard-ui
    ./prepare_assets.sh
    go build -o wireguard-ui
    
    # Create necessary directories
    mkdir -p /opt/wireguard-ui
    mkdir -p /etc/wireguard
    
    # Move the built binary and assets to the installation directory
    mv wireguard-ui /opt/wireguard-ui/
    cp -r assets/ /opt/wireguard-ui/
    
    # Clean up
    cd /
    rm -rf /tmp/wireguard-ui
    rm -f /tmp/go.tar.gz
    
    log "WireGuard-UI built and installed successfully"
}

# Alternative function to install using Docker
install_wireguard_ui_docker() {
    log "Installing Docker and WireGuard-UI container..."
    
    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        if command -v apt-get &> /dev/null; then
            apt-get update
            apt-get install -y ca-certificates curl gnupg
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif command -v pacman &> /dev/null; then
            pacman -Sy --noconfirm docker docker-compose
        elif command -v zypper &> /dev/null; then
            zypper install -y docker docker-compose
        elif command -v apk &> /dev/null; then
            apk add --no-cache docker docker-compose
        fi
        
        # Start and enable Docker service
        if [ "$USE_OPENRC" = true ]; then
            rc-update add docker default
            rc-service docker start
        else
            systemctl enable docker
            systemctl start docker
        fi
        
        log "Docker installed successfully"
    fi
    
    # Create directories
    mkdir -p /etc/wireguard-ui
    mkdir -p /etc/wireguard
    
    # Create Docker Compose file
    log "Creating Docker Compose file..."
    cat > /etc/wireguard-ui/docker-compose.yml << EOF
version: '3'
services:
  wireguard-ui:
    image: ngoduykhanh/wireguard-ui:latest
    container_name: wireguard-ui
    volumes:
      - ./db:/app/db
      - /etc/wireguard:/etc/wireguard
    ports:
      - "5000:5000"
    environment:
      - BIND_ADDRESS=0.0.0.0:5000
      - WGUI_USERNAME=admin
      - WGUI_PASSWORD=admin
      - WGUI_CONFIG_FILE_PATH=/etc/wireguard/wg0.conf
      - WGUI_MANAGE_START=true
      - WGUI_MANAGE_RESTART=true
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
EOF
    
    # Start Docker container
    log "Starting WireGuard-UI container..."
    cd /etc/wireguard-ui
    docker compose up -d
    
    log "WireGuard-UI Docker container started successfully"
}

# Function to create systemd service
create_systemd_service() {
    log "Creating systemd service for WireGuard-UI..."
    
    cat > /etc/systemd/system/wireguard-ui.service << EOF
[Unit]
Description=WireGuard UI
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/wireguard-ui
ExecStart=/opt/wireguard-ui/wireguard-ui
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=wireguard-ui
Environment=WGUI_SERVER_INTERFACE_ADDRESSES=10.252.1.0/24
Environment=WGUI_SERVER_LISTEN_PORT=51820
Environment=WGUI_CONFIG_FILE_PATH=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF

    # Create auto-restart service for WireGuard when config changes
    cat > /etc/systemd/system/wgui.service << EOF
[Unit]
Description=Restart WireGuard
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart wg-quick@wg0.service

[Install]
RequiredBy=wgui.path
EOF

    cat > /etc/systemd/system/wgui.path << EOF
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes

[Path]
PathModified=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF

    log "Enabling services..."
    systemctl daemon-reload
    systemctl enable wireguard-ui.service
    systemctl enable wgui.path
    systemctl enable wgui.service
    
    log "Services enabled. WireGuard-UI service created successfully"
}

# Function to create OpenRC service (for Alpine Linux)
create_openrc_service() {
    log "Creating OpenRC service for WireGuard-UI..."
    
    # Create WireGuard-UI service
    cat > /etc/init.d/wireguard-ui << EOF
#!/sbin/openrc-run

name="WireGuard UI"
description="WireGuard UI web interface"
command="/opt/wireguard-ui/wireguard-ui"
command_background=true
pidfile="/run/wireguard-ui.pid"
start_stop_daemon_args="--chdir /opt/wireguard-ui"
depend() {
    need net
    after firewall
}
EOF
    chmod +x /etc/init.d/wireguard-ui
    
    # Create config watcher script
    cat > /usr/local/bin/wgui << EOF
#!/bin/sh
wg-quick down wg0
wg-quick up wg0
EOF
    chmod +x /usr/local/bin/wgui
    
    # Create config watcher service
    cat > /etc/init.d/wgui << EOF
#!/sbin/openrc-run

command=/sbin/inotifyd
command_args="/usr/local/bin/wgui /etc/wireguard/wg0.conf:w"
pidfile=/run/\${RC_SVCNAME}.pid
command_background=yes
EOF
    chmod +x /etc/init.d/wgui
    
    log "Enabling services..."
    rc-update add wireguard-ui default
    rc-update add wgui default
    
    log "Services enabled. WireGuard-UI OpenRC service created successfully"
}

# Function to configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        log "Using UFW firewall"
        ufw allow 51820/udp
        ufw allow 5000/tcp
    elif command -v firewall-cmd &> /dev/null; then
        log "Using Firewalld"
        firewall-cmd --permanent --add-port=51820/udp
        firewall-cmd --permanent --add-port=5000/tcp
        firewall-cmd --reload
    else
        log "No supported firewall detected. Please manually open ports 51820/udp and 5000/tcp"
    fi
    
    log "Firewall configured"
}

# Function to start services
start_services() {
    if [ "$USING_DOCKER" = true ]; then
        log "WireGuard-UI is already running in Docker container"
        return
    fi
    
    log "Starting services..."
    
    if [ "$USE_OPENRC" = true ]; then
        rc-service wireguard-ui start
        rc-service wgui start
        log "Services started with OpenRC"
    else
        systemctl start wireguard-ui.service
        systemctl start wgui.path
        systemctl start wgui.service
        log "Services started with systemd"
    fi
    
    log "WireGuard-UI is now running!"
}

# Function to create wg0.conf if not exists
create_wg_config() {
    if [ ! -f /etc/wireguard/wg0.conf ]; then
        log "Creating initial WireGuard configuration..."
        
        # Generate private key
        PRIVATE_KEY=$(wg genkey)
        
        # Create basic config
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.252.1.1/24
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
EOF
        
        log "Basic WireGuard configuration created"
    else
        log "WireGuard configuration already exists, skipping creation"
    fi
}

# Function to check if wg0 interface is up
start_wireguard() {
    log "Setting up WireGuard interface..."
    
    if ! wg show wg0 &> /dev/null; then
        if command -v wg-quick &> /dev/null; then
            wg-quick up wg0
            if [ "$USE_OPENRC" = true ]; then
                rc-update add wg-quick default
            else
                systemctl enable wg-quick@wg0.service
            fi
            log "WireGuard interface started and enabled on boot"
        else
            log "ERROR: wg-quick not found, please start WireGuard manually"
        fi
    else
        log "WireGuard interface is already up"
    fi
}

# Function to display final instructions
show_instructions() {
    IP_ADDRESS=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    
    log "====================================================="
    log "WireGuard-UI has been installed successfully!"
    
    if [ "$USING_DOCKER" = true ]; then
        log "You can access the web interface at: http://$IP_ADDRESS:5000"
    else
        log "You can access the web interface at: http://$IP_ADDRESS:5000"
    fi
    
    log "Default credentials: admin / admin"
    log "IMPORTANT: Please change the default password immediately!"
    log "====================================================="
    
    if [ "$USING_DOCKER" = true ]; then
        log "To manage the Docker container:"
        log "  Start: docker compose -f /etc/wireguard-ui/docker-compose.yml up -d"
        log "  Stop: docker compose -f /etc/wireguard-ui/docker-compose.yml down"
        log "  Logs: docker logs wireguard-ui"
    else
        log "To manually start/stop the service:"
        if [ "$USE_OPENRC" = true ]; then
            log "  Start: rc-service wireguard-ui start"
            log "  Stop: rc-service wireguard-ui stop"
            log "  Status: rc-service wireguard-ui status"
        else
            log "  Start: systemctl start wireguard-ui"
            log "  Stop: systemctl stop wireguard-ui"
            log "  Status: systemctl status wireguard-ui"
        fi
    fi
    
    log "====================================================="
    log "The WireGuard service will automatically restart when the configuration file changes"
    log "Installation log has been saved to /WireGuardInstall.log"
}

# Main function
main() {
    # Start log file
    echo "===== WireGuard-UI Installation Log - $(date) =====" > /WireGuardInstall.log
    
    log "Starting WireGuard-UI installation..."
    check_root
    detect_os
    install_dependencies
    enable_ip_forwarding
    
    # Ask user about installation method
    log "Choose installation method:"
    log "1) Docker installation (recommended)"
    log "2) Build from source"
    read -p "Enter your choice (1/2): " install_choice
    
    case $install_choice in
        1)
            install_wireguard_ui_docker
            USING_DOCKER=true
            ;;
        2)
            install_wireguard_ui_from_source
            if [ "$USE_OPENRC" = true ]; then
                create_openrc_service
            else
                create_systemd_service
            fi
            start_services
            ;;
        *)
            log "Invalid choice. Defaulting to Docker installation."
            install_wireguard_ui_docker
            USING_DOCKER=true
            ;;
    esac
    
    create_wg_config
    configure_firewall
    start_wireguard
    show_instructions
    
    log "Installation completed!"
}

# Execute main function
USE_OPENRC=false
USING_DOCKER=false
main
