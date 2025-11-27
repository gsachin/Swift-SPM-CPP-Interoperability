// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JsonWrapper",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(
            name: "JsonWrapper",
            targets: ["JsonWrapper"]
        ),
    ],
    targets: [
        // C++ JSON Parser (nlohmann/json + C wrapper)
        .target(
            name: "CxxJsonParser",
            path: "Sources/CxxJsonParser",
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
            ]
        ),
        
        // Swift wrapper around C API
        .target(
            name: "JsonWrapper",
            dependencies: ["CxxJsonParser"],
            path: "Sources/JsonWrapper"
        ),
        
        // Tests
        .testTarget(
            name: "JsonWrapperTests",
            dependencies: ["JsonWrapper"]
        ),
    ],
    cxxLanguageStandard: .cxx17
)
