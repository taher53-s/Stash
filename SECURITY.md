# Stash Security and Privacy Model

Stash is a local macOS utility. It does not use a remote backend, make network requests, upload shelf contents, or persist copies of dropped files. A shelf keeps local URLs for items the user explicitly drags into the app.

## File handling

The app validates each dropped item before adding it to a shelf. Only readable local files or directories are accepted, and symbolic links are resolved before the readable-item check. Share commands revalidate every item before invoking a macOS sharing service.

## Permissions

Stash requests Accessibility permission so it can recognize the drag-and-shake gesture. The permission is not used to read file contents, monitor typing, transmit data, or automate other applications. File actions use the standard macOS Quick Look, Finder, clipboard, and sharing APIs after a user gesture.

## Distribution

For public distribution, build a signed `Stash.app` on macOS with the hardened runtime, then notarize the archive with an Apple Developer account before distribution. Do not distribute an unsigned development build as a release. See `RELEASE_SECURITY.md` and the scripts in `Scripts/` for the complete local workflow.
