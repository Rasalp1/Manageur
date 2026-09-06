// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Manageur",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Manageur",
            targets: ["Manageur"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Manageur",
            dependencies: [],
            path: "Sources/Manageur"
        ),
        .testTarget(
            name: "ManageurTests",
            dependencies: ["Manageur"],
            path: "Tests/ManageurTests"
        )
    ]
)
