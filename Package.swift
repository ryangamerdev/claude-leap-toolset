// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "leap",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "leap", targets: ["leap"]),
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
                .linkedLibrary("sqlite3"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        ),
        .executableTarget(
            name: "leap",
            dependencies: [
                "LeapCore",
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/leap"
        ),
        .testTarget(
            name: "LeapCoreTests",
            dependencies: ["LeapCore"],
            path: "Tests/LeapCoreTests"
        ),
    ]
)
