// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Components6000",
  platforms: [
    .iOS(.v15),
    .macOS(.v11),
  ],
  products: [
    .library(name: "Shared", targets: ["Shared"]),
    .library(name: "Discovery", targets: ["Discovery"]),
    .library(name: "Picker", targets: ["Picker"]),
    .library(name: "ApiViewer", targets: ["ApiViewer"]),
    .library(name: "LogViewer", targets: ["LogViewer"]),
    .library(name: "Commands", targets: ["Commands"]),
    .library(name: "Streams", targets: ["Streams"]),
    .library(name: "LogProxy", targets: ["LogProxy"]),
    .library(name: "XCGWrapper", targets: ["XCGWrapper"]),
    .library(name: "SecureStorage", targets: ["SecureStorage"]),
  ],
  dependencies: [
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.28.1"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1"),
  ],
  targets: [
    .target(
      name: "SecureStorage",
      dependencies: [
        ]
    ),
    .target(
      name: "LogProxy",
      dependencies: [
        ]
    ),
    .target(
      name: "ApiViewer",
      dependencies: [
        "Picker",
        "Discovery",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "LogViewer",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Shared",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Discovery",
      dependencies: [
        "Shared",
        "SecureStorage",
        "LogProxy",
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "Picker",
      dependencies: [
        "Discovery",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "XCGWrapper",
      dependencies: [
        "LogProxy",
        .product(name: "XCGLogger", package: "XCGLogger"),
      ]
    ),
    .target(
      name: "Commands",
      dependencies: [
        "Shared",
        "LogProxy",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "Streams",
      dependencies: [
        "Shared",
        "LogProxy",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .testTarget(
      name: "DiscoveryTests",
      dependencies: ["Discovery"]
    ),
    .testTarget(
      name: "PickerTests",
      dependencies: ["Picker"]
    ),
    .testTarget(
      name: "ApiViewerTests",
      dependencies: ["ApiViewer"]
    ),
    .testTarget(
      name: "LogViewerTests",
      dependencies: ["LogViewer"]
    ),
    .testTarget(
      name: "SecureStorageTests",
      dependencies: ["SecureStorage"]
    ),
    .testTarget(
      name: "XCGWrapperTests",
      dependencies: ["XCGWrapper"]
    ),
    .testTarget(
      name: "CommandsTests",
      dependencies: ["Commands", "Discovery"]
    ),
  ]
)
