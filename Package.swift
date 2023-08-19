// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Media",
    defaultLocalization: "en",
    platforms: [.iOS(.v11), .macOS(.v10_12), .tvOS(.v10), .watchOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Media",
            targets: ["Media"])
    ],
    dependencies: [
        .package(url: "https://github.com/rosberry/CollectionViewTools", from: "0.1.7"),
        .package(url: "https://github.com/onmyway133/DeepDiff", from: "2.3.3"),
        .package(url: "https://github.com/rosberry/Framezilla", from: "5.1.2"),
        .package(name: "MediaService", url: "https://github.com/rosberry/MediaService", .branch("master")),
        .package(name: "Ion", url: "https://github.com/rosberry/ion", .branch("master")),
        .package(name: "Texstyle", url: "https://github.com/rosberry/texstyle", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Media",
            dependencies: ["CollectionViewTools", "DeepDiff", "Framezilla", "Ion", "MediaService", "Texstyle", "Rcam"])
    ]
)
