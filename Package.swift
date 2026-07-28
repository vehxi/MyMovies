// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MyMovies",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "MyMovies", targets: ["MyMovies"])
    ],
    targets: [
        .executableTarget(
            name: "MyMovies",
            path: "MyMovies",
            exclude: [
                "MyMovies.entitlements",
                "Resources/Assets.xcassets"
            ],
            resources: [
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "MyMoviesTests",
            dependencies: ["MyMovies"],
            path: "MyMoviesTests"
        )
    ]
)
