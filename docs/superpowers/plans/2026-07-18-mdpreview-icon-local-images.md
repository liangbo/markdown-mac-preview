# mdPreview Icon and Local Images Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the supplied image as the mdPreview app icon and make Markdown relative images load from the opened file's directory.

**Architecture:** Store the source PNG in project resources, generate a macOS `.icns` during app bundling, and declare it in `Info.plist`. Replace direct `loadHTMLString` preview loading with a small preview HTML file loaded through `WKWebView.loadFileURL(_:allowingReadAccessTo:)`; existing local relative image files are embedded into that HTML as data URLs so the WebView only needs access to the temporary preview file.

**Tech Stack:** Swift 5.9, SwiftUI, WebKit, Swift Package Manager, macOS `sips` and `iconutil`.

## Global Constraints

- Native macOS app remains named `mdPreview`.
- The icon source is `/Users/liangbo/Downloads/已生成图像 1.png`.
- Markdown images such as `![image](a.png)`, `![image](./a.png)`, and `![image](images/a.png)` resolve relative to the opened Markdown file.
- WebView JavaScript remains disabled.
- Existing recent-files, editing, live preview, save, and HTML preview behavior must keep working.

---

### Task 1: App Icon Asset and Bundle Metadata

**Files:**
- Create: `Resources/AppIcon.png`
- Modify: `scripts/build-app.sh`
- Test: `scripts/build-app.sh`, `plutil -lint build/mdPreview.app/Contents/Info.plist`, file checks under `build/mdPreview.app/Contents/Resources`

**Interfaces:**
- Consumes: Source PNG at `/Users/liangbo/Downloads/已生成图像 1.png`
- Produces: `build/mdPreview.app/Contents/Resources/AppIcon.icns` and `CFBundleIconFile` set to `AppIcon`

- [x] Copy the source PNG into `Resources/AppIcon.png`.
- [x] Update `scripts/build-app.sh` to generate an iconset using `sips`, convert it to `AppIcon.icns` using `iconutil`, and copy it to the app bundle resources directory.
- [x] Add `CFBundleIconFile` with value `AppIcon` to the generated `Info.plist`.
- [x] Run `scripts/build-app.sh` and verify `build/mdPreview.app/Contents/Resources/AppIcon.icns` exists.
- [x] Run `plutil -lint build/mdPreview.app/Contents/Info.plist` and expect `OK`.

### Task 2: Local Markdown Image Loading

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/PreviewView.swift`
- Test: `Tests/MarkdownMacPreviewAppTests/PreviewHTMLFileStoreTests.swift`

**Interfaces:**
- Consumes: `MarkdownPreviewContent.html`, optional Markdown file parent directory `URL`
- Produces: `PreviewHTMLFileStore.write(html:baseURL:) -> PreviewHTMLFileStore.LoadRequest`

- [x] Add a failing test that embeds an existing relative image from the Markdown directory into the temporary preview HTML.
- [x] Implement `PreviewHTMLFileStore` as a small file-writing helper.
- [x] Update `HTMLPreviewWebView` to call `loadFileURL(_:allowingReadAccessTo:)`.
- [x] Ensure the coordinator skips reloads when HTML and base directory did not change.
- [x] Run the new test and then the full `swift test`.

### Task 3: Final Verification and Merge

**Files:**
- Verify all changed files.

- [x] Run full `swift test`.
- [x] Run `scripts/build-app.sh`.
- [x] Run `plutil -lint build/mdPreview.app/Contents/Info.plist`.
- [ ] Confirm Git status contains only intended tracked changes plus any pre-existing `.DS_Store` files in the main repo.
- [ ] Commit and merge back to `main`.
