// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Components6000",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
  ],
  products: [
    .library(name: "Shared", targets: ["Shared"]),
    .library(name: "LanDiscovery", targets: ["LanDiscovery"]),
    .library(name: "PickerView", targets: ["PickerView"]),
    .library(name: "ApiViewer", targets: ["ApiViewer"]),
    .library(name: "LogViewer", targets: ["LogViewer"]),
    .library(name: "TcpCommands", targets: ["TcpCommands"]),
    .library(name: "UdpStreams", targets: ["UdpStreams"]),
    .library(name: "XCGWrapper", targets: ["XCGWrapper"]),
    .library(name: "SecureStorage", targets: ["SecureStorage"]),
    .library(name: "WanDiscovery", targets: ["WanDiscovery"]),
    .library(name: "Radio", targets: ["Radio"]),
    .library(name: "ClientView", targets: ["ClientView"]),
    .library(name: "RemoteViewer", targets: ["RemoteViewer"]),
    .library(name: "LoginView", targets: ["LoginView"]),
    .library(name: "ProgressView", targets: ["ProgressView"]),
    .library(name: "SdrViewer", targets: ["SdrViewer"]),
    .library(name: "LevelIndicator", targets: ["LevelIndicator"]),
  ],
  dependencies: [
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.32.0"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1"),
  ],
  targets: [
    // --------------- Modules ---------------
    // LevelIndicator
    .target(
      name: "LevelIndicator",
      dependencies: [
      ]
    ),
    
    // SdrViewer
    .target(
      name: "SdrViewer",
      dependencies: [
        "Shared",
        "LevelIndicator",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // ProgressView
    .target(
      name: "ProgressView",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // LoginView
    .target(
      name: "LoginView",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // RemoteViewer
    .target(
      name: "RemoteViewer",
      dependencies: [
        "Shared",
        "LoginView",
        "SecureStorage",
        "ProgressView",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // ClientView
    .target(
      name: "ClientView",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // Radio
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
    
    // Shared
    .target(
      name: "Shared",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // WanDiscovery
    .target(
      name: "WanDiscovery",
      dependencies: [
        "Shared",
        "LoginView",
        "SecureStorage",
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    
    // SecureStorage
    .target(
      name: "SecureStorage",
      dependencies: []
    ),
    
    // LevelIndicator
    .target(
      name: "ApiViewer",
      dependencies: [
        "WanDiscovery",
        "PickerView",
        "ClientView",
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
    
    // LogViewer
    .target(
      name: "LogViewer",
      dependencies: [
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // LanDiscovery
    .target(
      name: "LanDiscovery",
      dependencies: [
        "Shared",
        "SecureStorage",
        .product(name: "JWTDecode", package: "JWTDecode.swift"),
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    
    // PickerView
    .target(
      name: "PickerView",
      dependencies: [
        "LanDiscovery",
        "WanDiscovery",
        "ClientView",
        "Shared",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    
    // XCGWrapper
    .target(
      name: "XCGWrapper",
      dependencies: [
        "Shared",
        .product(name: "XCGLogger", package: "XCGLogger"),
        .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
      ]
    ),
    
    // TcpCommands
    .target(
      name: "TcpCommands",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
    
    // UdpStreams
    .target(
      name: "UdpStreams",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
//    .testTarget(
//      name: "LoginViewTests",
//      dependencies: ["LoginView"]
//    ),
//    .testTarget(
//      name: "DiscoveryTests",
//      dependencies: ["LanDiscovery"]
//    ),
//    .testTarget(
//      name: "PickerTests",
//      dependencies: ["PickerView"]
//    ),
//    .testTarget(
//      name: "ApiViewerTests",
//      dependencies: ["ApiViewer"]
//    ),
    
    // --------------- Modules ---------------
    // SecureStorageTests
    .testTarget(
      name: "SecureStorageTests",
      dependencies: ["SecureStorage"]
    ),
//    .testTarget(
//      name: "TcpCommandsTests",
//      dependencies: ["TcpCommands", "LanDiscovery"]
//    ),
    
    // LoggingTests
    .testTarget(
      name: "LoggingTests",
      dependencies: [
        "Shared",
        "XCGWrapper",
        "LogViewer",
      ]
    ),
//    .testTarget(
//      name: "RadioTests",
//      dependencies: ["Radio"]
//    ),
  ]
)
