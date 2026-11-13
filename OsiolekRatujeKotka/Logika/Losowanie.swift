import Foundation

/// Generator liczb losowych (SplitMix64). W grze ziarno jest losowe, w testach stałe,
/// więc ten sam labirynt da się odtworzyć. Odpowiada `R`, `ri`, `pick` z gry webowej.
struct Los {
    private var stan: UInt64

    init(ziarno: UInt64 = UInt64.random(in: .min ... .max)) { stan = ziarno }

    /// Liczba z przedziału [0, 1), jak `Math.random()`.
    mutating func R() -> Double {
        stan &+= 0x9E37_79B9_7F4A_7C15
        var z = stan
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }

    /// `Math.floor(R()*n)`.
    mutating func ri(_ n: Int) -> Int { min(n - 1, Int(R() * Double(n))) }

    mutating func pick<T>(_ a: [T]) -> T { a[ri(a.count)] }

    /// Tasowanie Fishera-Yatesa (`tasuj` z gry).
    mutating func tasuj<T>(_ a: [T]) -> [T] {
        var a = a
        var i = a.count - 1
        while i > 0 {
            let j = ri(i + 1)
            a.swapAt(i, j)
            i -= 1
        }
        return a
    }
}

/// Stały „los” dla pola planszy: ten sam labirynt zawsze wygląda tak samo, także po obrocie ekranu.
/// Dokładne odwzorowanie `los(i,s)` z gry (liczby zmiennoprzecinkowe i 32-bitowa arytmetyka JavaScriptu;
/// `s` bywa ułamkowe, np. przy kamieniach w ścianie).
func losPola(_ i: Double, _ s: Double, wersja: Int) -> Double {
    let suma = i * 374_761_393 + s * 668_265_263 + Double(wersja) * 2_246_822_519
    // ToInt32 z JavaScriptu: obcięcie części ułamkowej i reszta z dzielenia przez 2^32.
    let m = suma.rounded(.towardZero).truncatingRemainder(dividingBy: 4_294_967_296)
    var h = Int32(truncatingIfNeeded: Int64(m))
    h = (h ^ Int32(bitPattern: UInt32(bitPattern: h) >> 13)) &* 1_274_126_177
    let u = UInt32(bitPattern: h ^ Int32(bitPattern: UInt32(bitPattern: h) >> 16))
    return Double(u) / 4_294_967_296
}

func losPola(_ i: Int, _ s: Int, wersja: Int) -> Double { losPola(Double(i), Double(s), wersja: wersja) }
