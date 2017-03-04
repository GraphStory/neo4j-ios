import PackageDescription

let package = Package(
    name: "Theo",
    dependencies: [
		.Package(url: "https://github.com/niklassaers/bolt-swift.git", majorVersion: 0),
	],
    exclude: ["Source/Theo/TheoTests"]
)
