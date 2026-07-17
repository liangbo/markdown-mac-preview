# Markdown Mac Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI app that opens local Markdown files, previews them by default, allows light editing, saves changes, and packages into a double-clickable `.app` bundle.

**Architecture:** Use a Swift Package with two targets: `MarkdownMacPreviewCore` for file validation, document state, stats, and rendering, and `MarkdownMacPreviewApp` for SwiftUI views, app commands, and macOS file panels. Keep document behavior testable without launching the UI, then wire it into a small native shell.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit file panels, Foundation, XCTest, Swift Package Manager, shell packaging script.

## Global Constraints

- Project path: `/Users/liangbo/aiskills/markdown-mac-preview`.
- The app must be a real local Mac app, not a browser-hosted site.
- The first version prioritizes preview; editing is available but not the default visual focus.
- Supported file extensions are `.md` and `.markdown`.
- Markdown rendering starts with Apple platform APIs using `AttributedString(markdown:)`.
- The app must produce a local `.app` bundle for double-click launching.
- Do not add cloud sync, multi-file workspace management, plugins, WYSIWYG editing, cross-platform builds, or GitHub-perfect rendering in this version.
- Store design and implementation plan under `markdown-mac-preview/docs`.

---

## File Structure

- `Package.swift`: Swift package definition with a core library, app executable, and core tests.
- `README.md`: Local build, test, run, and packaging instructions.
- `scripts/build-app.sh`: Builds the release executable and creates `build/Markdown Mac Preview.app`.
- `Sources/MarkdownMacPreviewCore/MarkdownStats.swift`: Computes word, character, and heading counts.
- `Sources/MarkdownMacPreviewCore/MarkdownDocument.swift`: Owns loaded file URL, editable text, original text, dirty state, file validation, load, edit, and save behavior.
- `Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift`: Converts Markdown text into an `AttributedString` preview result.
- `Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`: SwiftUI macOS entry point.
- `Sources/MarkdownMacPreviewApp/AppCommands.swift`: Native commands and keyboard shortcuts for open, save, and editor toggle.
- `Sources/MarkdownMacPreviewApp/AppViewModel.swift`: Bridges UI commands to the document model and renderer.
- `Sources/MarkdownMacPreviewApp/ContentView.swift`: Main window state layout.
- `Sources/MarkdownMacPreviewApp/PreviewView.swift`: Readable Markdown preview surface.
- `Sources/MarkdownMacPreviewApp/EditorView.swift`: Plain Markdown editor surface.
- `Sources/MarkdownMacPreviewApp/StatusBarView.swift`: File name, dirty state, stats, and errors.
- `Tests/MarkdownMacPreviewCoreTests/MarkdownStatsTests.swift`: Stats unit tests.
- `Tests/MarkdownMacPreviewCoreTests/MarkdownDocumentTests.swift`: File validation, load, edit, save tests.
- `Tests/MarkdownMacPreviewCoreTests/MarkdownRendererTests.swift`: Markdown rendering tests.

---

### Task 1: Project Scaffold And Packaging Path

**Files:**
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Package.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/README.md`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/scripts/build-app.sh`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownStats.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`

**Interfaces:**
- Consumes: none.
- Produces: package targets `MarkdownMacPreviewCore` and `MarkdownMacPreviewApp`; executable product `MarkdownMacPreview`; script `scripts/build-app.sh`.

- [ ] **Step 1: Create package manifest**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownMacPreview",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MarkdownMacPreviewCore",
            targets: ["MarkdownMacPreviewCore"]
        ),
        .executable(
            name: "MarkdownMacPreview",
            targets: ["MarkdownMacPreviewApp"]
        )
    ],
    targets: [
        .target(
            name: "MarkdownMacPreviewCore"
        ),
        .executableTarget(
            name: "MarkdownMacPreviewApp",
            dependencies: ["MarkdownMacPreviewCore"]
        ),
        .testTarget(
            name: "MarkdownMacPreviewCoreTests",
            dependencies: ["MarkdownMacPreviewCore"]
        )
    ]
)
```

