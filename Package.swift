// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "Janus",
    platforms: [
        .macOS(.v10_14), .iOS(.v13), .tvOS(.v13),
    ],
    products: [
        .library(
            name: "Janus",
            targets: ["Janus"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Janus",
            dependencies: ["WebRTC"],
            linkerSettings: [.linkedFramework("WebRTC")]
        ),
        .binaryTarget(name: "WebRTC",
                      url: "https://github.com/alexpiezo/WebRTC/releases/download/95.4638.0/WebRTC-M95.xcframework.zip",
                      checksum: "b49d47cdbbd7d72b03a340aa1b55591b82824926ada8a54be992addf614c8325"
                     ),
        .testTarget(
            name: "JanusTests",
            dependencies: ["Janus"]
        ),
    ]
)
