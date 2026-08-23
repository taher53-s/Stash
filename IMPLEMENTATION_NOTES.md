# Stash Native Product Update

This local update repairs and extends the native macOS Stash app without pushing any changes to GitHub.

## Product improvements

The shelf now uses a graphite-and-cyan material system aligned with the Stash product theme. It has an editable title, focused empty state, file cards, Quick Look, Finder reveal, copy-path controls, and both item-level and whole-shelf sharing. Whole-shelf sharing exposes AirDrop, Messages, Mail, and the standard macOS share sheet.

The menu bar uses the native archive-box symbol instead of emoji presentation. It has a single explicit **Settings…** menu entry; settings themselves are provided through the normal SwiftUI Settings scene, avoiding an additional shelf-level settings surface.

## Local app logic

The shake detector now requires meaningful directional strokes and forgets stale drag motion sooner, reducing accidental shelf reveals. The shelf window has more usable space, keeps to the selected window level, and stays within screen bounds near the cursor. Shelf defaults include menu-bar item count, floating behavior for newly created shelves, automatic recycling after inactivity, and a preferred sharing destination.

## Build on macOS

This package requires **macOS 14+** and Swift 6.2 or a compatible Xcode toolchain.

```bash
cd stash-product
swift build
swift run
```

On first launch, grant the Accessibility permission requested by Stash so the drag-shake gesture can be recognized. The app has no remote backend or cloud service; all changes are implemented as local AppKit/SwiftUI state and macOS share-service integration.

## Suggested smoke test

1. Launch Stash and create a shelf from the menu-bar item.
2. Drag a file, shake the pointer, and drop it into the shelf.
3. Double-click an item for Quick Look; test the item share and the shelf share menu.
4. Open **Settings…**, change a default, and create a new shelf to verify the selected behavior.
5. Rename a shelf, remove an item, and confirm the item count in the menu bar updates.
