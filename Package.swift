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
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Ink.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "MarkdownMacPreviewCore",
            dependencies: [
                .product(name: "Ink", package: "Ink")
            ]
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
