// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "claude-leap",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "claude-leap", targets: ["claude-leap"]),
        .library(name: "LeapCore", targets: ["LeapCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "LeapCore",
            path: "Sources/LeapCore",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        ),
        .executableTarget(
            name: "claude-leap",
            dependencies: [
                "LeapCore",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/claude-leap"
        ),
        .testTarget(
            name: "LeapCoreTests",
            dependencies: ["LeapCore"],
            path: "Tests/LeapCoreTests"
        ),
    ]
)
