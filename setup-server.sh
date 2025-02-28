#!/bin/bash
#
#
# Written by Prima Agus Setiawan 
# a.k.a joeheartless 

echo "[+] Checking sudo access..."
sudo -v || { echo "[!] Sudo authentication failed! Exiting."; exit 1; }
while true; do sudo -v; sleep 300; done &

set -e 
exec > >(sudo tee -i /var/log/server-setup.log)
exec 2>&1

spinner_kontol() {
    local pid=$1
    local delay=0.1
    local spin_chars=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Applying network changes..... ${spin_chars[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for i in "${spin_chars[@]}"; do
            echo -ne "\r[+] Applying network changes..... $i "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Applying network changes... Done!\n"
}

echo "[+] Detecting network interfaces..."
interfaces=($(ls /sys/class/net | grep -v lo)) 

if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo "No network interfaces found. Exiting."
    exit 1
fi

echo "Available interfaces:"
for i in "${!interfaces[@]}"; do
    echo "[$((i+1))] ${interfaces[$i]}"
done

read -p "Enter the interface number you want to configure: " INTERFACE_NUM

if ! [[ "$INTERFACE_NUM" =~ ^[0-9]+$ ]] || (( INTERFACE_NUM < 1 || INTERFACE_NUM > ${#interfaces[@]} )); then
    echo "Invalid selection. Exiting."
    exit 1
fi

INTERFACE="${interfaces[$((INTERFACE_NUM-1))]}"
echo "You selected: $INTERFACE"

read -p "Do you want to use DHCP? (default "No"): " USE_DHCP
if [[ "$USE_DHCP" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
    echo "[+] Configuring DHCP..."
    (
        cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml >/dev/null
network:
  ethernets:
    $INTERFACE:
      dhcp4: true
  version: 2
EOF
        sudo netplan apply >/dev/null 2>&1
    ) &
    spinner_kontol $!

else
    read -p "Enter the static IP address (e.g., 192.168.1.100/24): " STATIC_IP
    if [[ ! "$STATIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        echo "[!] Invalid static IP format!" >&2
        exit 1
    fi
    
    read -p "Enter the gateway (e.g., 192.168.1.1): " GATEWAY
    if [[ ! "$GATEWAY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[!] Invalid gateway format!" >&2
        exit 1
    fi

    read -p "Enter the primary DNS (e.g., 8.8.8.8): " DNS1
    read -p "Enter the secondary DNS (e.g., 1.1.1.1): " DNS2
    cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
    
    echo "[+] Configuring static IP..."
    (
        cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml >/dev/null
network:
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses: 
        - $STATIC_IP
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
  version: 2
EOF
        sudo netplan apply >/dev/null 2>&1
    ) &
    spinner_kontol $!
fi

spinner_kontol_docker() {
    local pid=$1
    local delay=0.1  
    local frames=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Installing Docker... ${frames[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for frame in "${frames[@]}"; do
            echo -ne "\r[+] Installing Docker... $frame "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Installing Docker... Done!\n"
}

read -p "Do you want to install Docker? (default "No"): " INSTALL_DOCKER
if [[ "$INSTALL_DOCKER" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
    (
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y ca-certificates curl gnupg lsb-release >/dev/null 2>&1
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg >/dev/null
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
        sudo systemctl enable --now docker >/dev/null 2>&1
        sudo usermod -aG docker $(whoami)
    ) &
    spinner_kontol_docker $!
    echo "[+] Docker installed successfully! You may need to log out and log back in to use Docker without sudo."
fi

spinner_kontol_bind9() {
    local pid=$1
    local delay=0.1
    local spin_chars=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Installing BIND9... ${spin_chars[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for i in "${spin_chars[@]}"; do
            echo -ne "\r[+] Installing BIND9... $i "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Installing BIND9... Done!\n"
}

read -p "Do you want to install BIND9 DNS server? (default "No"): " INSTALL_BIND9
if [[ "$INSTALL_BIND9" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
    (
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y bind9 >/dev/null 2>&1
        sudo systemctl enable --now bind9 >/dev/null 2>&1
    ) &
    spinner_kontol_bind9 $!

    echo "[+] BIND9 DNS server installed successfully!"
fi

spinner_kontol_squid() {
    local pid=$1
    local delay=0.1
    local spin_chars=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Installing Squid Proxy... ${spin_chars[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for i in "${spin_chars[@]}"; do
            echo -ne "\r[+] Installing Squid Proxy... $i "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Installing Squid Proxy... Done!\n"
}

read -p "Do you want to install Squid Proxy? (default "No"): " INSTALL_SQUID
if [[ "$INSTALL_SQUID" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then

    (
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y squid >/dev/null 2>&1
        sudo systemctl enable --now squid >/dev/null 2>&1
    ) &
    spinner_kontol_squid $!

    echo "[+] Squid Proxy installed successfully!"
fi

spinner_nginx() {
    local pid=$1
    local delay=0.1
    local spin_chars=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Installing Nginx... ${spin_chars[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for i in "${spin_chars[@]}"; do
            echo -ne "\r[+] Installing Nginx... $i "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Installing Nginx... Done!\n"
}

spinner_kontol_nginx() {
    local pid=$1
    local delay=0.1
    local spin_chars=('3' '3=' '3==' '3===' '3====' '3====D')

    echo -ne "\r[+] Installing Nginx... ${spin_chars[0]} "

    while ps -p $pid >/dev/null 2>&1; do
        for i in "${spin_chars[@]}"; do
            echo -ne "\r[+] Installing Nginx... $i "
            sleep $delay
        done
    done
    echo -ne "\r\033[K[+] Installing Nginx... Done!\n"
}

read -p "Do you want to install Nginx? (default "No"): " INSTALL_NGINX
if [[ "$INSTALL_NGINX" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then

    (
        sudo apt update -y >/dev/null 2>&1
        sudo apt install -y nginx >/dev/null 2>&1
        sudo systemctl enable --now nginx >/dev/null 2>&1
    ) &
    spinner_kontol_nginx $!

    echo "[+] Nginx installed successfully!"
fi

read -p "Do you want to apply security hardening? (default "No"): " EXTRA_HARDENING
if [[ "$EXTRA_HARDENING" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
    echo "[+] Applying security hardening..."

    read -p "Harden SSH configuration? (default "No"): " HARDEN_SSH
    if [[ "$HARDEN_SSH" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
        echo "[+] Hardening SSH..."
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo systemctl restart ssh
        echo "[+] SSH Hardening Applied!"
    fi
    
    read -p "Disable IPv6? (default "No"): " DISABLE_IPV6
    if [[ "$DISABLE_IPV6" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
        echo "[+] Disabling IPv6..."
        sudo sed -i '/^net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
        sudo sed -i '/^net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
        echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        sysctl -p >/dev/null 2>&1
        echo "[+] IPv6 has been disabled!"
    fi

        read -p "Enable ASLR? (default "No"): " ENABLE_ASLR
    if [[ "$ENABLE_ASLR" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
        echo "[+] Enabling Exec Shield & ASLR..."
        sudo sed -i '/^kernel.exec-shield/d' /etc/sysctl.conf
        sudo sed -i '/^kernel.randomize_va_space/d' /etc/sysctl.conf
        echo "kernel.randomize_va_space = 2" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        sysctl -p >/dev/null 2>&1
        echo "[+] Exec Shield & ASLR enabled!"
    fi

    read -p "Strengthen mkfifo security? (default "No"): " STRENGTHEN_MKFIFO
    if [[ "$STRENGTHEN_MKFIFO" =~ ^(yes|ye|y|gas|yuhu|youman|ys|yd|si|ya|yak|yoi)$ ]]; then
        echo "[+] Strengthening mkfifo security..."
        sudo sed -i '/^fs.protected_fifos/d' /etc/sysctl.conf
        echo "fs.protected_fifos = 2" | sudo tee -a /etc/sysctl.conf >/dev/null 2>&1
        sysctl -p >/dev/null 2>&1
        echo "[+] mkfifo security has been strengthened!"
    fi
fi

echo "Setup complete! Restart your server to apply all changes."
