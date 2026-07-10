## SSHub 3.0.0

New

- Auto-reconnect: if a connection drops unexpectedly, SSHub retries on its own and only reports a failure once the retries are exhausted
- Live server status: each server card shows whether the host is online, offline, or being checked
- Private keys stay out of backups: your key never leaves your machine, so a shared backup file can't leak a reusable credential (passwords are still included)

Improvements

- Tighter, more consistent UI across the home, terminal, and settings screens
- Clearer connection status while reconnecting

Docs

- README now covers building the release artifacts locally and cutting a release, with a simpler install guide
