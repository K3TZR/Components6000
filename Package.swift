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
    .library(name: "LanDiscovery", targets: ["LanDiscovery"]),
    .library(name: "Picker", targets: ["Picker"]),
    .library(name: "ApiViewer", targets: ["ApiViewer"]),
    .library(name: "LogViewer", targets: ["LogViewer"]),
    .library(name: "TcpCommands", targets: ["TcpCommands"]),
    .library(name: "UdpStreams", targets: ["UdpStreams"]),
    .library(name: "XCGWrapper", targets: ["XCGWrapper"]),
    .library(name: "SecureStorage", targets: ["SecureStorage"]),
    .library(name: "WanDiscovery", targets: ["WanDiscovery"]),
    .library(name: "Radio", targets: ["Radio"]),
    .library(name: "ClientStatus", targets: ["ClientStatus"]),
    .library(name: "RemoteViewer", targets: ["RemoteViewer"]),
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
      name: "Login",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "RemoteViewer",
      dependencies: [
        "Shared",
        "Login",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ClientStatus",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Radio",
      dependencies: [
        "LanDiscovery",
        "WanDiscovery",
        "TcpCommands",
        "UdpStreams",
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
      name: "WanDiscovery",
      dependencies: [
        "Shared",
        "Login",
        "SecureStorage",
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "SecureStorage",
      dependencies: []
    ),
    .target(
      name: "ApiViewer",
      dependencies: [
        "WanDiscovery",
        "Picker",
        "ClientStatus",
        "LanDiscovery",
        "TcpCommands",
        "UdpStreams",
        "Radio",
        "LogViewer",
        "XCGWrapper",
        "RemoteViewer",
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
      name: "LanDiscovery",
      dependencies: [
        "Shared",
        "SecureStorage",
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "Picker",
      dependencies: [
        "LanDiscovery",
        "WanDiscovery",
        "ClientStatus",
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "XCGWrapper",
      dependencies: [
        "Shared",
        .product(name: "XCGLogger", package: "XCGLogger"),
        .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
      ]
    ),
    .target(
      name: "TcpCommands",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .target(
      name: "UdpStreams",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    .testTarget(
      name: "DiscoveryTests",
      dependencies: ["LanDiscovery"]
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
      name: "SecureStorageTests",
      dependencies: ["SecureStorage"]
    ),
    .testTarget(
      name: "TcpCommandsTests",
      dependencies: ["TcpCommands", "LanDiscovery"]
    ),
    .testTarget(
      name: "LoggingTests",
      dependencies: [
        "Shared",
        "XCGWrapper",
        "LogViewer",
      ]
    ),
    .testTarget(
      name: "RadioTests",
      dependencies: ["Radio"]
    ),
  ]
)
