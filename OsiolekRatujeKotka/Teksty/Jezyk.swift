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

    /// „3 kroki”, „5 kroków” — odmiana jak w grze (polski: trzy formy, chiński: bez spacji).
    static func kroki(_ jezyk: String, _ n: Int) -> String {
        let f = surowy(jezyk, "kroki").tablica.map(\.napis)
        guard !f.isEmpty else { return "\(n)" }
        if jezyk.hasPrefix("zh") { return "\(n)\(f[0])" }
        let i: Int
        if jezyk == "pl" {
            i = n == 1 ? 0 : (n % 10 >= 2 && n % 10 <= 4 && !(n % 100 >= 12 && n % 100 <= 14)) ? 1 : 2
        } else { i = n == 1 ? 0 : 1 }
        return "\(n) \(f[min(i, f.count - 1)])"
    }
}
