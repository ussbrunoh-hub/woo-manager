// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WooManager",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WooManager",
            path: "Sources/WooManager"
        )
    ]
)
