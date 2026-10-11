// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KakeibotApp",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "WidgetFeature", targets: ["WidgetFeature"])
    ],
    dependencies: [
        .package(path: "../KakeibotKit")
    ],
    targets: [
        .target(name: "AppFeature", dependencies: ["Features", "Notifications"]),
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
                .product(name: "Store", package: "KakeibotKit")
            ]
        ),
        .target(
            name: "Notifications",
            dependencies: [.product(name: "Core", package: "KakeibotKit")]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [.product(name: "Core", package: "KakeibotKit")]
        ),
        .testTarget(name: "AppFeatureTests", dependencies: ["AppFeature"]),
        .testTarget(name: "FeaturesTests", dependencies: ["Features"])
    ]
)
