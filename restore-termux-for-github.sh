#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "====================================================="
echo "        DroidDesk - 1-Click Termux Restore          "
echo "====================================================="
echo ""

BACKUP_PATH="/sdcard/Download/termux-backup.tar.gz"

if [ ! -f "$BACKUP_PATH" ]; then
    echo "❌ Error: Backup archive not found at $BACKUP_PATH"
    echo "Please ensure termux-backup.tar.gz is present in Downloads."
    exit 1
fi

echo "[+] Target backup found: $BACKUP_PATH ($(du -h "$BACKUP_PATH" | cut -f1))"
echo "[*] Granting storage permissions..."
termux-setup-storage || true

echo "[*] Unpacking backup into GitHub Termux environment (please wait ~1-2 mins)..."
tar -zxf "$BACKUP_PATH" -C / --overwrite

echo ""
echo "====================================================="
echo " [✔] Termux Restore Complete!"
echo "-----------------------------------------------------"
echo " All packages, python environments, dotfiles, and"
echo " proot containers are 100% restored."
echo ""
echo " You can now launch DroidDesk! Both Termux and DroidDesk"
echo " are linked to common storage (0 MB storage duplicate)."
echo "====================================================="
