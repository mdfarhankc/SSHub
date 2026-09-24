## SSHub 4.6.0

This release adds a live server info panel that reads a server's resource use over SSH: CPU, memory, swap, storage and, where present, GPU, along with the processes using the most CPU.

New

- A server info panel showing live CPU usage and load, memory and swap, storage per mount, and GPU where nvidia-smi is available, plus the OS, kernel and uptime. Open it from a server card's menu, or from the info button while a terminal or file browser is open
- On wide screens a compact live stats strip sits above the terminal and file browser; on a phone it is hidden and the info button opens the full panel instead
- View all processes on a server, sorted by CPU and showing actual memory use, loaded on demand with a Load more button rather than polled
- The panel pauses while the app is in the background and reconnects on its own with a growing back-off if the connection drops, showing a reconnecting note while it retries

## SSHub 4.5.0

This release rounds out the file browser: edit permissions and ownership, search a folder, upload a whole folder, and select many files at once. It also fixes a stall that could hang a large folder download.

New

- Edit a file or folder's Unix permissions from a simple read/write/execute grid, with the octal value shown live. The dialog also shows the owner and group, and lets you change them where you have the rights (changing ownership needs root)
- Search the current folder: open the search bar, type, and the listing filters by name as you go
- Upload a whole folder, streamed as one archive the same way folder download works, with a per-file fallback for servers without tar
- Select several files and folders at once, then download or delete them in one go. A batch download reports its result as a single success and a single error message rather than one per item

Improvements

- Navigate the path bar's folder suggestions with the arrow keys and pick one with Enter, not just the mouse
- A Browse files button on each server card opens the file browser in one tap, without the menu
- The backup passphrase now requires at least 8 characters

Fixes

- A large folder download could stall part way and then refuse to cancel, holding up every later transfer. The download no longer stalls, Cancel always works, and a stalled transfer now recovers on its own
- A workflow's first step could show a secret value in the workflows list. Secret steps are never shown now
- Folder downloads reject an archive that tries to write outside the chosen folder, and no longer skip .git
- Rapid workflow edits could drop a saved workflow. Saves are serialised now

## SSHub 4.4.0

This release adds workflows, a way to run a command and answer the prompts that follow in a single tap, and moves the app onto the latest Flutter and dependencies.

New

- Workflows: save a sequence that sends a command and replies to the prompts it triggers. A git pull can send the command, then fill in the username and password on its own. Each step can carry {{host}}, {{user}} and {{port}} for the current server, or {{prompt:Label}} to ask for a value when it runs. A step marked secret is hidden and asks to unlock before running. Open the picker in a terminal with Ctrl+Shift+R, and manage workflows from the home screen

Improvements

- Updated to the latest Flutter and dependencies

Fixes

- A command snippet that asks for a value did not run when picked from the terminal. It runs now
- Simplified the home tag filter to All and your tags

## SSHub 4.3.0

This release adds server tags, a jump-to-path file browser and one consistent menu across the app, along with the security and performance fixes from a full audit.

New

- Tag your servers and filter the home screen by tag, so a long list stays manageable. A server can carry several tags at once, and typing a tag suggests ones you already use
- Jump straight to a folder in the file browser: click the path, type where you want to go and press Enter. Folder names complete as you type, and each level is listed only once rather than on every keystroke
- Right-click or long-press a file to open the same lifted menu the server cards use, with download, rename and delete
- The snippets page splits into Secrets and Commands columns, each reordered on its own

Improvements

- A folder download now refuses any server-supplied name that would write outside the folder you chose, so a malicious listing cannot drop files elsewhere on your machine
- Every menu shares one look now: server cards, tabs, the file browser and the terminal's right-click menu
- The terminal's find box is a floating panel rather than a full-width bar, and no longer draws a stray border when focused
- Copying from the terminal with the keyboard stays marked sensitive, matching the on-screen copy
- Find no longer rescans the whole scrollback on every keystroke, and changing a setting no longer rebuilds every open terminal
- The back button and the file browser's up control use clearer icons

