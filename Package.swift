import PackageDescription

let package = Package(
    name: "Theo",
    dependencies: [
		.Package(url: "https://github.com/Neo4j-Swift/Bolt-swift.git", majorVersion: 1),
		.Package(url: "https://github.com/antitypical/Result.git", majorVersion: 3)
	],
    exclude: ["Source/Theo/TheoTests"]
)
