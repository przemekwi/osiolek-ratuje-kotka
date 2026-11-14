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

// MARK: - Naklejki i album (rysunki z osobnych kartek)

func rysujSlonce2(_ c: Plotno, _ s: Double) {
    let D = RYS["SLONCE2"]
    piorko(c, s, 9); owal(c, D["kolo"].liczby, kolorK("slonce"))
    for p in D["promienie"].tablica { linia(c, p.punkty) }
}

func rysujZwierzatko(_ c: Plotno, _ s: Double) {
    let Z = RYS["ZWIERZATKO"]
    piorko(c, s, 9)
    for n in Z["nogi"].tablica { ksztalt(c, n.punkty, kolorK("zwierzatko")) }
    for u in Z["uszy"].tablica { ksztalt(c, u.punkty, kolorK("zwierzatko")) }
    ksztalt(c, Z["cialo"].punkty, kolorK("zwierzatko"))
    for u in Z["wUszach"].tablica { linia(c, u.punkty) }
    for o in Z["oczy"].tablica { owal(c, o.liczby, nil) }
    linia(c, Z["usmiech"].punkty)
}

/// Robot: opiekun planu w trybie „Zaplanuj drogę”.
func rysujRobota(_ c: Plotno, _ s: Double) {
    let B = RYS["ROBOT"]
    piorko(c, s, 9)
    for n in B["nogi"].tablica { ksztalt(c, n.punkty, kolorK("robot")) }
    for u in B["uszy"].tablica { ksztalt(c, u.punkty, kolorK("robot")) }
    ksztalt(c, B["cialo"].punkty, kolorK("robot"))
    for u in B["wUszach"].tablica { linia(c, u.punkty) }
    for o in B["oczy"].tablica { owal(c, o.liczby, TUSZ) }
    for b in B["blaski"].tablica {
        let o = b.liczby
        c.beginPath(); c.ellipse(o[0], o[1], o[2], o[3]); c.fillStyle = kolorK("robot"); c.fill()
    }
    linia(c, B["usmiech"].punkty)
}

func rysujDziewczynke(_ c: Plotno, _ s: Double) {
    let D = RYS["DZIEWCZYNKA"]
    piorko(c, s, 9)
    ksztalt(c, D["wlosy"].punkty, kolorK("pien"))
    for o in D["loki"].tablica { owal(c, o.liczby, kolorK("pien")) }
    for l in D["nogi"].tablica { linia(c, l.punkty) }
    ksztalt(c, D["sukienka"].punkty, kolorK("dach"))
    for l in D["rece"].tablica { linia(c, l.punkty) }
    owal(c, D["twarz"].liczby, kolorK("pyszczek"))
    for o in D["oczy"].tablica { owal(c, o.liczby, TUSZ) }
    linia(c, D["usmiech"].punkty)
}

func rysujJednorozca(_ c: Plotno, _ s: Double) {
    let J = RYS["JEDNOROZEC"]
    piorko(c, s, 9)
    for n in J["nogi"].tablica { ksztalt(c, n.punkty, kolorK("jednorozec")) }
    for o in J["kopytka"].tablica { owal(c, o.liczby, nil) }
    linia(c, J["ogon"].punkty)
    ksztalt(c, J["cialo"].punkty, kolorK("jednorozec"))
    linia(c, J["szyja"].punkty)
    ksztalt(c, J["ucho"].punkty, kolorK("jednorozec")); ksztalt(c, J["rog"].punkty, kolorK("slonce"))
    ksztalt(c, J["glowa"].punkty, kolorK("jednorozec"))
    owal(c, J["oko"].liczby, TUSZ); owal(c, J["nos"].liczby, TUSZ); linia(c, J["usmiech"].punkty)
}

/// Gwiazdki: kreski długopisem na żółtym śladzie (jak flamaster pod spodem).
func rysujGwiazdki(_ c: Plotno, _ s: Double) {
    let L = RYS["GWIAZDKI"]["linie"].tablica
    piorko(c, s, 70); c.strokeStyle = kolorK("slonce")
    for l in L { linia(c, l.punkty) }
    piorko(c, s, 12)
    for l in L { linia(c, l.punkty) }
}

let ALBUM_RAMKA = RYS["ALBUM"]["ramka"].liczby

