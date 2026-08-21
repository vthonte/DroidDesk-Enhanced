# Termux & DroidDesk 0-MB Shared Storage Migration Notes

## 📌 Architecture Overview & Goal
Make DroidDesk use existing Termux installation at `/data/data/com.termux/files` with **0 MB storage duplication** using Android's kernel-level shared UID mechanism (`android:sharedUserId="com.termux"`).

---

## 🔍 Key Findings & Security Architecture

1. **Android `sharedUserId` Security Constraint**:
   - Android OS enforces that two apps using the same `sharedUserId` (`com.termux`) **MUST be signed with the exact same developer private key**.
   - F-Droid Termux builds use F-Droid's server key (private).
   - GitHub Termux releases (`v0.118.0+`) use Termux's official open-source keystore (`testkey_untrusted.jks`).

2. **Verified Keystore Credentials**:
   - **Keystore File**: `app/android/app/testkey_untrusted.jks` (Downloaded from official `termux/termux-app` repository)
   - **Alias**: `alias`
   - **Store Password**: `xrj45yWGLbsO7W0v`
   - **Key Password**: `xrj45yWGLbsO7W0v`
   - **SHA-256 Fingerprint**: `B6:DA:01:48:0E:EF:D5:FB:F2:CD:37:71:B8:D1:02:1E:C7:91:30:4B:DD:6C:4B:F4:1D:3F:AA:BA:D4:8E:E5:E1`

3. **DroidDesk Build Configuration**:
   - `app/android/app/build.gradle.kts` is updated to sign both release and debug builds with `testkey_untrusted.jks`.
   - `AndroidManifest.xml` has `android:sharedUserId="com.termux"` re-enabled.

---

## 🚀 Step-by-Step Migration Guide

### 1. Perform Fresh Termux Backup
Run the export script in Termux:
```bash
bash export-termux-for-droiddesk.sh
```
This updates `/sdcard/Download/termux-backup.tar.gz`.

### 2. Uninstall F-Droid Termux
- Long-press Termux app icon -> **Uninstall**.

### 3. Install GitHub Termux
- Download and install [Termux v0.118.0 (GitHub Release ARM64)](https://github.com/termux/termux-app/releases/download/v0.118.0/termux-app_v0.118.0+github-debug_arm64-v8a.apk).

### 4. Restore Environment (1-Click)
Open GitHub Termux and run:
```bash
bash /sdcard/Download/restore-termux-for-github.sh
```
*(If storage prompt appears, tap Allow. Or grant in Settings > Apps > Termux > Permissions > Files and media > Allow management of all files).*

### 5. Install & Run DroidDesk
- Install `/sdcard/Download/DroidDesk-Enhanced.apk`.
- Select **XFCE4** on setup screen.
- Both apps now run side-by-side sharing `/data/data/com.termux/files` with **0 MB storage duplicate**!
