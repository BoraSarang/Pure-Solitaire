// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PureSolitaire",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "GameCore",
            path: "Sources/GameCore"
        ),
        .executableTarget(
            name: "PureSolitaire",
            dependencies: ["GameCore"],
            path: "Sources/PureSolitaire"
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            path: "Tests/GameCoreTests"
        )
    ]
)
