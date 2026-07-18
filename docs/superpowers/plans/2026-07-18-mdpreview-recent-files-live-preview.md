# mdPreview Recent Files and Live Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a left-side recent-files explorer, rename the generated app to `mdPreview`, and verify edit mode updates the preview from unsaved in-memory Markdown.

**Architecture:** Keep the existing AppKit lifecycle and SwiftUI view structure. Add a small testable recent-files model/store in the app target, then let `AppViewModel` own recent-file state and expose selection actions to a new SwiftUI sidebar. Keep the Swift executable product name stable internally while changing the generated app bundle and visible app name to `mdPreview`.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, Swift Package Manager, XCTest, macOS 13+, `UserDefaults` for local persistence.

## Global Constraints

- User-facing app name must be `mdPreview`.
- Generated app bundle must be `build/mdPreview.app`.
- Recent list must show opened Markdown files in newest-first order.
- Recent list must deduplicate files and keep at most 20 entries.
- Recent list must persist locally using `UserDefaults`.
- Opening from recent files must preserve the existing Save / Discard / Cancel guard for unsaved edits.
- Editing must update preview before save, using current in-memory document content.
- Do not add full folder browsing, recursive project tree, search, tagging, or cloud sync.
- Preserve generated `.DS_Store` files unless explicitly asked to clean them.

---

## File Structure

- Create `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFile.swift`
  - Defines `RecentFile` and `RecentFilesStore`.
  - Keeps recent-file ordering, deduplication, cap, extension filtering, persistence, and stale-file removal testable without SwiftUI.
- Create `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift`
  - Renders the left sidebar and calls closures for open and clear-stale behaviors.
- Modify `markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift`
  - Owns `recentFiles`, updates the store when files are opened, opens a selected recent file with unsaved-change confirmation, removes missing entries.
- Modify `markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`
  - Adds the sidebar beside the document area and keeps preview/editor split behavior.
- Modify `markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`
  - Changes visible window and menu app name to `mdPreview`.
- Modify `markdown-mac-preview/Sources/MarkdownMacPreviewApp/StatusBarView.swift`
  - No required behavior change; adjust only if sidebar layout needs status text to stay readable.
- Modify `markdown-mac-preview/scripts/build-app.sh`
  - Outputs `build/mdPreview.app` and sets `CFBundleName` / `CFBundleDisplayName` to `mdPreview`.
- Modify `markdown-mac-preview/README.md`
  - Updates app name, run/build/open instructions, and describes recent files/live preview.
- Create `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/RecentFilesStoreTests.swift`
  - Tests recent-file ordering, dedupe, cap, unsupported extension filtering, persistence, and stale removal.
- Create `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`
  - Tests live-preview behavior through `AppViewModel.updateContent(_:)` and recent-file update behavior where no AppKit modal is required.
- Modify `markdown-mac-preview/Package.swift`
  - Adds a `MarkdownMacPreviewAppTests` test target that depends on `MarkdownMacPreviewApp` and `MarkdownMacPreviewCore`.

---

### Task 1: Recent Files Store

**Files:**
- Create: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFile.swift`
- Create: `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/RecentFilesStoreTests.swift`
- Modify: `markdown-mac-preview/Package.swift`

**Interfaces:**
- Produces: `struct RecentFile: Identifiable, Equatable`
- Produces: `final class RecentFilesStore`
- Produces: `RecentFilesStore(defaults:key:limit:)`
- Produces: `func load() -> [RecentFile]`
- Produces: `func record(_ url: URL) -> [RecentFile]`
- Produces: `func remove(_ url: URL) -> [RecentFile]`
- Produces: `static func isSupportedMarkdownURL(_ url: URL) -> Bool`

- [ ] **Step 1: Write failing tests for ordering and deduplication**

Create `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/RecentFilesStoreTests.swift` with:

```swift
import XCTest
@testable import MarkdownMacPreviewApp

