# SSHub

SSHub is a fast, minimal SSH client for the desktop, built with Flutter. Save your servers, connect with one click, and work in a full terminal. Credentials stay encrypted on your machine.

## Features

- Manage your SSH servers as a grid of cards, with add / edit / delete and color tags
- Live server status: each card shows whether the host is online, offline, or being checked
- Password or SSH key authentication (OpenSSH, RSA, or EC keys, with an optional key passphrase)
- Host key verification: SSHub remembers each server's fingerprint per key type and refuses to connect if it changes, with a deliberate "forget host key" action for servers you rebuilt
- Full in-app terminal powered by `dartssh2` + `xterm`, with copy / paste, select all, and find-in-scrollback
- Tabbed sessions: up to ten servers open at once, each keeping its own scrollback, with keyboard switching
- SFTP file browser: browse in a list or a grid, upload, download, rename, delete and create folders, over its own connection
- Read-only mode, on by default, so the file browser cannot change anything on the server until you unlock it
- Built-in file viewer for text files, with binary detection and a size cap
- Auto-reconnect: dropped connections retry on their own before reporting a failure
- Snippets: save reusable commands or credentials and paste them into any session
- Keyboard shortcuts for common actions, with an in-app cheat sheet
- App lock with biometric / system unlock
- Encrypted backup export and import to move your data between machines
- In-app update check against the latest GitHub release
- Credentials stored securely in the OS keychain (Windows Credential Manager, macOS Keychain, etc.), never in plain text; keys stay on your machine and are excluded from backups
- Server list stored locally as JSON, so your data never leaves your machine
- Settings: light / dark / system theme, terminal font size and family
- Friendly connection errors with one-click retry

### Planned

- Downloading and uploading whole folders
- Editing a remote file in place
- Selecting multiple files for batch actions
- A transfer queue, so more than one transfer can run at a time
- Resuming an interrupted transfer instead of starting over
- Viewing and changing file permissions
- Searching within a folder

## Platforms

Windows, Linux, macOS, Android, iOS

Desktop (Windows) is the primary target. Web is not supported because browsers cannot open the raw TCP sockets that SSH requires.

## Installation

Download the build for your platform from the [Releases page](https://github.com/mdfarhankc/SSHub/releases/latest), then follow the short steps below.

> The builds aren't code-signed yet, so your OS shows a one-time "unknown developer" warning the first time you open the app. That's expected, and the steps below get past it.

### Windows

1. Download **`sshub-windows-setup.exe`** and run it.
2. If SmartScreen pops up: click **More info** -> **Run anyway**.

Prefer no installer? Download **`sshub-windows-x64-portable.zip`**, extract the whole folder, and run `sshub.exe` inside it.

### macOS

1. Open **`sshub-macos.dmg`** and drag **SSHub** into **Applications**.
2. If macOS says the app is "damaged", run this once in Terminal, then open it normally:
   ```bash
   xattr -dr com.apple.quarantine /Applications/SSHub.app
   ```

### Linux

**AppImage** (easiest):

```bash
chmod +x sshub-linux-x86_64.AppImage
./sshub-linux-x86_64.AppImage
```

FUSE error? Run `sudo apt install libfuse2`.

**Tarball:** extract **`sshub-linux-x64.tar.gz`** and run `./sshub` (needs GTK 3 and libsecret, which most desktops already have).

### Android

1. Download and open **`sshub-android.apk`**.
2. Allow **install from unknown apps** if asked; if Play Protect warns, tap **Install anyway**.

### iOS

No prebuilt download. Build from source with Xcode using your own signing identity (see below).

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

## Building Release Artifacts Locally

The GitHub Actions workflow (`.github/workflows/release.yml`) builds every
platform's artifact on a version tag push. You can reproduce any of them
locally. Each platform must be built on its own OS.

### Windows (installer + portable zip)

Requires [Inno Setup 6](https://jrsoftware.org/isdl.php): `winget install JRSoftware.InnoSetup`.

```powershell
flutter build windows --release
# Installer -> dist/sshub-windows-setup.exe
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" windows\packaging\sshub.iss
# Portable  -> dist/sshub-windows-x64-portable.zip
Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath dist/sshub-windows-x64-portable.zip
```

> A machine-wide Inno Setup install lives at `C:\Program Files (x86)\Inno Setup 6\ISCC.exe` instead.

### Linux (AppImage + tarball)

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev
flutter build linux --release

# Tarball -> dist/sshub-linux-x64.tar.gz
mkdir -p dist
tar -czf dist/sshub-linux-x64.tar.gz -C build/linux/x64/release/bundle .

# AppImage -> dist/sshub-linux-x86_64.AppImage
mkdir -p AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/
cp assets/icon/icon.png AppDir/sshub.png
printf '%s\n' '[Desktop Entry]' 'Name=SSHub' 'Exec=sshub' 'Icon=sshub' 'Type=Application' 'Categories=Utility;' > AppDir/sshub.desktop
printf '%s\n' '#!/bin/bash' 'HERE="$(dirname "$(readlink -f "${0}")")"' 'exec "${HERE}/usr/bin/sshub" "$@"' > AppDir/AppRun
chmod +x AppDir/AppRun
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
APPIMAGE_EXTRACT_AND_RUN=1 ./appimagetool-x86_64.AppImage AppDir dist/sshub-linux-x86_64.AppImage
```

### macOS (dmg)

```bash
flutter build macos --release
APP=$(ls -d build/macos/Build/Products/Release/*.app | head -1)
mkdir -p dmg dist
cp -R "$APP" dmg/
ln -s /Applications dmg/Applications
hdiutil create -volname "SSHub" -srcfolder dmg -ov -format UDZO dist/sshub-macos.dmg
```

### Android (apk)

```bash
flutter build apk --release   # -> build/app/outputs/flutter-apk/app-release.apk
```

> Release signing needs `android/key.properties` and the keystore, which are
> gitignored and never committed. Without them the build is unsigned. In CI
> these are restored from repository secrets.

## Cutting a Release

1. Bump the version in all four places: `pubspec.yaml`, `lib/core/app_info.dart`,
   `windows/packaging/sshub.iss`, and `site/src/lib/site.ts`.
2. Update `RELEASE_NOTES.md` (its contents become the GitHub release body, and
   its heading carries the version too).
3. Check that nothing drifted:

   ```bash
   make version
   ```

4. Commit, then tag and push:

   ```bash
   make tag                     # refuses to tag unless every file agrees
   git push origin main --tags
   ```

The tag push triggers the workflow, which builds all platforms and attaches
the artifacts above to a GitHub release named after the tag.

## Project Structure

Feature-first clean architecture:

```
lib/
├── core/            # auth, backup, di, logging, router, shortcuts, theme, update, widgets
└── features/
    ├── onboarding/
    ├── splash/
    ├── settings/
    ├── sftp/
    ├── snippets/
    └── ssh/
        ├── data/          # datasources, models, repository impls
        ├── domain/        # entities, repository interfaces, usecases
        └── presentation/  # blocs, cubits, pages, widgets
```

## Contributing

SSHub is not accepting external code contributions at the moment, so pull
requests will be closed for now. Bug reports and feature ideas are very
welcome though, please open an issue using one of the templates.

## License

SSHub is licensed under the [GNU General Public License v3.0](LICENSE). You are
free to use, run, study and share it, and any distributed derivative must remain
open under the same license and keep the original copyright notice.

The vendored `third_party/xterm` copy keeps its own license, included alongside it.

## Author

Mohammed Farhan K C ([@mdfarhankc](https://github.com/mdfarhankc))
