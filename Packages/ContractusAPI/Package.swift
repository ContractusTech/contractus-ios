// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContractusAPI",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ContractusAPI",
            targets: ["ContractusAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
        .package(name: "TweetNacl", url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", from: "1.0.2"),
        .package(url: "https://github.com/keefertaylor/Base58Swift.git", from: "2.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ContractusAPI",
            dependencies: [
                "Alamofire",
                "TweetNacl",
                "Base58Swift"
            ]),
        .testTarget(
            name: "ContractusAPITests",
            dependencies: ["ContractusAPI"]),
    ]
)
