// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sweph",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "sweph", type: .dynamic, targets: ["sweph"])
    ],
    targets: [
        .target(
            name: "sweph",
            path: "Sources/sweph"
        )
    ]
)
