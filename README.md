# SSHub

SSHub is a fast, minimal SSH client for the desktop, built with Flutter. Save your servers, connect with one click, and work in a full terminal. Credentials stay encrypted on your machine.

## Features

- Manage your SSH servers as a grid of cards
- Add, edit and delete servers
- Color tag each server for quick visual identification
- Full in-app terminal powered by `dartssh2` + `xterm`
- Passwords stored securely in the OS keychain (Windows Credential Manager, macOS Keychain, etc.), never in plain text
- Server list stored locally as JSON, so your data never leaves your machine
- Settings: light / dark / system theme, terminal font size and family
- Friendly connection errors with one-click retry

### Planned

- SSH key authentication
- Multiple sessions and tabs
- Host key verification

## Platforms

Windows, Linux, macOS, Android, iOS

Desktop (Windows) is the primary target. Web is not supported because browsers cannot open the raw TCP sockets that SSH requires.

## Installation

Grab the latest build for your platform from the [Releases page](https://github.com/mdfarhankc/SSHub/releases/latest).

The desktop builds are not code-signed or notarized yet, so each OS shows a one-time security prompt the first time you open a downloaded build. The steps below clear it; this is expected for an unsigned app, not a sign that anything is wrong.

### Windows

- **Installer (recommended):** download `sshub-windows-setup.exe` and run it. SmartScreen may show "Windows protected your PC" -> click **More info** -> **Run anyway**. The installer adds SSHub to the Start Menu and registers an uninstaller.
- **Portable:** download `sshub-windows-x64-portable.zip` and extract it anywhere, then run `sshub.exe`. Keep the extracted folder intact, the executable needs the DLLs and the `data/` folder beside it.

### macOS

The `.dmg` is unsigned and not notarized, so Gatekeeper blocks it by default (you may see "SSHub is damaged and can't be opened").

1. Open `sshub-macos.dmg` and drag **SSHub** into **Applications**.
2. Clear the quarantine flag once, then launch:
   ```bash
   xattr -dr com.apple.quarantine /Applications/SSHub.app
   open /Applications/SSHub.app
   ```
   Alternatively, try to open it once, then allow it under **System Settings -> Privacy & Security -> Open Anyway**.

### Linux

- **AppImage (recommended):**
  ```bash
  chmod +x sshub-linux-x86_64.AppImage
  ./sshub-linux-x86_64.AppImage
  ```
  If it fails with a FUSE error, install `libfuse2` (`sudo apt install libfuse2`) or run it with `--appimage-extract-and-run`.
- **Portable tarball:**
  ```bash
  tar -xzf sshub-linux-x64.tar.gz
  ./sshub
  ```
  Needs GTK 3 and libsecret (`sudo apt install libgtk-3-0 libsecret-1-0`), which most desktops already ship. libsecret backs the encrypted credential store.

### Android

1. Download `sshub-android.apk`.
2. Open it, then allow your browser or file manager to **install unknown apps** when prompted.
3. Play Protect may warn about an unknown developer, choose **Install anyway**. The build is signed with the project's release key.

### iOS

No prebuilt download. Build it from source with Xcode using your own signing identity (see below).

## Tech Stack

| | |
|---|---|
| Framework | Flutter |
| State management | flutter_bloc |
| SSH | dartssh2 |
| Terminal | xterm (vendored, see note) |
| Secret storage | flutter_secure_storage |

> Note: `third_party/xterm` is a local copy of [xterm.dart](https://github.com/TerminalStudio/xterm.dart) with a one-line fix for broken keyboard input on Flutter 3.44+ Windows ([xterm.dart#207](https://github.com/TerminalStudio/xterm.dart/issues/207)). The `dependency_overrides` entry in `pubspec.yaml` points to it and can be removed once the fix lands upstream.

## Build from Source

```bash
git clone https://github.com/mdfarhankc/SSHub.git
cd SSHub
flutter pub get
flutter run -d windows   # or linux / macos / your device
```

## Project Structure

Feature-first clean architecture:

```
lib/
├── core/            # router, theme
└── features/
    ├── splash/
    ├── settings/
    └── ssh/
        ├── data/          # datasources, models, repository impls
        ├── domain/        # entities, repository interfaces, usecases
        └── presentation/  # blocs, cubits, pages, widgets
```

## Author

Mohammed Farhan K C ([@mdfarhankc](https://github.com/mdfarhankc))
