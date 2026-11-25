// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KakeibotApp",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]
        ),
        .library(
            name: "AppWidget",
            targets: ["AppWidget"]
        )
    ],
    dependencies: [
        .package(path: "../KakeibotKit")
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "DesignSystem",
                "FeatureModels",
                "Features",
                "Notifications",
                "Sync",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .target(
            name: "AppWidget",
            dependencies: [
                "DesignSystem",
                "Notifications",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "FeatureModels",
            dependencies: [
                "DesignSystem",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "Features",
            dependencies: [
                "DesignSystem",
                "FeatureModels",
                .product(name: "Core", package: "KakeibotKit")
            ],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .target(
            name: "Notifications",
            dependencies: [
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "Sync",
            dependencies: [
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "TestSupport",
            path: "Tests/TestSupport"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                "FeatureModels",
                "Notifications",
                "TestSupport",
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "AppWidgetTests",
            dependencies: [
                "AppWidget",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem",
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "FeatureModels",
                "Features",
                "TestSupport",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "SyncTests",
            dependencies: [
                "Sync",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        )
    ]
)
