## SSHub 2.1.0

New

- SSH key authentication: connect with a private key (OpenSSH, RSA, or EC), with an optional key passphrase and file import
- Host key verification: SSHub remembers each server's fingerprint and refuses to connect if it changes
- Terminal copy and paste: Ctrl+C copies when text is selected, plus paste, select all, and a right-click menu
- Terminal search: find in the scrollback with Ctrl+F and jump between matches
- Backups are now encrypted by default, with stronger key derivation

Fixes

- App lock no longer turns off when you cancel the authentication prompt
- macOS: backup import and export now work (sandboxed file access)

Improvements

- Refreshed page transitions and a tidier settings layout