final class RecentFilesStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: RecentFilesStore!

    override func setUp() {
        super.setUp()
        suiteName = "RecentFilesStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 20)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testRecordAddsNewestFirstAndDeduplicates() {
        let first = URL(fileURLWithPath: "/tmp/first.md")
        let second = URL(fileURLWithPath: "/tmp/second.markdown")

        _ = store.record(first)
        _ = store.record(second)
        let files = store.record(first)

        XCTAssertEqual(files.map(\.url), [first.standardizedFileURL, second.standardizedFileURL])
    }
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
swift test --filter RecentFilesStoreTests/testRecordAddsNewestFirstAndDeduplicates
```

Expected: FAIL because `MarkdownMacPreviewApp` test target or `RecentFilesStore` does not exist.

- [ ] **Step 3: Add the app test target**

Modify `markdown-mac-preview/Package.swift` by adding this test target after the existing core test target:

```swift
.testTarget(
    name: "MarkdownMacPreviewAppTests",
    dependencies: ["MarkdownMacPreviewApp", "MarkdownMacPreviewCore"]
)
```

- [ ] **Step 4: Implement minimal recent file model/store**

Create `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFile.swift`:

```swift
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
    func record(_ url: URL) -> [RecentFile] {
        guard Self.isSupportedMarkdownURL(url) else {
            return load()
        }

        let standardizedURL = url.standardizedFileURL
        var files = load().filter { $0.url != standardizedURL }
        files.insert(RecentFile(url: standardizedURL), at: 0)
        files = Array(files.prefix(limit))
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
```

- [ ] **Step 6: Run the focused test and verify it passes**

Run:

```bash
swift test --filter RecentFilesStoreTests/testRecordAddsNewestFirstAndDeduplicates
```

Expected: PASS.

- [ ] **Step 7: Add failing tests for cap, unsupported files, persistence, and remove**

Append to `RecentFilesStoreTests`:

```swift
func testRecordCapsRecentFilesAtLimit() {
    store = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 3)

    for index in 0..<5 {
        _ = store.record(URL(fileURLWithPath: "/tmp/file-\(index).md"))
    }

    XCTAssertEqual(store.load().map(\.fileName), ["file-4.md", "file-3.md", "file-2.md"])
}

func testRecordIgnoresUnsupportedExtensions() {
    let files = store.record(URL(fileURLWithPath: "/tmp/not-markdown.txt"))

    XCTAssertTrue(files.isEmpty)
    XCTAssertTrue(store.load().isEmpty)
}

func testLoadRestoresPersistedFiles() {
    _ = store.record(URL(fileURLWithPath: "/tmp/saved.md"))
    let reloadedStore = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 20)

    XCTAssertEqual(reloadedStore.load().map(\.fileName), ["saved.md"])
}

func testRemoveDeletesPersistedEntry() {
    let stale = URL(fileURLWithPath: "/tmp/stale.md")
    _ = store.record(stale)

    let files = store.remove(stale)

    XCTAssertTrue(files.isEmpty)
    XCTAssertTrue(store.load().isEmpty)
}
```

- [ ] **Step 8: Run the new tests and verify they pass**

Run:

```bash
swift test --filter RecentFilesStoreTests
```

Expected: PASS.

- [ ] **Step 9: Commit Task 1**

```bash
git add markdown-mac-preview/Package.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFile.swift markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/RecentFilesStoreTests.swift
git commit -m "Add recent files store"
```

---

### Task 2: Recent Files App State and Live Preview Test

**Files:**
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Create: `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`

**Interfaces:**
- Consumes: `RecentFilesStore.load()`, `record(_:)`, `remove(_:)`
- Produces: `@Published private(set) var recentFiles: [RecentFile]`
- Produces: `func openRecentFile(_ recentFile: RecentFile)`
- Produces: `func removeRecentFile(_ recentFile: RecentFile)`
- Produces: `init(recentFilesStore: RecentFilesStore = RecentFilesStore())`

- [ ] **Step 1: Write failing tests for view model live preview and recent recording**

Create `markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`:

```swift
import XCTest
@testable import MarkdownMacPreviewApp

