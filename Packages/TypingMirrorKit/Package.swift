// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TypingMirrorKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TypingMirrorKit", targets: ["TypingMirrorKit"])
    ],
    targets: [
        .target(
            name: "TypingMirrorKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TypingMirrorKitTests",
            dependencies: ["TypingMirrorKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
