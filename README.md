# Server Setup V.1.0.0
## Overview
This script automates the configuration of a Linux server (Ubuntu Server 24.04.2 LTS), including network settings, package installations, and security hardening. It logs all operations and provides interactive options for customization.

## Features
- **Network Configuration:** Supports both DHCP and static IP settings.
- **Software Installation:** Includes options to install:
  - Docker
  - BIND9 DNS Server
  - Squid Proxy
  - Nginx Web Server
- **Security Hardening:** Offers enhancements such as:
  - SSH hardening (disable root login & password auth)
  - IPv6 disabling
  - ASLR (Address Space Layout Randomization) enabling
  - FIFO security improvements
- **Logging:** Captures all operations in `/var/log/server-setup.log`.

## Installation & Usage
### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/server-setup.git
cd server-setup
```

### 2. Make the Script Executable
```bash
chmod +x server-setup.sh
```

### 3. Run the Script
```bash
./server-setup.sh
```
## Disclaimer
This script has been tested and runs optimally on **Ubuntu Server 24.04.2 LTS**. Compatibility with other versions may vary.


