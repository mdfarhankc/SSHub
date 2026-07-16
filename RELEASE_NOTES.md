## SSHub 4.0.0

New

- Files: a full SFTP file browser for every server. Browse in a list or a grid, upload, download, rename, delete and create folders. It opens its own connection, so it does not depend on a terminal being open
- Read-only mode, on by default: the file browser cannot change anything on the server until you unlock it, so a misclick on a production box stays harmless
- File viewer: open a text file straight from the browser instead of downloading it. Binary files are detected rather than shown as noise, and large files open as a capped preview
- Tabbed sessions: keep up to ten servers open at once. Each tab keeps its own scrollback while it sits in the background, and Ctrl+Tab or Alt+1-9 switches between them
- Forget host key: a rebuilt server presents a new host key, and SSHub can now be told to trust it again from the server's menu instead of refusing forever

Improvements

- A new icon set across the whole app: one consistent outlined style in place of the mix of filled and outlined icons
- Host keys are remembered per key type, so a server offering more than one key can no longer look like a changed host
- The file browser remembers whether you were in list or grid view, and whether hidden files were shown
- A dropped connection is now reported straight away instead of leaving the file browser waiting on a reply that never comes
- A minimum window size on desktop, so the layout cannot be squeezed into an unusable shape

Fixes

- Typing in a newly opened tab could go to the previously focused tab, which could run a command on the wrong server
- Closing a tab while it was still connecting left the SSH connection open
- Retrying a failed file session left the previous connection open
- Symlinked folders opened as files instead of being entered
- Starting a second download while one was running left the first with no visible progress
- The About screen referenced an icon that was missing from the bundle
