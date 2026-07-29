// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Mosaic",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Mosaic",
            targets: ["Mosaic"]
        ),
    ],
    dependencies: [
        // swift-syntax bumps its major version with each Swift release, so a range
        // spanning the 6xx series keeps the macro target usable across toolchains
        // rather than pinning consumers to one.
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"700.0.0"),
    ],
    targets: [
        .target(
            name: "MosaicCore",
            path: "Sources/Mosaic"
        ),
        .target(
            name: "Mosaic",
            dependencies: [
                "MosaicCore",
                "MosaicMacros",
            ],
            path: "Sources/MosaicExports"
        ),
        .macro(
            name: "MosaicMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "MosaicTests",
            dependencies: ["MosaicCore"],
            path: "Tests/MosaicTests"
        ),
    ]
)
