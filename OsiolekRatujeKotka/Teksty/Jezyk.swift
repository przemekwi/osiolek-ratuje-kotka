import Foundation

/// Teksty gry w ośmiu językach (Teksty.json wyeksportowany z gry webowej). Polski jest źródłowy:
/// brakujący tekst w innym języku zastępuje polski, jak `t(k,p)` w grze.
enum Teksty {
    static let dane = J.wczytaj("Teksty")
    static let jezyki: [String] = dane["jezyki"].tablica.map(\.napis)
    static func nazwa(_ jezyk: String) -> String { dane["nazwy"][jezyk].napis }

    /// Język urządzenia przypisany do jednego z języków gry (`jezykPrzegladarki`).
    static func jezykUrzadzenia() -> String {
        let l = (Locale.preferredLanguages.first ?? "pl").lowercased()
        if l.hasPrefix("zh") { return l.contains("hant") || l.contains("-tw") || l.contains("-hk") || l.contains("-mo") ? "zh-Hant" : "zh-Hans" }
        let k = String(l.prefix(2))
        return jezyki.contains(k) ? k : "en"
    }

    static func surowy(_ jezyk: String, _ klucz: String) -> J {
        if let t = TekstyAplikacji.tekst(jezyk, klucz) { return .napis(t) }
        let w = dane["teksty"][jezyk][klucz]
        return w.istnieje ? w : dane["teksty"]["pl"][klucz]
    }

    /// Tekst z podstawionymi parametrami {n}, {s}…
    static func t(_ jezyk: String, _ klucz: String, _ p: [String: CustomStringConvertible] = [:]) -> String {
        var s = surowy(jezyk, klucz).napis
        for (k, v) in p { s = s.replacingOccurrences(of: "{\(k)}", with: v.description) }
        return s
    }

}
