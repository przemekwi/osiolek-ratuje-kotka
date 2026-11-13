// swift-tools-version:5.9
// Logika gry (czysty Swift, bez SwiftUI) jako biblioteka do testów — także na Linuksie.
// Aplikację buduje się z OsiolekRatujeKotka.xcodeproj; te same pliki logiki są w niej skompilowane bezpośrednio.
import PackageDescription

let package = Package(
    name: "OsiolekLogika",
    targets: [
        .target(name: "OsiolekLogika", path: "OsiolekRatujeKotka/Logika"),
        .testTarget(name: "OsiolekLogikaTests", dependencies: ["OsiolekLogika"], path: "Testy/OsiolekLogikaTests"),
    ]
)
