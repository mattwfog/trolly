// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Trolly",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Trolly",
            path: "Trolly"
        ),
        .testTarget(
            name: "TrollyTests",
            dependencies: ["Trolly"],
            path: "TrollyTests"
        ),
    ]
)
