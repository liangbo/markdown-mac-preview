# Logo and Recent Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app icon and expose Open/Edit/Save actions in the Recent sidebar header.

**Architecture:** `RecentFilesSidebarView` owns the sidebar header layout and receives action closures plus enabled/title state from `ContentView`. `AppViewModel` exposes a small `SidebarActionState` value for testable button state. The app delegate keeps menu shortcuts but no longer creates titlebar action buttons.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, XCTest, macOS app bundle scripts.

## Global Constraints

- Keep the app name `mdPreview`.
- Keep existing menu shortcuts for Open, Save, and Toggle Editor.
- Keep recent file selection, drag ordering, and remove behavior unchanged.
- Convert the provided checkerboard logo background to transparency before app icon generation.

---

### Task 1: Sidebar Action State

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/AppViewModel.swift`
- Test: `Tests/MarkdownMacPreviewAppTests/AppViewModelTests.swift`

**Interfaces:**
- Produces: `AppViewModel.sidebarActionState: SidebarActionState`
- Produces: `SidebarActionState(canEdit: Bool, canSave: Bool, editTitle: String)`

- [x] Add a failing test that sidebar actions are disabled before opening a document.
- [x] Add a failing test that Edit is enabled after opening a document and Save follows dirty state.
- [x] Implement `SidebarActionState`.
- [x] Run `swift test --filter AppViewModelTests`.

### Task 2: Recent Header Buttons

**Files:**
- Modify: `Sources/MarkdownMacPreviewApp/RecentFilesSidebarView.swift`
- Modify: `Sources/MarkdownMacPreviewApp/ContentView.swift`
- Modify: `Sources/MarkdownMacPreviewApp/MarkdownMacPreviewApp.swift`

**Interfaces:**
- Consumes: `SidebarActionState`
- Consumes: `openDocument`, `saveDocument`, and `toggleEditor` closures.

- [x] Add Open/Edit/Save buttons after the `Recent` title.
- [x] Disable Edit and Save based on `SidebarActionState`.
- [x] Remove the titlebar action accessory and button state plumbing.
- [x] Run the full Swift test suite.

### Task 3: Logo Replacement and Bundle Verification

**Files:**
- Modify: `Resources/AppIcon.png`

**Interfaces:**
- Consumes: `/var/folders/p2/g0k9gqf10lsbfxxm045vd_900000gn/T/codex-clipboard-0424f6cc-0c02-424c-9377-b1ea09489361.png`
- Produces: transparent app icon source at `Resources/AppIcon.png`.

- [x] Convert checkerboard pixels to alpha and replace `Resources/AppIcon.png`.
- [x] Run `scripts/build-app.sh`.
- [x] Run `plutil -lint build/mdPreview.app/Contents/Info.plist`.
- [x] Verify `build/mdPreview.app/Contents/Resources/AppIcon.icns` can be parsed by `iconutil`.
- [x] Commit, merge back to `main`, and remove the worktree.
