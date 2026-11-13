import SwiftUI

// Rysunki dziecka: te same funkcje co w grze webowej (osiolekKodem, kotekKodem, rysujScene…).
// Punkty pochodzą z Rysunki.json; nic nie jest dorysowane od nowa.

/// Koszulka narysowana przez dziecko; `kolor` może zastąpić kolor z rysunku (paleta w szafie).
struct Koszulka: Equatable {
    let indeks: Int
    var kolor: String?
    var dane: J { RYS["KOSZULKI"][indeks] }
    var id: String { dane["id"].napis }
    var ramka: [Double] { dane["ramka"].liczby }
    var kolorRysunku: String { kolor ?? dane["kolor"].napis }
    static let wszystkie: [Koszulka] = RYS["KOSZULKI"].tablica.indices.map { Koszulka(indeks: $0) }
    static func == (a: Koszulka, b: Koszulka) -> Bool { a.indeks == b.indeks && a.kolor == b.kolor }
}

func rysujKoszulke(_ c: Plotno, _ s: Double, _ k: Koszulka, _ minPx: Double = 0) {
    let D = k.dane
    piorko(c, s, 8, minPx)
    c.save()
    if D["obrot"].logiczna {
        let r = k.ramka
        c.translate(r[0] + r[2] / 2, r[1] + r[3] / 2); c.rotate(.pi); c.translate(-(r[0] + r[2] / 2), -(r[1] + r[3] / 2))
    }
    let polBiala = Color(hex: "#ffffffaa")
    ksztalt(c, D["obrys"].punkty, Color(hex: k.kolorRysunku))
    if D["platki"].istnieje { ksztalt(c, D["platki"].punkty, polBiala) }
    for s in D["ksztalty"].tablica { ksztalt(c, s.punkty, polBiala) }
    for o in D["pelne"].tablica { owal(c, o.liczby, polBiala) }
    for o in D["owale"].tablica { owal(c, o.liczby, nil) }
    for l in D["linie"].tablica { linia(c, l.punkty) }
    for p in D["kropki"].tablica {
        c.beginPath(); c.arc(p[0].liczba, p[1].liczba, 6); c.fillStyle = TUSZ; c.fill()
    }
    c.restore()
}

let OSIOLEK_RAMKA = RYS["OSIOLEK"]["ramka"].liczby
let KOTEK_RAMKA = RYS["KOTEK"]["ramka"].liczby
let SCENA_RAMKA = RYS["SCENA"]["ramka"].liczby
let DOMEK_RAMKA = RYS["DOMEK_RAMKA"].liczby
let LAPKA_RAMKA = RYS["LAPKA"]["ramka"].liczby
let KRZAK_RAMKA = RYS["KRZAK"]["ramka"].liczby
let SERCE_RAMKA = RYS["SERCE"]["ramka"].liczby

func osiolekKodem(_ c: Plotno, _ s: Double, _ koszulka: Koszulka?) {
    let O = RYS["OSIOLEK"]
    piorko(c, s)
    ksztalt(c, O["ogon"].punkty, kolorK("osiol")); ksztalt(c, O["kitka"].punkty, kolorK("kitka"))
    for n in O["nogi"].tablica { ksztalt(c, n.punkty, kolorK("osiol")) }
    for u in O["uszy"].tablica { ksztalt(c, u.punkty, kolorK("osiol")) }
    ksztalt(c, O["brzuch"].punkty, kolorK("osiol"))
    if let k = koszulka {
        let t = O["tulow"].liczby
        wpisz(c, k.ramka, t[0], t[1], t[2], t[3]) { c2, s2 in rysujKoszulke(c2, s * s2, k, 0.7) }
        piorko(c, s)
    }
    ksztalt(c, O["glowa"].punkty, kolorK("osiol")); ksztalt(c, O["pyszczek"].punkty, kolorK("pyszczek"))
    for o in O["oczy"].tablica { owal(c, o.liczby, TUSZ) }
    for o in O["nozdrza"].tablica { owal(c, o.liczby, TUSZ) }
}

func kotekKodem(_ c: Plotno, _ s: Double) {
    let T = RYS["KOTEK"]
    piorko(c, s)
    ksztalt(c, T["ogon"].punkty, kolorK("kotek"))
    c.fillStyle = kolorK("kotek"); sciezka(c, T["tulow"].punkty, true); c.fill()
    for k in T["kreski"].tablica { linia(c, k.punkty) }
    ksztalt(c, T["glowa"].punkty, kolorK("kotek"))
    ksztalt(c, T["nosek"].punkty, kolorK("nosek")); linia(c, T["buzia"].punkty)
    for o in T["oczy"].tablica { owal(c, o.liczby, TUSZ) }
}

