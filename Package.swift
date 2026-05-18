// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SteamControllerKit",
    platforms: [
        .iOS("26.0"),
        .tvOS("26.0"),
    ],
    products: [
        .library(name: "SteamControllerKit", targets: ["SteamControllerKit"]),
    ],
    targets: [
        .target(name: "SteamControllerKit"),
        .testTarget(
            name: "SteamControllerKitTests",
            dependencies: ["SteamControllerKit"]
        ),
    ]
)