- [ ] **Step 2: Add minimal core placeholder**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownStats.swift`:

```swift
import Foundation

public struct MarkdownStats: Equatable {
    public let characters: Int
    public let words: Int
    public let headings: Int

    public init(characters: Int = 0, words: Int = 0, headings: Int = 0) {
        self.characters = characters
        self.words = words
        self.headings = headings
    }
}
```

- [ ] **Step 3: Add minimal app entry point**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`:

```swift
import SwiftUI

@main
struct MarkdownMacPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
    }
}
```

- [ ] **Step 4: Add minimal launch view**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Markdown Mac Preview")
                .font(.title)
            Text("Open a Markdown file to preview it locally.")
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
```

- [ ] **Step 5: Add packaging script**

Write `/Users/liangbo/aiskills/markdown-mac-preview/scripts/build-app.sh` and make it executable:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Markdown Mac Preview"
BUNDLE_DIR="$ROOT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c release --product MarkdownMacPreview

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/release/MarkdownMacPreview" "$MACOS_DIR/MarkdownMacPreview"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MarkdownMacPreview</string>
  <key>CFBundleIdentifier</key>
  <string>com.liangbo.markdown-mac-preview</string>
  <key>CFBundleName</key>
  <string>Markdown Mac Preview</string>
  <key>CFBundleDisplayName</key>
  <string>Markdown Mac Preview</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Created $BUNDLE_DIR"
```

Run: `chmod +x scripts/build-app.sh`

- [ ] **Step 6: Add README**

Write `/Users/liangbo/aiskills/markdown-mac-preview/README.md`:

````markdown
# Markdown Mac Preview

A native macOS Markdown preview app focused on local `.md` and `.markdown` files.

## Run

```bash
swift run MarkdownMacPreview
```

## Test

```bash
swift test
```

## Build A Local App Bundle

```bash
scripts/build-app.sh
open "build/Markdown Mac Preview.app"
```
````

- [ ] **Step 7: Verify scaffold**

Run: `swift build`

Expected: build succeeds and includes `Build complete!`.

- [ ] **Step 8: Verify app bundle script**

Run: `scripts/build-app.sh`

Expected: output includes `Created /Users/liangbo/aiskills/markdown-mac-preview/build/Markdown Mac Preview.app`.

- [ ] **Step 9: Commit**

```bash
git add markdown-mac-preview/Package.swift markdown-mac-preview/README.md markdown-mac-preview/scripts/build-app.sh markdown-mac-preview/Sources
git commit -m "Add markdown mac preview scaffold"
```

---

### Task 2: Markdown Stats Core

**Files:**
- Modify: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownStats.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownStatsTests.swift`

**Interfaces:**
- Consumes: `MarkdownStats` struct from Task 1.
- Produces: `public static func MarkdownStats.compute(for markdown: String) -> MarkdownStats`.

- [ ] **Step 1: Write failing stats tests**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownStatsTests.swift`:

```swift
import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownStatsTests: XCTestCase {
    func testComputesCharactersWordsAndHeadings() {
        let markdown = """
        # Title

        Hello **local** Markdown preview.

        ## Notes
        - one item
        - second item
        """

        let stats = MarkdownStats.compute(for: markdown)

        XCTAssertEqual(stats.characters, markdown.count)
        XCTAssertEqual(stats.words, 10)
        XCTAssertEqual(stats.headings, 2)
    }

    func testEmptyMarkdownHasZeroStats() {
        let stats = MarkdownStats.compute(for: "")

        XCTAssertEqual(stats.characters, 0)
        XCTAssertEqual(stats.words, 0)
        XCTAssertEqual(stats.headings, 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MarkdownStatsTests`

Expected: FAIL because `MarkdownStats.compute(for:)` is not defined.

- [ ] **Step 3: Implement stats**

Replace `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownStats.swift` with:

