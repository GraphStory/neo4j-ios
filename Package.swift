import PackageDescription

let package = Package(
    name: "Theo",
    dependencies: [
		.Package(url: "https://github.com/niklassaers/bolt-swift.git", majorVersion: 0),
		.Package(url: "https://github.com/antitypical/Result.git", majorVersion: 3)
	],
    exclude: ["Source/Theo/TheoTests"]
)
