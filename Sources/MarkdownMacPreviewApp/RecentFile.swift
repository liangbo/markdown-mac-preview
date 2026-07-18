import Foundation

struct RecentFile: Identifiable, Equatable {
    let url: URL

    var id: String {
        url.standardizedFileURL.path
    }

    var fileName: String {
        url.lastPathComponent
    }

    var parentPath: String {
        url.deletingLastPathComponent().path
    }
}

final class RecentFilesStore {
    private let defaults: UserDefaults
    private let key: String
    private let limit: Int

    init(defaults: UserDefaults = .standard, key: String = "mdPreview.recentFiles", limit: Int = 20) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
    }

    func load() -> [RecentFile] {
        let paths = defaults.stringArray(forKey: key) ?? []
        return paths
            .map { URL(fileURLWithPath: $0).standardizedFileURL }
            .filter(Self.isSupportedMarkdownURL)
            .reduce(into: [RecentFile]()) { files, url in
                guard !files.contains(where: { $0.url == url }) else { return }
                files.append(RecentFile(url: url))
            }
            .prefix(limit)
            .map { $0 }
    }

    @discardableResult
    func record(_ url: URL, promoteExisting: Bool = true) -> [RecentFile] {
        guard Self.isSupportedMarkdownURL(url) else {
            return load()
        }

        let standardizedURL = url.standardizedFileURL
        var files = load()
        if !promoteExisting, files.contains(where: { $0.url == standardizedURL }) {
            return files
        }

        files = files.filter { $0.url != standardizedURL }
        files.insert(RecentFile(url: standardizedURL), at: 0)
        files = Array(files.prefix(limit))
        save(files)
        return files
    }

    @discardableResult
    func reorder(fromOffsets source: IndexSet, toOffset destination: Int) -> [RecentFile] {
        var files = load()
        files.move(fromOffsets: source, toOffset: destination)
        save(files)
        return files
    }

    @discardableResult
    func remove(_ url: URL) -> [RecentFile] {
        let standardizedURL = url.standardizedFileURL
        let files = load().filter { $0.url != standardizedURL }
        save(files)
        return files
    }

    static func isSupportedMarkdownURL(_ url: URL) -> Bool {
        ["md", "markdown"].contains(url.pathExtension.lowercased())
    }

    private func save(_ files: [RecentFile]) {
        defaults.set(files.map { $0.url.path }, forKey: key)
    }
}