```swift
import Foundation

public struct MarkdownStats: Equatable {
    public let characters: Int
    public let words: Int
    public let headings: Int

    public init(characters: Int = 0, words: Int = 0, headings: Int = 0) {
        self.characters = characters
        self.words = words
        self.headings = headings
    }

    public static func compute(for markdown: String) -> MarkdownStats {
        let headingCount = markdown
            .split(whereSeparator: \.isNewline)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.range(of: #"^#{1,6}\s+\S"#, options: .regularExpression) != nil
            }
            .count

        let plainText = markdown
            .replacingOccurrences(of: #"```[\s\S]*?```"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"`[^`]+`"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"https?://\S+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[#>*_\-\[\]()`]"#, with: " ", options: .regularExpression)

        let words = plainText
            .split { character in
                character.isWhitespace || character.isNewline
            }
            .count

        return MarkdownStats(
            characters: markdown.count,
            words: words,
            headings: headingCount
        )
    }
}
```

- [ ] **Step 4: Run stats tests**

Run: `swift test --filter MarkdownStatsTests`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownStats.swift markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownStatsTests.swift
git commit -m "Add markdown stats core"
```

---

### Task 3: Markdown Document Model

**Files:**
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownDocument.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownDocumentTests.swift`

**Interfaces:**
- Consumes: `MarkdownStats.compute(for:)` from Task 2.
- Produces: `MarkdownDocument`, `MarkdownDocumentError`, `MarkdownDocument.load(from:)`, `updateContent(_:)`, `save()`.

- [ ] **Step 1: Write failing document tests**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownDocumentTests.swift`:

```swift
import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownDocumentTests: XCTestCase {
    func testLoadsSupportedMarkdownFile() throws {
        let url = try writeTempFile(name: "note.md", content: "# Hello\n\nLocal preview")

        let document = try MarkdownDocument.load(from: url)

        XCTAssertEqual(document.fileURL, url)
        XCTAssertEqual(document.fileName, "note.md")
        XCTAssertEqual(document.content, "# Hello\n\nLocal preview")
        XCTAssertFalse(document.isDirty)
        XCTAssertEqual(document.stats.headings, 1)
    }

    func testRejectsUnsupportedExtension() throws {
        let url = try writeTempFile(name: "note.txt", content: "# Hello")

        XCTAssertThrowsError(try MarkdownDocument.load(from: url)) { error in
            XCTAssertEqual(error as? MarkdownDocumentError, .unsupportedFileType("txt"))
        }
    }

    func testDirtyStateChangesAfterEditAndClearsAfterSave() throws {
        let url = try writeTempFile(name: "draft.markdown", content: "# Draft")
        var document = try MarkdownDocument.load(from: url)

        document.updateContent("# Draft\n\nUpdated body")

        XCTAssertTrue(document.isDirty)
        XCTAssertEqual(document.stats.words, 3)

        try document.save()

        XCTAssertFalse(document.isDirty)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Draft\n\nUpdated body")
    }

    private func writeTempFile(name: String, content: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MarkdownDocumentTests`

Expected: FAIL because `MarkdownDocument` is not defined.

- [ ] **Step 3: Implement document model**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownDocument.swift`:

```swift
import Foundation

public enum MarkdownDocumentError: Error, Equatable, LocalizedError {
    case unsupportedFileType(String)
    case unreadableFile(String)
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "Unsupported file type: .\(ext). Please open a .md or .markdown file."
        case .unreadableFile(let message):
            return "Could not read this Markdown file. \(message)"
        case .saveFailed(let message):
            return "Could not save this Markdown file. \(message)"
        }
    }
}

public struct MarkdownDocument: Equatable {
    public let fileURL: URL
    public private(set) var originalContent: String
    public private(set) var content: String

    public var fileName: String {
        fileURL.lastPathComponent
    }

    public var isDirty: Bool {
        content != originalContent
    }

    public var stats: MarkdownStats {
        MarkdownStats.compute(for: content)
    }

