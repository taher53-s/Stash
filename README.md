# Stash

Stash is an open-source macOS utility that provides a temporary "shelf" for your files.

Drag files from anywhere, "shake" your mouse, and the Stash shelf will appear. Drop your files in to stash them temporarily. When you navigate to your final destination folder, simply drag them out of the shelf!

## Features

- **Global Shake Detection:** Just drag a file and shake your mouse to reveal the shelf.
- **Native SwiftUI Interface:** Clean, lightweight, and blazingly fast.
- **Privacy First:** Stash runs entirely locally on your Mac. No internet connection required.

## Installation

Download the latest release from the [Releases](https://github.com/) tab and drag `Stash.app` to your Applications folder.

### Important: Accessibility Permissions
Because Stash needs to detect mouse dragging across the entire system, macOS requires you to grant it Accessibility permissions.
1. Open **System Settings** > **Privacy & Security** > **Accessibility**.
2. Click the `+` button and add Stash, or toggle the switch next to it if it's already in the list.

## Building from Source

Stash is built using the Swift Package Manager. You don't even need Xcode!

```bash
git clone https://github.com/your-username/Stash.git
cd Stash
make
open Stash.app
```
