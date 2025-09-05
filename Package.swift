// swift-tools-version: 5.5

import PackageDescription

let package = Package(name: "UniqueID", products: [
    .library(name: "UniqueID", targets: ["UniqueID"]),
], dependencies: [
    .package(url: "https://github.com/purpln/timestamp.git", branch: "main"),
], targets: [
    .target(name: "UniqueID", dependencies: [
        .product(name: "Timestamp", package: "timestamp"),
    ]),
])
