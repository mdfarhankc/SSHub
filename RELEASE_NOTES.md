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
