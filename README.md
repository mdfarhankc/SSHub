# SSHub

A simple, local SSH connection manager built with Flutter. Store your servers, connect with one click, and work in an embedded terminal without external tools.

> Work in progress: the embedded terminal is currently under development.

## Features

- Manage your SSH servers as a grid of cards
- Passwords stored securely in the OS keychain (Windows Credential Manager, macOS Keychain, etc.), never in plain text
- Server list stored locally as JSON, so your data never leaves your machine
- Embedded in-app terminal via `dartssh2` + `xterm` (in progress)

### Planned

- SSH key authentication
- Edit / delete servers
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
| Terminal | xterm |
| Secret storage | flutter_secure_storage |

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
    └── ssh/
        ├── data/          # datasources, models, repository impl
        ├── domain/        # entities, repository interfaces
        └── presentation/  # blocs, pages, widgets
```

## Author

Mohammed Farhan K C ([@mdfarhankc](https://github.com/mdfarhankc))
