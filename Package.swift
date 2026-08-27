// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Murti",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        // MurtiCore is dependency-free. Optional adapters (MurtiAlamofire,
        // MurtiLottie, …) ship as their own packages so this stays clean.
        .library(name: "MurtiCore", targets: ["MurtiCore"]),
        .library(name: "MurtiBuilder", targets: ["MurtiBuilder"]),
        .executable(name: "MurtiGallery", targets: ["MurtiGallery"]),
        .executable(name: "MurtiGen", targets: ["MurtiGen"]),
    ],
    targets: [
        .target(name: "MurtiCore"),
        .target(name: "MurtiBuilder", dependencies: ["MurtiCore"]),
        .executableTarget(name: "MurtiGallery", dependencies: ["MurtiCore"]),
        .executableTarget(name: "MurtiGen", dependencies: ["MurtiBuilder", "MurtiCore"]),
        .testTarget(name: "MurtiCoreTests", dependencies: ["MurtiCore"]),
        .testTarget(name: "MurtiBuilderTests", dependencies: ["MurtiBuilder"]),
        .testTarget(name: "MurtiGenTests", dependencies: ["MurtiGen", "MurtiBuilder", "MurtiCore"]),
    ]
)
