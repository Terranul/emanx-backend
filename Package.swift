// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "EmailAnxietyBackend",

    platforms: [
        .macOS(.v13)
    ],

    dependencies: [
        // Vapor web framework
        .package(
            url: "https://github.com/vapor/vapor.git",
            from: "4.121.4"
        ),

        // Swift NIO
        .package(
            url: "https://github.com/apple/swift-nio.git",
            from: "2.101.0"
        ),

        // Fluent ORM
        .package(
            url: "https://github.com/vapor/fluent.git",
            from: "4.0.0"
        ),

        // PostgreSQL driver for Fluent
        .package(
            url: "https://github.com/vapor/fluent-postgres-driver.git",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/mochidev/swift-webpush.git", 
            .upToNextMinor(from: "0.4.1")
        )
    ],

    targets: [
        .executableTarget(
            name: "EmailAnxietyBackend",

            dependencies: [
                .product(
                    name: "Vapor",
                    package: "vapor"
                ),

                .product(
                    name: "NIOCore",
                    package: "swift-nio"
                ),

                .product(
                    name: "NIOPosix",
                    package: "swift-nio"
                ),

                .product(
                    name: "Fluent",
                    package: "fluent"
                ),

                .product(
                    name: "FluentPostgresDriver",
                    package: "fluent-postgres-driver"
                ),
                .product(name: "WebPush", package: "swift-webpush")
            ],

            swiftSettings: swiftSettings
        ),

        .testTarget(
            name: "EmailAnxietyBackendTests",

            dependencies: [
                .target(
                    name: "EmailAnxietyBackend"
                ),

                .product(
                    name: "VaporTesting",
                    package: "vapor"
                )
            ],

            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("ImmutableWeakCaptures")
    ]
}