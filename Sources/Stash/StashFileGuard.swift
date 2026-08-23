// Native safety layer: Stash only accepts readable local items explicitly dropped by the user.
import Foundation

enum StashFileGuard {
    static func usableLocalURL(_ url: URL) -> URL? {
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
        guard resolved.isFileURL else { return nil }

        guard let values = try? resolved.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey]),
              values.isRegularFile == true || values.isDirectory == true,
              FileManager.default.isReadableFile(atPath: resolved.path) else {
            return nil
        }

        return resolved
    }

    @discardableResult
    static func withScopedAccess<T>(to url: URL, perform work: () -> T) -> T {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return work()
    }
}