@MainActor
final class AppViewModelTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: RecentFilesStore!

    override func setUp() {
        super.setUp()
        suiteName = "AppViewModelTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = RecentFilesStore(defaults: defaults, key: "recent-files-test", limit: 20)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        suiteName = nil
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testLoadDocumentRecordsRecentFile() throws {
        let url = try makeMarkdownFile(named: "note.md", content: "# Note")
        let viewModel = AppViewModel(recentFilesStore: store)

        viewModel.loadDocument(from: url)

        XCTAssertEqual(viewModel.recentFiles.map(\.url), [url.standardizedFileURL])
    }

    func testPreviewUsesUnsavedEditedContent() throws {
        let url = try makeMarkdownFile(named: "draft.md", content: "# Old")
        let viewModel = AppViewModel(recentFilesStore: store)
        viewModel.loadDocument(from: url)

        viewModel.updateContent("# New\n\nLive preview text")

        XCTAssertTrue(viewModel.previewContent.attributedString.characters.contains("New"))
        XCTAssertTrue(viewModel.previewContent.attributedString.characters.contains("Live preview text"))
        XCTAssertTrue(viewModel.document?.isDirty == true)
    }

    private func makeMarkdownFile(named name: String, content: String) throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AppViewModelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
swift test --filter AppViewModelTests
```

Expected: FAIL because `AppViewModel` does not accept a store and does not expose `recentFiles` yet.

- [ ] **Step 3: Add recent-file dependency injection and state**

Modify the top of `AppViewModel`:

```swift
@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var document: MarkdownDocument?
    @Published private(set) var recentFiles: [RecentFile]
    @Published var isEditorVisible = false
    @Published var errorMessage: String?

    private let recentFilesStore: RecentFilesStore

    init(recentFilesStore: RecentFilesStore = RecentFilesStore()) {
        self.recentFilesStore = recentFilesStore
        self.recentFiles = recentFilesStore.load()
    }
```

- [ ] **Step 4: Record recent files after successful load**

Modify `loadDocument(from:)` so success records the URL:

```swift
func loadDocument(from url: URL) {
    do {
        document = try MarkdownDocument.load(from: url)
        recentFiles = recentFilesStore.record(url)
        isEditorVisible = false
        errorMessage = nil
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

- [ ] **Step 5: Add recent open and remove methods**

Add to `AppViewModel`:

```swift
func openRecentFile(_ recentFile: RecentFile) {
    guard FileManager.default.fileExists(atPath: recentFile.url.path) else {
        recentFiles = recentFilesStore.remove(recentFile.url)
        errorMessage = "Recent file no longer exists: \(recentFile.fileName)"
        return
    }

    guard confirmDiscardIfNeeded() else {
        return
    }

    loadDocument(from: recentFile.url)
}

func removeRecentFile(_ recentFile: RecentFile) {
    recentFiles = recentFilesStore.remove(recentFile.url)
}
```

- [ ] **Step 6: Run focused tests and verify they pass**

Run:

```bash
swift test --filter AppViewModelTests
```

Expected: PASS.

- [ ] **Step 7: Commit Task 2**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift markdown-mac-preview/Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift
git commit -m "Connect recent files to app state"
```

---

### Task 3: Recent Files Sidebar UI

**Files:**
- Create: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift`
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`

**Interfaces:**
- Consumes: `AppViewModel.recentFiles`
- Consumes: `AppViewModel.openRecentFile(_:)`
- Consumes: `AppViewModel.removeRecentFile(_:)`

- [ ] **Step 1: Create the sidebar view**

Create `markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift`:

```swift
import SwiftUI

struct RecentFilesSidebarView: View {
    let recentFiles: [RecentFile]
    let selectedURL: URL?
    let open: (RecentFile) -> Void
    let remove: (RecentFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if recentFiles.isEmpty {
                Text("No recent files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            } else {
                List(recentFiles) { file in
                    Button {
                        open(file)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.fileName)
                                .font(.body)
                                .lineLimit(1)
                            Text(file.parentPath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Remove from Recent") {
                            remove(file)
                        }
                    }
                    .listRowBackground(rowBackground(for: file))
                }
                .listStyle(.sidebar)
            }

            Spacer(minLength: 0)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 300)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func rowBackground(for file: RecentFile) -> Color {
        guard selectedURL?.standardizedFileURL == file.url.standardizedFileURL else {
            return Color.clear
        }
        return Color(nsColor: .selectedContentBackgroundColor).opacity(0.25)
    }
}
```

- [ ] **Step 2: Wire sidebar into ContentView**

Replace the middle area of `ContentView.body` between the first and second dividers with an `HStack`:

```swift
HStack(spacing: 0) {
    RecentFilesSidebarView(
        recentFiles: viewModel.recentFiles,
        selectedURL: viewModel.document?.url,
        open: viewModel.openRecentFile,
        remove: viewModel.removeRecentFile
    )

    Divider()

    if viewModel.hasDocument {
        documentBody
    } else {
        emptyState
    }
}
```

The outer `VStack`, toolbar, and status bar stay in place.

- [ ] **Step 3: Build to verify SwiftUI compiles**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 4: Run all tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 5: Commit Task 3**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift
git commit -m "Add recent files sidebar"
```

---

### Task 4: Rename Visible App and Bundle to mdPreview

**Files:**
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`
- Modify: `markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`
- Modify: `markdown-mac-preview/scripts/build-app.sh`
- Modify: `markdown-mac-preview/README.md`

**Interfaces:**
- Produces: generated bundle path `markdown-mac-preview/build/mdPreview.app`
- Keeps: SwiftPM executable product `MarkdownMacPreview`

- [ ] **Step 1: Update visible strings in Swift files**

In `MarkdownMacPreviewApp.swift`, change:

```swift
window.title = "Markdown Mac Preview"
```

to:

```swift
window.title = "mdPreview"
```

Change:

```swift
withTitle: "Quit Markdown Mac Preview"
```

to:

```swift
withTitle: "Quit mdPreview"
```

In `ContentView.swift`, change empty state title:

```swift
Text("Markdown Mac Preview")
```

to:

```swift
Text("mdPreview")
```

- [ ] **Step 2: Update the app bundle script**

In `scripts/build-app.sh`, change:

```bash
APP_NAME="Markdown Mac Preview"
```

to:

```bash
APP_NAME="mdPreview"
```

Change `CFBundleName` and `CFBundleDisplayName` strings to `mdPreview`:

```xml
<key>CFBundleName</key>
<string>mdPreview</string>
<key>CFBundleDisplayName</key>
<string>mdPreview</string>
```

Keep `CFBundleExecutable` as `MarkdownMacPreview` because the internal Swift product name remains unchanged.

- [ ] **Step 3: Update README**

Replace README title and commands with:

```markdown
# mdPreview

A native macOS Markdown preview app focused on local `.md` and `.markdown` files.

The app opens local Markdown files, keeps recently opened files in a left sidebar, renders a readable preview by default, and lets you toggle a plain-text editor with live preview when you need to make small changes.
```

Update the build section command to:

```bash
scripts/build-app.sh
open "build/mdPreview.app"
```

- [ ] **Step 4: Build the app bundle and verify the new path**

Run:

```bash
scripts/build-app.sh
test -d "build/mdPreview.app"
plutil -lint "build/mdPreview.app/Contents/Info.plist"
```

Expected: bundle exists and plist lint prints `OK`.

- [ ] **Step 5: Commit Task 4**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift markdown-mac-preview/scripts/build-app.sh markdown-mac-preview/README.md
git commit -m "Rename app bundle to mdPreview"
```

---

### Task 5: Final Verification and Launch Check

**Files:**
- Modify only if verification exposes a defect.

**Interfaces:**
- Verifies all earlier interfaces.

- [ ] **Step 1: Run all tests**

Run:

```bash
swift test --disable-sandbox --scratch-path /private/tmp/mdpreview-build --cache-path /private/tmp/mdpreview-swiftpm-cache --config-path /private/tmp/mdpreview-swiftpm-config --security-path /private/tmp/mdpreview-swiftpm-security
```

Expected: all tests pass with 0 failures.

- [ ] **Step 2: Run build**

Run:

```bash
swift build --disable-sandbox --scratch-path /private/tmp/mdpreview-build --cache-path /private/tmp/mdpreview-swiftpm-cache --config-path /private/tmp/mdpreview-swiftpm-config --security-path /private/tmp/mdpreview-swiftpm-security
```

Expected: build completes successfully.

- [ ] **Step 3: Build app bundle**

Run:

```bash
scripts/build-app.sh
```

Expected: `Created .../build/mdPreview.app`.

- [ ] **Step 4: Lint generated plist**

Run:

```bash
plutil -lint "build/mdPreview.app/Contents/Info.plist"
```

Expected: `build/mdPreview.app/Contents/Info.plist: OK`.

- [ ] **Step 5: Launch generated app**

Run:

```bash
open -n "build/mdPreview.app"
pgrep -fl MarkdownMacPreview
```

Expected: `open` exits 0 and `pgrep` shows a process under `/Users/liangbo/aiskills/markdown-mac-preview/build/mdPreview.app/Contents/MacOS/MarkdownMacPreview`.

- [ ] **Step 6: Confirm git status**

Run:

```bash
git status --short
```

Expected: only pre-existing `.DS_Store` untracked files remain, or no output if they were already cleaned outside this task.

- [ ] **Step 7: Commit only if verification required fixes**

If Task 5 required code changes:

```bash
git add <changed-files>
git commit -m "Verify mdPreview recent files workflow"
```

If no changes were needed, do not create an empty commit.

---

## Self-Review

- Spec coverage: Task 1 covers persistence, dedupe, ordering, limit, and extension filtering. Task 2 covers AppViewModel state, missing-file handling, unsaved guard integration, and live preview through in-memory content. Task 3 covers left sidebar UI. Task 4 covers visible app and bundle renaming. Task 5 covers tests, build, bundle, plist, and launch verification.
- Placeholder scan: no unresolved placeholders or incomplete implementation notes are present.
- Type consistency: `RecentFile`, `RecentFilesStore`, `recentFiles`, `openRecentFile(_:)`, and `removeRecentFile(_:)` are named consistently across tasks.
