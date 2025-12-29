What this does
You install Ubuntu Server.
You download this repo.
You edit one file (.env).
You run one command.
You end up with:
Homepage, Sonarr, Radarr, Lidarr, Bazarr, Overseerr, Plex, LazyLibrarian, Maintainerr, Prowlarr, Transmission, FlareSolverr, Watchtower.
VPN is optional.
Transcoding capability is detected automatically and the correct Plex profile is selected.

Before you start
You need:
1) A machine with Ubuntu Server installed
2) Internet access
3) A second device (phone/laptop) to open the web UIs

Step 1: Log in to Ubuntu Server
Use the keyboard/monitor or SSH if you set it up during install.

Step 2: Install the minimal tools to download the repo
sudo apt update
sudo apt install -y git nano

Step 3: Download the project
git clone <YOUR_GITHUB_REPO_URL>
cd <REPO_FOLDER>

Step 4: Create your config
cp .env.example .env
nano .env

Required changes
1) Change:
TRANSMISSION_RPC_PASS=change_me
to something else.

VPN options
If you do NOT want a VPN:
VPN_MODE=novpn

If you want a VPN:
VPN_MODE=vpn
Set:
OPENVPN_USER=
OPENVPN_PASSWORD=
You can also set:
VPN_SERVICE_PROVIDER=
SERVER_COUNTRIES=
SERVER_CITIES=
SERVER_HOSTNAMES=
If you do not know these, leave them blank except the credentials.

Time zone and IP address
Leave these as auto unless you have a reason:
TZ=auto
SERVER_IP=auto

Transcoding
Leave:
TRANSCODE_PROFILE=auto
The installer picks one of:
plex
plex_intel
plex_nvidia

Step 5: Run the installer
sudo bash install.sh

If the script exits immediately, you almost always left a required .env value empty or left TRANSMISSION_RPC_PASS as change_me.

Step 6: Open Homepage
The script prints the URL.
Typical:
http://<server-ip>:3000

Ports (if you need them)
Homepage:     3000
Plex:         32400
Sonarr:       8989
Radarr:       7878
Lidarr:       8686
Bazarr:       6767
Overseerr:    5055
Transmission: 9091
Prowlarr:     9696
FlareSolverr: 8191
LazyLibrarian:5299
Maintainerr:  6246

Transcoding guidance (beginner)
If the installer selects:
plex_nvidia
You likely have an NVIDIA GPU and Plex can do hardware transcoding once the host has NVIDIA drivers and the NVIDIA container runtime. If you have not installed NVIDIA drivers, Plex may still run but GPU transcoding will not work until you do.

plex_intel
You likely have an Intel/AMD iGPU device exposed as /dev/dri. This is what most small home servers use for efficient transcoding.

plex
No hardware device was detected. Assume software transcoding only.

What to do if you have no hardware transcoding
If you cannot hardware transcode, do not expect reliable 4K transcoding.
Use 1080p media for remote streaming.
If you must keep 4K, keep a separate 1080p copy for remote playback or use Direct Play only.

Post-install configuration order
1) Plex
Open Plex and sign in.
Create libraries:
Movies:      /media/movies
TV:          /media/tv
Music:       /media/music
Books:       /media/books
Audiobooks:  /media/audiobooks

2) Transmission
Open Transmission.
Confirm download folders:
Incomplete: /downloads/incomplete
Complete:   /downloads/complete

3) Sonarr, Radarr, Lidarr
Add download client:
Type: Transmission
Host: transmission
Port: 9091
Username: value from .env TRANSMISSION_RPC_USER
Password: value from .env TRANSMISSION_RPC_PASS

Set root folders:
Sonarr: /tv
Radarr: /movies
Lidarr: /music

4) Prowlarr
Add indexers.
Add applications (Sonarr/Radarr/Lidarr) and sync.
If an indexer needs FlareSolverr:
Set FlareSolverr URL to:
http://flaresolverr:8191

5) Overseerr
Connect to Plex.
Connect to Sonarr and Radarr.

6) Bazarr
Connect to Sonarr and Radarr.
Set language preferences.

7) Maintainerr
Connect to Plex and configure retention rules.

VPN notes (CGNAT)
If your ISP uses CGNAT, you cannot port forward into your home.
This does not stop downloading.
It does limit inbound torrent connectivity and can reduce seeding performance.

Updates
Watchtower runs on the schedule in WATCHTOWER_SCHEDULE.
Only containers with the watchtower label are updated (this stack labels them all).

Troubleshooting
View running containers:
cd /srv/docker/media-stack
docker compose ps

Logs:
docker logs gluetun
docker logs transmission
docker logs prowlarr
docker logs plex

Restart stack:
cd /srv/docker/media-stack
docker compose restart

Change configuration
Edit .env, then:
cd /srv/docker/media-stack
docker compose --env-file /path/to/repo/.env up -d