func gwiazdka(_ c: Plotno, _ g: [Double], _ kolor: Color) {
    let x = g[0], y = g[1], r1 = g[2], r2 = g[3]
    c.beginPath()
    for k in 0..<10 {
        let a = -Double.pi / 2 + 0.25 + Double(k) * Double.pi / 5, r = k % 2 == 1 ? r2 : r1
        if k == 0 { c.moveTo(x + cos(a) * r, y + sin(a) * r) } else { c.lineTo(x + cos(a) * r, y + sin(a) * r) }
    }
    c.closePath(); c.fillStyle = kolor; c.fill(); c.stroke()
}

func rysujDomek(_ c: Plotno, _ s: Double) {
    let D = RYS["SCENA"]["domek"]
    piorko(c, s, 7)
    ksztalt(c, D["dach"].punkty, kolorK("dach"))
    for l in D["linie"].tablica { linia(c, l.punkty) }
    ksztalt(c, D["sciany"].punkty, kolorK("sciany"))
    for o in D["okna"].tablica { ksztalt(c, o.punkty, kolorK("okna")) }
    for l in D["krzyzyki"].tablica { linia(c, l.punkty) }
    ksztalt(c, D["drzwi"].punkty, kolorK("drzwi"))
    owal(c, D["galka"].liczby, TUSZ)
    linia(c, D["patyk"].punkty)
    gwiazdka(c, D["gwiazdka"].liczby, kolorK("gwiazdka"))
}

func rysujDrzewo(_ c: Plotno, _ s: Double) {
    let D = RYS["SCENA"]["drzewo"]
    piorko(c, s, 7)
    ksztalt(c, D["pien"].punkty, kolorK("pien"))
    for k in D["kora"].tablica { linia(c, k.punkty) }
    ksztalt(c, D["korona"].punkty, kolorK("korona"))
    for p in D["listki"].punkty { owal(c, [p.x, p.y, 30, 19, -0.6], kolorK("listek")) }
}

/// Domek z otoczeniem; `bezNieba` — sam domek z drzewkiem (do pola labiryntu).
func rysujScene(_ c: Plotno, _ s: Double, bezNieba: Bool = false) {
    let S = RYS["SCENA"]
    piorko(c, s, 7)
    if !bezNieba {
        owal(c, S["slonce"]["kolo"].liczby, kolorK("slonce"))
        for p in S["slonce"]["promienie"].tablica { linia(c, p.punkty) }
        for ch in S["chmury"].tablica { ksztalt(c, ch.punkty, kolorK("chmura")) }
        for o in S["buzia"]["oczy"].tablica { linia(c, o.punkty) }
        linia(c, S["buzia"]["usta"].punkty)
    }
    rysujDrzewo(c, s)
    rysujDomek(c, s)
}

func rysujLapke(_ c: Plotno, _ s: Double, _ kolor: Color) {
    let L = RYS["LAPKA"]
    piorko(c, s, 9)
    ksztalt(c, L["poduszka"].punkty, kolor)
    for p in L["palce"].tablica { ksztalt(c, p.punkty, kolor) }
}

func rysujKrzak(_ c: Plotno, _ s: Double) {
    piorko(c, s, 9)
    ksztalt(c, RYS["KRZAK"]["obrys"].punkty, kolorK("krzak"))
    linia(c, RYS["KRZAK"]["petelka"].punkty)
}

func rysujSerce(_ c: Plotno, _ s: Double) {
    piorko(c, s, 9)
    ksztalt(c, RYS["SERCE"]["obrys"].punkty, kolorK("nosek"))
    linia(c, RYS["SERCE"]["linia"].punkty)
}

let OLOWEK = RYS["OLOWEK"].napis

/// Rysunki kredkami: warstwy wypełnień ("w") i kresek ("k").
func rysujWarstwy(_ c: Plotno, _ s: Double, _ D: J) {
    for w in D["warstwy"].tablica {
        if w[0].napis == "w" {
            c.fillStyle = Color(hex: w[1].napis); sciezka(c, w[2].punkty, true); c.fill()
            if w[3].istnieje { piorko(c, s, 2.4); c.strokeStyle = Color(hex: w[3].napis); c.stroke() }
        } else {
            piorko(c, s, w[2].liczba); c.strokeStyle = Color(hex: w[1].napis)
            for l in w[3].tablica { linia(c, l.punkty) }
        }
    }
}

