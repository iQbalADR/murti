// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Murti",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
        .macCatalyst(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        // MurtiCore is dependency-free. Optional adapters (MurtiAlamofire,
        // MurtiLottie, …) ship as their own packages so this stays clean.
        .library(name: "MurtiCore", targets: ["MurtiCore"]),
        .library(name: "MurtiBuilder", targets: ["MurtiBuilder"]),
        .executable(name: "MurtiGallery", targets: ["MurtiGallery"]),
        .executable(name: "MurtiGen", targets: ["MurtiGen"]),
        .executable(name: "MurtiStudio", targets: ["MurtiStudio"]),
    ],
    targets: [
        .target(name: "MurtiCore"),
        .target(name: "MurtiBuilder", dependencies: ["MurtiCore"]),
        .executableTarget(name: "MurtiGallery", dependencies: ["MurtiCore"]),
        .executableTarget(name: "MurtiGen", dependencies: ["MurtiBuilder", "MurtiCore"]),
        .executableTarget(name: "MurtiStudio", dependencies: ["MurtiCore", "MurtiBuilder"]),
        .testTarget(name: "MurtiCoreTests", dependencies: ["MurtiCore"]),
        .testTarget(name: "MurtiBuilderTests", dependencies: ["MurtiBuilder"]),
        .testTarget(name: "MurtiGenTests", dependencies: ["MurtiGen", "MurtiBuilder", "MurtiCore"]),
        .testTarget(name: "MurtiStudioTests", dependencies: ["MurtiStudio", "MurtiCore"]),
    ]
)