func rysujAlbum(_ c: Plotno, _ s: Double, _ kolor: Color) {
    let A = RYS["ALBUM"]
    piorko(c, s, 9)
    c.fillStyle = kolor; sciezka(c, A["okladka"].punkty, true); c.fill()
    for l in A["kreski"].tablica { linia(c, l.punkty) }
}

/// Rysunek naklejki: ramka i funkcja rysująca (`NAKLEJKI` z gry, ta sama kolejność).
struct RysunekNaklejki {
    let ramka: [Double]
    let rysuj: (Plotno, Double) -> Void
}

func rysunekNaklejki(_ id: String) -> RysunekNaklejki {
    switch id {
    case "osiolek": return RysunekNaklejki(ramka: OSIOLEK_RAMKA) { c, s in osiolekKodem(c, s, nil) }
    case "kotek": return RysunekNaklejki(ramka: KOTEK_RAMKA, rysuj: kotekKodem)
    case "dom": return RysunekNaklejki(ramka: DOMEK_RAMKA) { c, s in rysujScene(c, s, bezNieba: true) }
    case "robot": return RysunekNaklejki(ramka: RYS["ROBOT"]["ramka"].liczby, rysuj: rysujRobota)
    case "lapka": return RysunekNaklejki(ramka: LAPKA_RAMKA) { c, s in rysujLapke(c, s, kolorK("lapka")) }
    case "krzak": return RysunekNaklejki(ramka: KRZAK_RAMKA, rysuj: rysujKrzak)
    case "slonce": return RysunekNaklejki(ramka: RYS["SLONCE2"]["ramka"].liczby, rysuj: rysujSlonce2)
    case "zwierzatko": return RysunekNaklejki(ramka: RYS["ZWIERZATKO"]["ramka"].liczby, rysuj: rysujZwierzatko)
    case "dziewczynka": return RysunekNaklejki(ramka: RYS["DZIEWCZYNKA"]["ramka"].liczby, rysuj: rysujDziewczynke)
    case "jednorozec": return RysunekNaklejki(ramka: RYS["JEDNOROZEC"]["ramka"].liczby, rysuj: rysujJednorozca)
    case "gwiazdki": return RysunekNaklejki(ramka: RYS["GWIAZDKI"]["ramka"].liczby, rysuj: rysujGwiazdki)
    case "serce": return RysunekNaklejki(ramka: SERCE_RAMKA, rysuj: rysujSerce)
    case "trawa": return RysunekNaklejki(ramka: RYS["TRAWA"]["ramka"].liczby) { c, s in rysujWarstwy(c, s, RYS["TRAWA"]) }
    case "samochod": return RysunekNaklejki(ramka: RYS["SAMOCHOD"]["ramka"].liczby) { c, s in rysujWarstwy(c, s, RYS["SAMOCHOD"]) }
    case "kon": return RysunekNaklejki(ramka: RYS["KON"]["ramka"].liczby) { c, s in rysujWarstwy(c, s, RYS["KON"]) }
    case "grzybek": return RysunekNaklejki(ramka: RYS["GRZYBEK"]["ramka"].liczby) { c, s in rysujWarstwy(c, s, RYS["GRZYBEK"]) }
    default: return RysunekNaklejki(ramka: RYS["PILKA"]["ramka"].liczby) { c, s in rysujWarstwy(c, s, RYS["PILKA"]) }
    }
}

/// 10 kolorów do kolorowania koszulki (nazwa, kolor), jak `KOLORY` w grze.
let KOLORY_KOSZULKI: [(nazwa: String, hex: String)] = RYS["KOLORY"].tablica.map { ($0[0].napis, $0[1].napis) }

/// Kolory kolejnych albumów: kremowy, potem jaśniejsze kolory z palety (bez białego) — `KOLORY_ALBUMU`.
let KOLORY_ALBUMU: [Color] = {
    func jasniej(_ hex: String) -> Color {
        var v: UInt64 = 0
        Scanner(string: String(hex.dropFirst())).scanHexInt64(&v)
        let kanaly = [(v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff].map { (255 - (255 - Double($0)) * 0.45).rounded() / 255 }
        return Color(.sRGB, red: kanaly[0], green: kanaly[1], blue: kanaly[2], opacity: 1)
    }
    return [Color(hex: "#fff6e0")] + KOLORY_KOSZULKI.filter { $0.nazwa != "bialy" }.map { jasniej($0.hex) }
}()
