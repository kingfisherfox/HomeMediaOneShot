# Installation Guide

## Overview
This guide helps you install a complete home media server stack on Ubuntu Server. It includes Homepage, Sonarr, Radarr, Lidarr, Bazarr, Overseerr, Plex, LazyLibrarian, Maintainerr, Prowlarr, Transmission, FlareSolverr, and Watchtower.

## Prerequisites
1. A machine with Ubuntu Server installed.
2. Internet access.
3. A second device (phone/laptop) to open the web UIs.

## Installation Steps

### Step 1: Log in to Ubuntu Server
Use the keyboard/monitor or SSH.

### Step 2: Install Minimal Tools
Run the following commands to install git and nano:
```bash
sudo apt update && upgrade -y
sudo apt install -y git nano
```

### Step 3: Download the Project
Clone the repository:
```bash
git clone https://github.com/kingfisherfox/HomeMediaOneShot.git
cd HomeMediaOneShot
```

### Step 4: Create Configuration
Copy the example configuration file:
```bash
cp .env.example .env
nano .env
```

#### Required Changes
1. Change `TRANSMISSION_RPC_PASS=change_me` to a secure password.

#### VPN Options
- **No VPN**: Set `VPN_MODE=novpn`.
- **With VPN**: 
  - Set `VPN_MODE=vpn`.
  - Set `OPENVPN_USER` and `OPENVPN_PASSWORD`.
  - Optionally set `VPN_SERVICE_PROVIDER`, `SERVER_COUNTRIES`, etc.

#### Time Zone and IP
Leave as `auto` unless specific settings are needed:
- `TZ=auto`
- `SERVER_IP=auto`

#### Transcoding
Leave `TRANSCODE_PROFILE=auto`. The installer detects hardware:
- `plex_nvidia`: NVIDIA GPU detected.
- `plex_intel`: Intel/AMD iGPU detected.
- `plex`: No hardware acceleration detected.

### Step 5: Run the Installer
```bash
sudo bash install.sh
```

**Note**: If the script exits immediately, check that you have updated `.env` and changed `TRANSMISSION_RPC_PASS`.

### Step 6: Access Homepage
The script will print the URL, typically:
`http://<server-ip>:3000`

## Ports Reference
- Homepage: 3000
- Plex: 32400
- Sonarr: 8989
- Radarr: 7878
- Lidarr: 8686
- Bazarr: 6767
- Overseerr: 5055
- Transmission: 9091
- Prowlarr: 9696
- FlareSolverr: 8191
- LazyLibrarian: 5299
- Maintainerr: 6246

## Post-Install Configuration

### 1. Plex
- Sign in and create libraries (Movies, TV, Music, Books, Audiobooks) pointing to `/media/...`.

### 2. Transmission
- Confirm download folders:
  - Incomplete: `/downloads/incomplete`
  - Complete: `/downloads/complete`

### 3. Sonarr, Radarr, Lidarr
- Add Transmission as download client:
  - Host: `transmission`
  - Port: `9091`
  - Username: `admin` (or value from `TRANSMISSION_RPC_USER`)
  - Password: Your password from `.env`

### 4. Prowlarr
- Add indexers and sync to apps.
- For FlareSolverr, set URL to `http://flaresolverr:8191`.

### 5. Overseerr, Bazarr, Maintainerr
- Connect to respective services as guided in their UIs.