func danePrzedmiotu(_ p: Przedmiot) -> J {
    switch p {
    case .serce: return RYS["SERCE"]
    case .grzybek: return RYS["GRZYBEK"]
    case .pilka: return RYS["PILKA"]
    case .trawa: return RYS["TRAWA"]
    }
}
func ramkaPrzedmiotu(_ p: Przedmiot) -> [Double] { danePrzedmiotu(p)["ramka"].liczby }

/// Przedmiot do zebrania: pokolorowany albo (na pasku, jeszcze niezebrany) same kontury jak w kolorowance.
func rysujPrzedmiot(_ c: Plotno, _ s: Double, _ p: Przedmiot, kolor: Bool) {
    if p == .serce {
        piorko(c, s, 9)
        ksztalt(c, RYS["SERCE"]["obrys"].punkty, kolor ? kolorK("nosek") : nil)
        linia(c, RYS["SERCE"]["linia"].punkty)
        return
    }
    let D = danePrzedmiotu(p)
    if kolor { rysujWarstwy(c, s, D); return }
    for w in D["warstwy"].tablica {
        if w[0].napis == "w" { piorko(c, s, 2.4); sciezka(c, w[2].punkty, true); c.stroke() } else {
            piorko(c, s, w[2].liczba)
            if w[1].napis != OLOWEK { c.strokeStyle = Color(hex: "#c4c1cb") }
            for l in w[3].tablica { linia(c, l.punkty) }
        }
    }
}

// MARK: - Postacie w prostokątach

func rysujOsiolka(_ c: Plotno, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ koszulka: Koszulka?) {
    wpisz(c, OSIOLEK_RAMKA, x, y, w, h) { c2, s in osiolekKodem(c2, s, koszulka) }
}
func rysujKotka(_ c: Plotno, _ x: Double, _ y: Double, _ w: Double, _ h: Double) {
    wpisz(c, KOTEK_RAMKA, x, y, w, h, kotekKodem)
}
func lapka(_ c: Plotno, _ x: Double, _ y: Double, _ r: Double, _ kat: Double, _ kolor: Color) {
    c.save(); c.translate(x, y); c.rotate(kat)
    wpisz(c, LAPKA_RAMKA, -r, -r, 2 * r, 2 * r) { c2, s in rysujLapke(c2, s, kolor) }
    c.restore()
}

/// Obwódki postaci: osiołek ma żółtą w obu motywach (żeby dziecko od razu go widziało),
/// kotek i domek jasną w motywie ciemnym.
enum Obwodka {
    static let osiolek = Color(hex: RYS["OBWODKA"]["osiolek"].napis)
    static let ciemny = Color(hex: RYS["OBWODKA"]["ciemny"].napis)
}

/// Rysunek jak naklejka: sylwetka w kolorze obwódki przesunięta dookoła (12 kierunków), a na niej rysunek
/// (`zObwodka` z gry). Rysuje w prostokącie (x, y, w, h); obwódka wychodzi poza niego.
func zObwodka(_ c: Plotno, _ x: Double, _ y: Double, _ w: Double, _ h: Double, kolor: Color?, _ rysuj: (Plotno) -> Void) {
    let przed = c.minKreska
    if h < 48 { c.minKreska = 1.2 }
    defer { c.minKreska = przed }
    if let kolor {
        let r = max(2.5, min(w, h) * 0.07)
        c.warstwa(filtry: [jednolity(kolor)]) { l in
            for k in 0..<12 {
                l.save(); l.translate(cos(Double(k) * .pi / 6) * r, sin(Double(k) * .pi / 6) * r)
                rysuj(l)
                l.restore()
            }
        }
    }
    rysuj(c)
}

/// Filtr zamieniający rysunek w sylwetkę jednego koloru (z zachowaniem przezroczystości), jak `source-in` na płótnie.
func jednolity(_ kolor: Color) -> GraphicsContext.Filter {
    let rgb = kolor.resolve(in: EnvironmentValues())
    var m = ColorMatrix()
    m.r1 = 0; m.r2 = 0; m.r3 = 0; m.r4 = 0; m.r5 = rgb.red
    m.g1 = 0; m.g2 = 0; m.g3 = 0; m.g4 = 0; m.g5 = rgb.green
    m.b1 = 0; m.b2 = 0; m.b3 = 0; m.b4 = 0; m.b5 = rgb.blue
    return .colorMatrix(m)
}
