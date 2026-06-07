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

## Tech Stack

| | |
|---|---|
| Framework | Flutter |
| State management | flutter_bloc |
| SSH | dartssh2 |
| Terminal | xterm (vendored, see note) |
| Secret storage | flutter_secure_storage |

> Note: `third_party/xterm` is a local copy of [xterm.dart](https://github.com/TerminalStudio/xterm.dart) with a one-line fix for broken keyboard input on Flutter 3.44+ Windows ([xterm.dart#207](https://github.com/TerminalStudio/xterm.dart/issues/207)). The `dependency_overrides` entry in `pubspec.yaml` points to it and can be removed once the fix lands upstream.

## Getting Started

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
