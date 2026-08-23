# Stash macOS Release Workflow

Stash is designed as a menu-bar utility, so a normal release should be a signed `Stash.app` bundle placed in **Applications**. The included `Scripts/build_app.sh` generates that bundle from the Swift package; the user can drag the resulting app into `/Applications` or run the equivalent Finder action. It sets the utility category, requires macOS 14 or later, and uses `LSUIElement` so Stash lives in the menu bar rather than showing a Dock icon.

## Release path

| Stage | Local command | Result |
|---|---|---|
| Build an app bundle | `ARCH=arm64 Scripts/build_app.sh` | Creates `dist/Stash.app`. |
| Create a universal build | Build once for `arm64` and once for `x86_64`, then merge binaries with `lipo`. | Supports Apple Silicon and Intel Macs. |
| Sign for distribution | `CODESIGN_IDENTITY="Developer ID Application: …" Scripts/build_app.sh` | Applies a Developer ID signature, secure timestamp, and hardened runtime. |
| Notarize and staple | `NOTARY_KEYCHAIN_PROFILE=stash-notary Scripts/notarize_app.sh` | Sends the signed release to Apple and attaches the returned ticket. |
| Verify before sharing | `Scripts/smoke_test_app.sh` | Verifies bundle metadata and signature, then lists the manual product smoke test. |

Apple’s current distribution guidance requires a Developer ID signature, Hardened Runtime, secure timestamp, and a notarization workflow for direct macOS distribution; Apple documents `notarytool` as the current submission utility.[1] The build script deliberately enables the hardened runtime without runtime-exception entitlements. Apple recommends adding only the exceptions that an app strictly requires.[2]

## Local protections included in this source package

Stash accepts only readable local items that the user explicitly drops into a shelf. It resolves symbolic links before validation, refuses non-file URLs, and revalidates all files before a share command. The app does not include a network backend, telemetry client, upload path, or cloud store. Accessibility permission is requested only to recognize the drag-and-shake gesture, while sharing uses the user-triggered macOS sharing APIs.

## Developer setup required before public release

The final release must be built on a Mac with Xcode 15.3 or later and an Apple Developer account. Set `CODESIGN_IDENTITY` to the Developer ID Application certificate selected in Keychain Access. Create and store a `notarytool` keychain profile on that Mac, then pass its name through `NOTARY_KEYCHAIN_PROFILE`. Review Apple’s notarization log and complete the manual smoke test before distributing any build.

> **Important:** The ZIP prepared in this environment is source and release tooling, not a signed `Stash.app`. Signing, notarization, and native execution require the owner’s macOS/Xcode environment and Developer ID credentials.

## References

[1]: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution "Apple Developer: Notarizing macOS software before distribution"
[2]: https://developer.apple.com/documentation/security/hardened-runtime "Apple Developer: Hardened Runtime"
