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
    .library(name: "XCGWrapper", targets: ["XCGWrapper"]),
    .library(name: "SecureStorage", targets: ["SecureStorage"]),
    .library(name: "Login", targets: ["Login"]),
  ],
  dependencies: [
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.32.0"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1"),
  ],
  targets: [
    .target(
      name: "Shared",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Login",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "SecureStorage",
      dependencies: []
    ),
    .target(
      name: "ApiViewer",
      dependencies: [
        "Login",
        "Picker",
        "Discovery",
        "Commands",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "LogViewer",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Discovery",
      dependencies: [
        "Shared",
        "SecureStorage",
        "Login",
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
        .product(name: "XCGLogger", package: "XCGLogger"),
        .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
      ]
    ),
    .target(
      name: "Commands",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "Streams",
      dependencies: [
        "Shared",
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
