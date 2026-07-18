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
        ),
        .testTarget(
            name: "MarkdownMacPreviewAppTests",
            dependencies: ["MarkdownMacPreviewApp", "MarkdownMacPreviewCore"]
        )
    ]
)
