// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TestDiscoveryPackage",
  platforms: [
    .iOS(.v15),
    .macOS(.v11),
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(name: "Shared", targets: ["Shared"]),
    .library(name: "Discovery", targets: ["Discovery"]),
//    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "Picker", targets: ["Picker"]),
    .library(name: "LogViewer", targets: ["LogViewer"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "0.28.1"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "LogViewer",
      dependencies: [
      ]
    ),
    .target(
      name: "Shared",
      dependencies: [
      ]
    ),
    .target(
      name: "Discovery",
      dependencies: [
        "Shared",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      ]
    ),
//    .target(
//      name: "AppFeature",
//      dependencies: [
//        "Picker",
//        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
//      ]
//    ),
    .target(
      name: "Picker",
      dependencies: [
        "Discovery",
        .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
//    .testTarget(
//      name: "AppFeatureTests",
//      dependencies: ["AppFeature"]
//    ),
    .testTarget(
      name: "PickerTests",
      dependencies: ["Picker"]
    ),
  ]
)