    public static func load(from url: URL) throws -> MarkdownDocument {
        try validateSupportedFile(url)

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return MarkdownDocument(fileURL: url, originalContent: text, content: text)
        } catch {
            throw MarkdownDocumentError.unreadableFile(error.localizedDescription)
        }
    }

    public mutating func updateContent(_ newContent: String) {
        content = newContent
    }

    public mutating func save() throws {
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            originalContent = content
        } catch {
            throw MarkdownDocumentError.saveFailed(error.localizedDescription)
        }
    }

    private static func validateSupportedFile(_ url: URL) throws {
        let ext = url.pathExtension.lowercased()
        guard ext == "md" || ext == "markdown" else {
            throw MarkdownDocumentError.unsupportedFileType(ext.isEmpty ? "none" : ext)
        }
    }
}
```

- [ ] **Step 4: Run document tests**

Run: `swift test --filter MarkdownDocumentTests`

Expected: PASS.

- [ ] **Step 5: Run full core tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownDocument.swift markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownDocumentTests.swift
git commit -m "Add markdown document model"
```

---

### Task 4: Markdown Renderer Core

**Files:**
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownRendererTests.swift`

**Interfaces:**
- Consumes: Foundation `AttributedString` Markdown initializer.
- Produces: `MarkdownPreviewContent`, `MarkdownRenderer.render(_:)`.

- [ ] **Step 1: Write failing renderer tests**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownRendererTests.swift`:

```swift
import XCTest
@testable import MarkdownMacPreviewCore

final class MarkdownRendererTests: XCTestCase {
    func testRendersBasicMarkdownIntoAttributedContent() {
        let result = MarkdownRenderer.render("# Title\n\nThis is **bold** text.")

        XCTAssertEqual(String(result.attributed.characters), "Title\n\nThis is bold text.")
        XCTAssertNil(result.warning)
    }

    func testPlainTextFallbackKeepsOriginalText() {
        let markdown = "Unclosed [link]("

        let result = MarkdownRenderer.render(markdown)

        XCTAssertEqual(String(result.attributed.characters), markdown)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MarkdownRendererTests`

Expected: FAIL because `MarkdownRenderer` is not defined.

- [ ] **Step 3: Implement renderer**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift`:

```swift
import Foundation

public struct MarkdownPreviewContent: Equatable {
    public let attributed: AttributedString
    public let warning: String?

    public init(attributed: AttributedString, warning: String? = nil) {
        self.attributed = attributed
        self.warning = warning
    }
}

public enum MarkdownRenderer {
    public static func render(_ markdown: String) -> MarkdownPreviewContent {
        do {
            let attributed = try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            )
            return MarkdownPreviewContent(attributed: attributed)
        } catch {
            return MarkdownPreviewContent(
                attributed: AttributedString(markdown),
                warning: "Markdown preview fell back to plain text."
            )
        }
    }
}
```

- [ ] **Step 4: Run renderer tests**

Run: `swift test --filter MarkdownRendererTests`

Expected: PASS.

- [ ] **Step 5: Run full tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewCore/MarkdownRenderer.swift markdown-mac-preview/Tests/MarkdownMacPreviewCoreTests/MarkdownRendererTests.swift
git commit -m "Add markdown renderer core"
```

---

### Task 5: App View Model And File Commands

**Files:**
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppCommands.swift`
- Modify: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`

**Interfaces:**
- Consumes: `MarkdownDocument.load(from:)`, `MarkdownDocument.updateContent(_:)`, `MarkdownDocument.save()`, `MarkdownRenderer.render(_:)`.
- Produces: `@MainActor final class AppViewModel`, command environment key `appViewModel`, app commands for `openDocument()`, `saveDocument()`, `toggleEditor()`.

