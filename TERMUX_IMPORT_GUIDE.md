# DroidDesk - Termux Integration & Import Guide

This guide explains how to connect or import your existing **Termux** installation (`/data/data/com.termux/files`) into **DroidDesk** to avoid duplicating storage space.

---

## Overview

By default, DroidDesk extracts an isolated Termux bootstrap into its own app data directory (`/data/data/com.orailnoor.droiddesk/files/usr`). While this keeps DroidDesk self-contained, it can take **1.5 GB to 5+ GB** of additional storage if you already have a fully configured Termux environment.

With the new modular enhancements added to DroidDesk, you have **two ways** to import and reuse your existing Termux installation:

---

## Method 1: Zero-Duplication Direct Access (Shared User ID)

If both Termux and DroidDesk are built with the same signing key and `android:sharedUserId="com.termux"`:

- **Storage Space Used**: **0 MB extra**
- **Speed**: Instant (no extraction or copying required)
- **Features**: Direct access to your existing Termux packages, Python virtual environments, dotfiles, scripts, and binaries.

### How It Works:
1. `app/android/app/src/main/AndroidManifest.xml` specifies `android:sharedUserId="com.termux"`.
2. `LinuxRuntime.kt` detects that `/data/data/com.termux/files/usr/bin/bash` is directly accessible.
3. DroidDesk automatically binds `prefixDir` to `/data/data/com.termux/files/usr` and `homeDir` to `/data/data/com.termux/files/home`.
4. The DroidDesk desktop environment launches directly on top of your live Termux files!

---

## Method 2: Termux Backup Archive Import (Non-Shared UID)

If you are using pre-compiled APKs signed with different keys (where Android UID isolation prevents direct file access):

- **Storage Space Used**: Uses standard DroidDesk storage, but imports **all** your custom packages, shell configs, scripts, and data.
- **Ease of Use**: 1-click import script.

### Step 1: Export Your Termux Environment
Inside your existing Termux app, run the export script included in this repository:

```bash
bash export-termux-for-droiddesk.sh
```

This creates a compressed backup archive at `/sdcard/Download/termux-backup.tar.gz`.

### Step 2: Import into DroidDesk
1. Open **DroidDesk**.
2. Trigger the import via settings or MethodChannel call `importTermuxBackup("/sdcard/Download/termux-backup.tar.gz")`.
3. DroidDesk extracts the archive, patches shebangs, configures ELF paths, and rebuilds the native socket hook.
4. Your customized Termux environment is now ready inside DroidDesk!

---

## Technical Code Reference

The following native Kotlin and Dart bridge methods were added to support this integration:

- **Kotlin (`LinuxRuntime.kt`)**:
  - `isDirectTermuxAccessible`: Checks if `/data/data/com.termux/files/usr/bin/bash` is readable/executable.
  - `useDirectTermux`: Dynamic boolean preference to enable/disable direct Termux binding.
  - `importTermuxBackup(backupFile, onProgress)`: Extracts, patches shebangs, and configures external Termux tarball archives.

- **Kotlin (`MainActivity.kt`)**:
  - `isDirectTermuxAvailable`: MethodChannel query.
  - `useDirectTermuxPrefix`: MethodChannel toggle.
  - `importTermuxBackup`: MethodChannel handler with progress callbacks.

- **Dart (`platform_bridge.dart`)**:
  - `DroidDeskPlatform.isDirectTermuxAvailable()`
  - `DroidDeskPlatform.useDirectTermuxPrefix({bool enable})`
  - `DroidDeskPlatform.importTermuxBackup(String filePath)`

---

## Creating a Pull Request

These changes are modular, backward-compatible, and fall back safely to standard DroidDesk behavior when Termux is not accessible. You can submit these modifications as a PR to the [DroidDesk-Enhanced Repository](https://github.com/techjarves/DroidDesk-Enhanced).
