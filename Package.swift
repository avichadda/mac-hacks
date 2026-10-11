// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacHacks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacHacks", targets: ["MacHacks"])
    ],
    targets: [
        .executableTarget(
            name: "MacHacks",
            path: "Sources/MacHacks"
        )
    ]
)
