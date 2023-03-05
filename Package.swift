// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PieceMetalSuzuki",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PieceMetalSuzuki",
            targets: ["PieceMetalSuzuki"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.21.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PieceMetalSuzuki",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            resources: [
                .copy("Images/"),
                .copy("Metal/"),
                .copy("LookupTables/ProtocolBuffers/"),
                .copy("LookupTables/Data/"),
            ],
            swiftSettings: [
                .unsafeFlags([
                    /// Disabling this flag turns of time profiling and the associated overhead.
//                    "-DPROFILE_SUZUKI",
//                    "-DPROFILE_QUAD",

                    /// Optimization settings.
                    "-Ounchecked",
                    "-O",
                    
                    /// Debugging flags, useful when extremely verbose logging is needed.
                    /// Best used with single images when running test cases.
//                    "-DSHOW_RDP_WORK",
//                    "-DSHOW_GRID_WORK",
                ], nil)
            ]),
        .testTarget(
            name: "PieceMetalSuzukiTests",
            dependencies: ["PieceMetalSuzuki"]),
    ]
)
