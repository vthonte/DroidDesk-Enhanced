#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# DroidDesk Termux Export Helper
#
# Run this script inside your existing Termux app to export your installed
# packages, configuration files, dotfiles, and home directory into a backup archive.
# DroidDesk can then import this archive directly without downloading a second bootstrap!
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}        DroidDesk - Termux Export Utility           ${NC}"
echo -e "${CYAN}=====================================================${NC}"

# Check if running in Termux
if [ ! -d "/data/data/com.termux/files/usr" ]; then
    echo -e "${RED}[!] Error: This script must be run inside standard Termux.${NC}"
    exit 1
fi

# Request storage permission if needed
if [ ! -d "/sdcard" ]; then
    echo -e "${YELLOW}[*] Requesting storage access...${NC}"
    termux-setup-storage
    sleep 2
fi

OUTPUT_DIR="/sdcard/Download"
[ -d "$OUTPUT_DIR" ] || OUTPUT_DIR="/sdcard"
EXPORT_FILE="${OUTPUT_DIR}/termux-backup.tar.gz"

echo -e "${GREEN}[+] Target export location: ${WHITE}${EXPORT_FILE}${NC}"
echo -e "${YELLOW}[*] Preparing backup archive (excluding temporary cache files)...${NC}"

# Create export archive excluding locks and cache
tar -czf "$EXPORT_FILE" \
    --exclude="usr/tmp/*" \
    --exclude="usr/var/cache/apt/archives/*.deb" \
    --exclude="home/.cache/*" \
    -C /data/data/com.termux/files usr home

FILE_SIZE=$(du -h "$EXPORT_FILE" | cut -f1)

echo -e "\n${GREEN}[✔] Termux export complete! Archive size: ${WHITE}${FILE_SIZE}${NC}"
echo -e "${CYAN}-----------------------------------------------------${NC}"
echo -e "${WHITE}Next steps to import into DroidDesk:${NC}"
echo -e "1. Install and open the DroidDesk APK."
echo -e "2. In DroidDesk setup/settings, select ${GREEN}'Import Termux Backup'${NC}."
echo -e "3. Point to: ${WHITE}${EXPORT_FILE}${NC}"
echo -e "4. DroidDesk will configure your packages automatically!"
echo -e "${CYAN}=====================================================${NC}"