- [ ] **Step 1: Implement app view model**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift`:

```swift
import AppKit
import Foundation
import MarkdownMacPreviewCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var document: MarkdownDocument?
    @Published var isEditorVisible = false
    @Published var errorMessage: String?

    var previewContent: MarkdownPreviewContent {
        MarkdownRenderer.render(document?.content ?? "")
    }

    var hasDocument: Bool {
        document != nil
    }

    var canSave: Bool {
        document?.isDirty == true
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        loadDocument(from: url)
    }

    func loadDocument(from url: URL) {
        do {
            document = try MarkdownDocument.load(from: url)
            isEditorVisible = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateContent(_ content: String) {
        document?.updateContent(content)
    }

    func saveDocument() {
        guard var currentDocument = document else {
            return
        }

        do {
            try currentDocument.save()
            document = currentDocument
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleEditor() {
        guard hasDocument else {
            return
        }
        isEditorVisible.toggle()
    }
}
```

- [ ] **Step 2: Implement app commands**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppCommands.swift`:

```swift
import SwiftUI

private struct AppViewModelKey: EnvironmentKey {
    static let defaultValue: AppViewModel? = nil
}

extension EnvironmentValues {
    var appViewModel: AppViewModel? {
        get { self[AppViewModelKey.self] }
        set { self[AppViewModelKey.self] = newValue }
    }
}

struct AppCommands: Commands {
    @Environment(\.appViewModel) private var viewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                viewModel?.openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Button("Save") {
                viewModel?.saveDocument()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(viewModel?.canSave != true)
        }

        CommandMenu("View") {
            Button("Toggle Editor") {
                viewModel?.toggleEditor()
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(viewModel?.hasDocument != true)
        }
    }
}
```

- [ ] **Step 3: Wire model into app**

Replace `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift` with:

```swift
import SwiftUI

@main
struct MarkdownMacPreviewApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            AppCommands()
        }
        .environment(\.appViewModel, viewModel)
    }
}
```

- [ ] **Step 4: Verify build**

Run: `swift build`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppViewModel.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/AppCommands.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift
git commit -m "Add app model and commands"
```

---

### Task 6: Preview-First SwiftUI Interface

**Files:**
- Modify: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/PreviewView.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/EditorView.swift`
- Create: `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/StatusBarView.swift`

**Interfaces:**
- Consumes: `AppViewModel`, `MarkdownPreviewContent`, `MarkdownDocument.stats`.
- Produces: preview-first UI with Open, Save, Toggle Editor controls and status information.

- [ ] **Step 1: Implement preview view**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/PreviewView.swift`:

```swift
import MarkdownMacPreviewCore
import SwiftUI

struct PreviewView: View {
    let content: MarkdownPreviewContent

    var body: some View {
        ScrollView {
            Text(content.attributed)
                .textSelection(.enabled)
                .font(.system(size: 16))
                .lineSpacing(5)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}
```

- [ ] **Step 2: Implement editor view**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/EditorView.swift`:

```swift
import SwiftUI

struct EditorView: View {
    @Binding var content: String

    var body: some View {
        TextEditor(text: $content)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
            .padding(.vertical, 8)
    }
}
```

- [ ] **Step 3: Implement status bar**

Write `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/StatusBarView.swift`:

```swift
import MarkdownMacPreviewCore
import SwiftUI

struct StatusBarView: View {
    let fileName: String?
    let isDirty: Bool
    let stats: MarkdownStats
    let errorMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(fileName ?? "No file open")
                .fontWeight(.medium)
                .lineLimit(1)

            if isDirty {
                Text("Unsaved")
                    .foregroundStyle(.orange)
            }

            Spacer()

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                Text("\(stats.words) words")
                Text("\(stats.characters) chars")
                Text("\(stats.headings) headings")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
```

- [ ] **Step 4: Implement main content view**

Replace `/Users/liangbo/aiskills/markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift` with:

```swift
import MarkdownMacPreviewCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private var editableContent: Binding<String> {
        Binding(
            get: { viewModel.document?.content ?? "" },
            set: { viewModel.updateContent($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            if viewModel.hasDocument {
                documentBody
            } else {
                emptyState
            }

            Divider()

            StatusBarView(
                fileName: viewModel.document?.fileName,
                isDirty: viewModel.document?.isDirty == true,
                stats: viewModel.document?.stats ?? MarkdownStats(),
                errorMessage: viewModel.errorMessage
            )
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button("Open") {
                viewModel.openDocument()
            }

            Button("Save") {
                viewModel.saveDocument()
            }
            .disabled(!viewModel.canSave)

            Button(viewModel.isEditorVisible ? "Hide Editor" : "Edit") {
                viewModel.toggleEditor()
            }
            .disabled(!viewModel.hasDocument)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var documentBody: some View {
        Group {
            if viewModel.isEditorVisible {
                HSplitView {
                    EditorView(content: editableContent)
                        .frame(minWidth: 320)
                    PreviewView(content: viewModel.previewContent)
                        .frame(minWidth: 420)
                }
            } else {
                PreviewView(content: viewModel.previewContent)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("Markdown Mac Preview")
                .font(.title)
            Text("Open a local Markdown file to preview it.")
                .foregroundStyle(.secondary)
            Button("Open Markdown File") {
                viewModel.openDocument()
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
```

- [ ] **Step 5: Verify build**

Run: `swift build`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add markdown-mac-preview/Sources/MarkdownMacPreviewApp/ContentView.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/PreviewView.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/EditorView.swift markdown-mac-preview/Sources/MarkdownMacPreviewApp/StatusBarView.swift
git commit -m "Add preview first interface"
```

---

### Task 7: Final Verification, Packaging, And Documentation

**Files:**
- Modify: `/Users/liangbo/aiskills/markdown-mac-preview/README.md`
- Modify: `/Users/liangbo/aiskills/markdown-mac-preview/scripts/build-app.sh` if packaging verification finds a concrete issue.

**Interfaces:**
- Consumes: all tasks above.
- Produces: verified local `.app` bundle and final usage documentation.

- [ ] **Step 1: Add a local sample file for manual verification outside Git**

Run:

```bash
mkdir -p /tmp/markdown-mac-preview-check
printf '# Local Check\n\nThis file is **rendered** and edited locally.\n' > /tmp/markdown-mac-preview-check/sample.md
```

Expected: `/tmp/markdown-mac-preview-check/sample.md` exists.

- [ ] **Step 2: Run all tests**

Run: `swift test`

Expected: PASS.

- [ ] **Step 3: Build release app bundle**

Run: `scripts/build-app.sh`

Expected: `build/Markdown Mac Preview.app` exists and the script prints its path.

- [ ] **Step 4: Launch the generated app bundle**

Run: `open "build/Markdown Mac Preview.app"`

Expected: app launches with an empty state and Open action.

- [ ] **Step 5: Manually verify open, preview, edit, save**

Use the app UI:

1. Open `/tmp/markdown-mac-preview-check/sample.md`.
2. Confirm the preview shows `Local Check` as a heading and bold text rendered as bold.
3. Toggle editor.
4. Add a new line: `Saved from Markdown Mac Preview.`
5. Confirm status shows `Unsaved`.
6. Save.
7. Confirm `Unsaved` disappears.

Then run:

```bash
cat /tmp/markdown-mac-preview-check/sample.md
```

Expected output includes `Saved from Markdown Mac Preview.`.

- [ ] **Step 6: Update README with verified workflow**

Replace `/Users/liangbo/aiskills/markdown-mac-preview/README.md` with:

````markdown
# Markdown Mac Preview

A native macOS Markdown preview app focused on local `.md` and `.markdown` files.

The app opens a local Markdown file, renders a readable preview by default, and lets you toggle a plain-text editor when you need to make small changes.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer

## Run From Source

```bash
swift run MarkdownMacPreview
```

## Test

```bash
swift test
```

## Build A Local App Bundle

```bash
scripts/build-app.sh
open "build/Markdown Mac Preview.app"
```

The generated app bundle is local and unsigned. macOS may ask for confirmation the first time it opens.

## Shortcuts

- `Command-O`: open a Markdown file
- `Command-S`: save current changes
- `Command-E`: show or hide the editor
````

- [ ] **Step 7: Run final status check**

Run: `git status --short`

Expected: only intended files under `markdown-mac-preview/` are modified or untracked. Ignore any pre-existing top-level `.DS_Store` if it appears.

- [ ] **Step 8: Commit final verification docs**

```bash
git add markdown-mac-preview/README.md markdown-mac-preview/scripts/build-app.sh
git commit -m "Document markdown mac preview workflow"
```
