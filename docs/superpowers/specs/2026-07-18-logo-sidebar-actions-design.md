# Logo and Recent Actions Design

## Goal

Update mdPreview to use the newly provided logo and move the primary document actions into the Recent sidebar header.

## Decisions

- Replace `Resources/AppIcon.png` with the new logo asset.
- Treat the checkerboard background in the provided PNG as an exported transparency preview and convert it to alpha before saving the app icon source.
- Add `Open`, `Edit`, and `Save` buttons immediately after the `Recent` title in the left sidebar.
- Remove the duplicate titlebar action buttons so the app has one clear action location.
- Keep menu shortcuts working for Open, Save, and Toggle Editor.

## Behavior

- `Open` always opens the Markdown file picker.
- `Edit` is disabled until a document is open and changes its title to `Hide Editor` while the editor is visible.
- `Save` is disabled unless the current document has unsaved changes.
- Existing recent-file selection, dragging, removing, and preview behavior remain unchanged.

## Verification

- Add unit coverage for sidebar action state.
- Run the full Swift test suite.
- Rebuild `mdPreview.app`.
- Check `Info.plist` and generated icon resources.
