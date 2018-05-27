// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Theo",
    products: [
        .library(name: "Theo", targets: ["Theo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Neo4j-Swift/Bolt-swift.git", from: "1.0.2"),
        .package(url: "https://github.com/antitypical/Result.git", from: "3.2.4"),
        .package(url: "https://github.com/iamjono/LoremSwiftum.git", from: "0.0.3"),
    ],
    targets: [
        .target(
            name: "Theo",
            dependencies: ["Bolt", "Result"]),
        .testTarget(
            name: "TheoTests",
            dependencies: ["Theo", "LoremSwiftum"]),
    ]
)
