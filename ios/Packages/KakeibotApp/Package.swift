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
            name: "WidgetFeature",
            targets: ["WidgetFeature"]
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
                "Features",
                "Notifications",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "WidgetFeature",
            dependencies: [
                "DesignSystem",
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "Features",
            dependencies: [
                "DesignSystem",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "Notifications",
            dependencies: [
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                "Notifications",
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem"
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "Features",
                .product(name: "Core", package: "KakeibotKit"),
                .product(name: "Store", package: "KakeibotKit")
            ]
        )
    ]
)
