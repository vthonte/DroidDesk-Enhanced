# Termux Integration Guide: Share Import (0 MB) vs Copy Import

This document explains how DroidDesk integrates with an existing Termux installation on Android. It covers both **Share Import** (0 MB storage duplication) and **Copy Import** (non-destructive tarball backup), along with instructions for users and context for AI coding assistants.

---

## 📌 1. Integration Modes Overview

| Feature | Mode 1: Share Import (Direct Link) | Mode 2: Copy Import (Tarball Migration) |
|---|---|---|
| **Storage Usage** | **0 MB extra storage** | Copies files to DroidDesk private storage |
| **Data Sync** | Live real-time two-way synchronization | Standalone copy inside DroidDesk |
| **Termux Version** | Requires GitHub Termux (`v0.118.0+`) | Works with ANY Termux (F-Droid, GitHub, Play Store) |
| **Android Mechanism** | `android:sharedUserId="com.termux"` | Tarball archive extraction via storage permissions |
| **Data Safety** | Shared live directory | Original Termux data remains safe & untouched |

---

## 🚀 2. Mode 1: Share Import (0 MB Shared Storage)

### How It Works
Android OS kernel assigns both Termux (`com.termux`) and DroidDesk (`com.orailnoor.droiddesk`) to the **exact same Linux User ID** using `android:sharedUserId="com.termux"`. Both apps read and write to `/data/data/com.termux/files` in real time with **zero file copying**.

### Signature Security Requirement
Android OS requires that two apps sharing a `sharedUserId` **MUST be signed with the exact same certificate key**.
- DroidDesk in this repository is configured (`app/android/app/build.gradle.kts`) to sign both debug and release builds with official Termux test keys (`testkey_untrusted.jks`).

### Steps for Share Import (0 MB)
1. **Backup Existing Termux** (if transitioning from F-Droid):
   ```bash
   bash export-termux-for-droiddesk.sh
   ```
2. **Uninstall F-Droid Termux** and install [GitHub Termux v0.118.0+ (ARM64)](https://github.com/termux/termux-app/releases/download/v0.118.0/termux-app_v0.118.0+github-debug_arm64-v8a.apk).
3. **Restore Backup into GitHub Termux**:
   ```bash
   bash /sdcard/Download/restore-termux-for-github.sh
   ```
4. **Install & Launch DroidDesk**:
   - Install `DroidDesk-Enhanced.apk`.
   - On the onboarding screen or in **Desktop Tools > Termux Integration**, tap **Link Direct (0 MB)**.
   - Select **XFCE4** and launch your desktop!

---

## 📦 3. Mode 2: Copy Import (Non-Destructive Tarball Import)

### How It Works
If you prefer not to uninstall F-Droid Termux, DroidDesk can import a backup archive (`termux-backup.tar.gz`) directly into DroidDesk's private app directory (`/data/user/0/com.orailnoor.droiddesk/files`).

### Steps for Copy Import
1. **Export Termux Backup**:
   ```bash
   bash export-termux-for-droiddesk.sh
   ```
2. **Import inside DroidDesk**:
   - Open DroidDesk -> Tap **Import Backup Tarball (.tar.gz)**.
   - Path: `/sdcard/Download/termux-backup.tar.gz`.
   - DroidDesk extracts and patches shebangs/runpaths automatically.
3. **Reclaim Storage**:
   - Once desktop functionality is verified, delete `/sdcard/Download/termux-backup.tar.gz` and clear/uninstall original Termux to free up storage.

---

## 🤖 4. Technical Reference & AI Agent Context

For AI coding assistants maintaining or extending this codebase:

- **AndroidManifest**: Defined with `android:sharedUserId="com.termux"` in `app/android/app/src/main/AndroidManifest.xml`.
- **Keystore Location**: `app/android/app/testkey_untrusted.jks`
  - Alias: `alias`
  - Store Password / Key Password: `xrj45yWGLbsO7W0v`
  - SHA-256 Fingerprint: `B6:DA:01:48:0E:EF:D5:FB:F2:CD:37:71:B8:D1:02:1E:C7:91:30:4B:DD:6C:4B:F4:1D:3F:AA:BA:D4:8E:E5:E1`
- **Dynamic Prefix Resolution**: Handled in `LinuxRuntime.kt` (`prefixDir` / `homeDir` dynamically resolve to `/data/data/com.termux/files/usr` or app `baseDir`).
- **UI Cards**: Implemented in `app/lib/screens/setup/de_picker.dart` and `app/lib/screens/desktop_tools_screen.dart`.
- **1-Click Restore Utility**: `restore-termux-for-github.sh` handles setup storage and tarball extraction into `/data/data/com.termux/files`.