## SSHub 4.2.0

This release brings a unified workspace, a reworked snippets system and customisable keyboard shortcuts.

New

- Terminals and file browsers now share one tab strip, opened side by side and kept connected while you move around your servers. Right-click a tab to duplicate it or close others
- Snippets can be a hidden Secret or a plain Command. Commands are shown in full and searchable, and any snippet can be inserted, run, or copied. Commands can carry {{host}}, {{user}} and {{port}} for the current session, or {{prompt:Label}} to ask for a value when used. Pin the ones you use most and drag to reorder them
- Rebind most keyboard shortcuts in Settings, with conflict detection and a reset to defaults
- A terminal bell you can set to flash the screen, play a native sound, or both
- Choose the terminal cursor shape: block, bar or underline
- Manage remembered SSH host keys in Settings, and forget one when a server is rebuilt
- A dedicated Help page listing every shortcut and short guides to each feature
- Set a default port and username that prefill when you add a server
- Terminal options for copy on select, paste on right click and reduced motion

Improvements

- Dragging a selection past the top or bottom edge now scrolls through the scrollback, and holding Shift extends an existing selection
- Ctrl+C copies when text is selected and sends the interrupt when nothing is, the way Windows Terminal and PuTTY behave. Ctrl+Shift+C still copies explicitly
- Pasting a large or multi-line block asks for confirmation first, so an accidental paste cannot quietly run commands
- Settings are reorganised into focused sections
- Lifted, iOS-style menus on server cards and tabs, with a blurred backdrop behind sheets and menus

## SSHub 4.1.0

This release closes several security gaps found in 4.0.0. Updating is recommended.

New

- Download a whole folder, with everything inside it. Files transfer as the walk finds them, so a large folder starts moving straight away instead of waiting for the whole tree to be listed
- Stop a transfer while it is running. A cancelled download removes its half-written file, and a cancelled upload removes the partial file on the server, so neither is left standing in for a complete one
- Choose where downloads are saved, in Settings. Every download goes there on every platform, and the folder is checked before it is kept
- Block screenshots, on by default on Android, which also hides SSHub from the recent apps preview

Improvements

- Folder downloads move several files at once and no longer ask the server for a size it already reported, which makes a folder of many small files dramatically faster
- Transfers show elapsed time while running and report how long they took when they finish
- Changing folders now shows that it is working, and a slower earlier request can no longer land after a newer one
- Text copied from the terminal or the file viewer is flagged as sensitive, so keyboards and clipboard previews do not show it in clear text
- Deleting a folder asks for its name to be typed back, since it takes everything inside

Fixes

- App lock silently allowed everything when the device had no screen lock. It now refuses to be enabled without one, and secret reveals stay hidden rather than opening
- Clear all data left remembered host keys behind, so a later server on the same address was trusted without a prompt. It now clears host keys and snippets too
- Switching a server between password and key authentication erased the other credential for good
- Uploading a file whose name already existed replaced it on the server with no warning
- The snippet picker pasted values without the authentication its own setting promises
- Ctrl+C copied instead of interrupting whenever a selection had been left behind. Copy is now Ctrl+Shift+C, matching the menu
- Deleting a folder with anything inside it failed instead of removing it
- A dropped connection replaced the scrollback with a status screen, hiding the output you needed to read. The session now stays visible under a banner
- Reconnecting a tab could write its older copy of a server back over edits made since
- An unexpected error during a transfer left the file browser refusing every later transfer
- Connecting could hang for good if a server accepted the connection then stalled before signing in
- Auto-reconnect could not be stopped, and a manual retry raced it
- The splash screen could hang for good if stored data never loaded
- Snippet failures were invisible, and a failed load looked like an empty list, inviting you to recreate snippets that were still there
- Key authentication failures said to check a password that is not used
