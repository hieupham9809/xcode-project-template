// swift-tools-version: 5.9
import PackageDescription

private extension PackageDescription.Target.Dependency {
    // static let factory: Self = .product(name: "Factory", package: "Factory")
}

private extension PackageDescription.Target.PluginUsage {
    // static let swiftGen: Self = .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
}

let debugOtherSwiftFlags = [
    "-Xfrontend", "-warn-long-expression-type-checking=200",
    "-Xfrontend", "-warn-long-function-bodies=200",
    "-strict-concurrency=targeted",
    "-enable-actor-data-race-checks",
]

let package = Package(
    name: "SmartSubscriptionKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SmartSubscriptionKit",
            targets: ["SmartSubscriptionKit"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SmartSubscriptionKit",
            dependencies: [
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [.unsafeFlags(debugOtherSwiftFlags, .when(configuration: .debug))],
            plugins: [
            ]
        ),
        .testTarget(
            name: "SmartSubscriptionKitTests",
            dependencies: ["SmartSubscriptionKit"],
            path: "Tests"
        ),
        // .target(
        //     name: "Mocks",
        //     dependencies: [
        //     ],
        //     path: "./Tests/Mocks",
        //     exclude: [".gitkeep"]
        // ),
    ]
)
