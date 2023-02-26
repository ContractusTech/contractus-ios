// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShamirSecretSharing",
    products: [
        .library(name: "ShamirSecretSharing", type: .dynamic, targets: ["ShamirSecretSharing"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "libsss"),
        .target(name: "ShamirSecretSharing", dependencies: ["libsss"]),
    ]
)
