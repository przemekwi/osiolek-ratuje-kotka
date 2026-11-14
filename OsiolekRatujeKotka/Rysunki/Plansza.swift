import SwiftUI
import UIKit

/// Kolory planszy dla motywu (PALETA z gry).
struct Paleta {
    let ciemna: Bool
    private let d: J
    init(ciemna: Bool) { self.ciemna = ciemna; d = RYS["PALETA"][ciemna ? "dark" : "light"] }
    func k(_ n: String) -> Color { Color(hex: d[n].napis) }
    var podloze: Color { k("podloze") }
    var znaczki: Color { k("znaczki") }
    var obrys: Color { k("obrys") }
    var kamien: Color { k("kamien") }
    var lapka: Color { k("lapka") }
}

// MARK: - Tło: ściany i podłoże według rysunku dziecka
// Ściana to pas: linia z obu stron, a w środku jeden z czterech wzorów (pasy, krata, kamienie, cegły).
// Podłoże: rzadkie kreseczki, „L” i „v”.

private func kreska(_ c: Plotno, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ drg: Double, _ i: Double, _ w: Int) {
    let mx = (x0 + x1) / 2 + (losPola(i, 7, wersja: w) - 0.5) * drg, my = (y0 + y1) / 2 + (losPola(i, 8, wersja: w) - 0.5) * drg
    c.beginPath(); c.moveTo(x0, y0); c.quadraticCurveTo(mx, my, x1, y1); c.stroke()
}

private func stylSciany(_ lab: Labirynt, _ i: Int) -> String {
    ["pasy", "krata", "kamienie", "cegly"][Int(losPola((lab.iy(i) >> 2) * 97 + (lab.ix(i) >> 2), 1, wersja: lab.wersja) * 4)]
}

private func wzorSciany(_ c: Plotno, _ lab: Labirynt, _ i: Int, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ C: Double, _ P_: Paleta) {
    let pion = h > w, L = pion ? h : w, P = pion ? w : h, styl = stylSciany(lab, i), W = lab.wersja
    func los(_ s: Double) -> Double { losPola(Double(i), s, wersja: W) }
    c.fillStyle = P_.k(styl); c.fillRect(x, y, w, h)
    func pt(_ a: Double, _ b: Double) -> (Double, Double) { pion ? (x + b, y + a) : (x + a, y + b) }
    func lin(_ a0: Double, _ b0: Double, _ a1: Double, _ b1: Double, _ k: Int) {
        let p = pt(a0, b0), q = pt(a1, b1)
        kreska(c, p.0, p.1, q.0, q.1, C * 0.05, Double(i * 31 + k), W)
    }
    if w == h && !pion { return }
    if styl == "pasy" {
        lin(0, P * 0.5, L, P * 0.5, 0)
        let n = max(1, Int((L / (P * 0.8)).rounded()))
        for k in 0..<n {
            let a = (Double(k) + 0.3 + los(Double(k + 10)) * 0.4) * L / Double(n)
            lin(a, -P * 0.1, a + (los(Double(k + 20)) - 0.5) * P * 0.6, P * (1.05 + los(Double(k + 30)) * 0.3), k + 1)
        }
    } else if styl == "krata" {
        lin(0, P * 0.35, L, P * 0.4, 0); lin(0, P * 0.68, L, P * 0.62, 1)
        let n = max(2, Int((L / (P * 0.6)).rounded()))
        for k in 0..<n {
            let a = (Double(k) + los(Double(k + 10))) * L / Double(n), s = (k % 2 == 1 ? 1 : -1) * P * 0.7
            lin(a, 0, a + s, P, k + 2)
        }
    } else if styl == "kamienie" {
        let rzedy = P > C * 0.3 && los(3) < 0.5 ? 2 : 1
        for r in 0..<rzedy {
            var a = 0.0
            let rr = Double(r)
            while a < L - P * 0.2 {
                let d = min(L - a, P * (0.55 + los(a * 7 + rr) * 0.45)), b0 = rr * P / Double(rzedy), b1 = (rr + 1) * P / Double(rzedy)
                let m = P * 0.07, z = P * 0.12
                let uv: [(Double, Double)] = [(a + m + z, b0 + m), (a + d - m - z, b0 + m), (a + d - m, b0 + m + z), (a + d - m, b1 - m - z),
                                              (a + d - m - z, b1 - m), (a + m + z, b1 - m), (a + m, b1 - m - z), (a + m, b0 + m + z)]
                let pts = uv.enumerated().map { k, p -> CGPoint in
                    let q = pt(p.0 + (los(a + Double(k * 13) + rr) - 0.5) * m, p.1 + (los(a + Double(k * 17) + rr) - 0.5) * m)
                    return CGPoint(x: q.0, y: q.1)
                }
                sciezka(c, pts, true); c.fillStyle = P_.kamien; c.fill(); c.stroke()
                a += d
            }
        }
    } else {
        let waski = P < C * 0.3
        if waski { lin(0, P * 0.25, L, P * 0.25, 0); lin(0, P * 0.75, L, P * 0.75, 1) }
        let n = max(1, Int((L / (waski ? P * 1.2 : P * 0.9)).rounded()))
        for k in 1...n {
            let a = Double(k) * L / Double(n + 1) + (los(Double(k)) - 0.5) * P * 0.2
            lin(a, waski ? P * 0.25 : 0, a + (los(Double(k + 5)) - 0.5) * P * 0.3, waski ? P * 0.75 : P, k + 2)
        }
    }
}

private func znaczekPodloza(_ c: Plotno, _ x: Double, _ y: Double, _ d: Double, _ i: Int, _ k: Int, _ w: Int) {
    let rodzaj = losPola(i, 40 + k, wersja: w), kat = (losPola(i, 50 + k, wersja: w) - 0.5) * 1.2
    c.save(); c.translate(x, y); c.rotate(kat); c.beginPath()
    if rodzaj < 0.5 { c.moveTo(0, -d / 2); c.lineTo(0, d / 2) }
    else if rodzaj < 0.75 { c.moveTo(-d * 0.15, -d / 2); c.lineTo(-d * 0.15, d / 2); c.lineTo(d * 0.35, d / 2) }
    else { c.moveTo(-d * 0.35, -d * 0.1); c.lineTo(0, d * 0.35); c.lineTo(d * 0.4, -d * 0.35) }
    c.stroke(); c.restore()
}

/// Nieruchoma część planszy: podłoże, ściany i domek (`rysujTlo` z gry).
func rysujTlo(_ c: Plotno, _ lab: Labirynt, _ S: Geometria, _ P_: Paleta) {
    let TW = lab.TW, TH = lab.TH, G = lab.G, W = lab.wersja
    c.fillStyle = P_.podloze; c.fillRect(0, 0, S.W, S.H)
    c.lineCap = .round; c.lineJoin = .round; c.lineWidth = max(1.5, S.C * 0.022)
    for y in 0..<TH {
        for x in 0..<TW {
            let i = y * TW + x, x0 = S.X0[x], y0 = S.Y0[y], w = S.X0[x + 1] - x0, h = S.Y0[y + 1] - y0
            if G[i] != 0 {
                c.strokeStyle = P_.obrys
                c.save(); c.clip(x0, y0, w, h); wzorSciany(c, lab, i, x0, y0, w, h, S.C, P_); c.restore()
            } else if i != lab.domI {
                c.strokeStyle = P_.znaczki
                let n = x % 2 == 1 && y % 2 == 1 ? 1 + (losPola(i, 2, wersja: W) < 0.35 ? 1 : 0) : (losPola(i, 2, wersja: W) < 0.4 ? 1 : 0)
                for k in 0..<n {
                    znaczekPodloza(c, x0 + w * (0.2 + losPola(i, 60 + k, wersja: W) * 0.6), y0 + h * (0.2 + losPola(i, 70 + k, wersja: W) * 0.6),
                                   S.C * 0.12, i, k, W)
                }
            }
        }
    }
    c.strokeStyle = P_.obrys
    let p = c.lineWidth / 2
    for y in 0..<TH {
        for x in 0..<TW {
            let i = y * TW + x
            if G[i] == 0 { continue }
            let x0 = S.X0[x], y0 = S.Y0[y], x1 = S.X0[x + 1], y1 = S.Y0[y + 1], dr = S.C * 0.04, i4 = Double(i * 4)
            if x == 0 { kreska(c, x0 + p, y0, x0 + p, y1, dr, i4, W) } else if G[i - 1] == 0 { kreska(c, x0, y0, x0, y1, dr, i4, W) }
            if x == TW - 1 { kreska(c, x1 - p, y0, x1 - p, y1, dr, i4 + 1, W) } else if G[i + 1] == 0 { kreska(c, x1, y0, x1, y1, dr, i4 + 1, W) }
            if y == 0 { kreska(c, x0, y0 + p, x1, y0 + p, dr, i4 + 2, W) } else if G[i - TW] == 0 { kreska(c, x0, y0, x1, y0, dr, i4 + 2, W) }
            if y == TH - 1 { kreska(c, x0, y1 - p, x1, y1 - p, dr, i4 + 3, W) } else if G[i + TW] == 0 { kreska(c, x0, y1, x1, y1, dr, i4 + 3, W) }
        }
    }
    // Domek z drzewkiem mieści się w jednym polu labiryntu.
    let dx0 = S.X0[lab.ix(lab.domI)], dy0 = S.Y0[lab.iy(lab.domI)], m = S.C * 0.04, dw = S.C - 2 * m
    zObwodka(c, dx0 + m, dy0 + m, dw, dw, kolor: P_.ciemna ? Obwodka.ciemny : nil) { cc in
        wpisz(cc, DOMEK_RAMKA, dx0 + m, dy0 + m, dw, dw) { c2, s in rysujScene(c2, s, bezNieba: true) }
    }
}

/// Gotowe postacie z obwódką trzymane jako obrazki (`duszki` z gry): obwódka to 12 kopii sylwetki, więc rysowanie
/// jej w każdej klatce zabierało czas i animacja gubiła klatki. Obrazek powstaje od nowa tylko przy zmianie
/// rozmiaru, motywu albo koszulki.
final class Duszki {
    static let wspolne = Duszki()
    private var pamiec: [String: CGImage] = [:]

    func obraz(_ klucz: String, w: Double, h: Double, m: Double, rysuj: @escaping (Plotno) -> Void) -> CGImage? {
        if let o = pamiec[klucz] { return o }
        var wynik: CGImage?
        let skala = max(1, min(3, UITraitCollection.current.displayScale))
        // ImageRenderer działa w wątku głównym, a Canvas rysuje się właśnie w nim.
        MainActor.assumeIsolated {
            let widok = Canvas { g, _ in rysuj(Plotno(g)) }.frame(width: w + 2 * m, height: h + 2 * m)
            let r = ImageRenderer(content: widok)
            r.scale = skala
            wynik = r.cgImage
        }
        if pamiec.count > 48 { pamiec.removeAll() }
        if let wynik { pamiec[klucz] = wynik }
        return wynik
    }
}

/// Postać jak naklejka w prostokącie (x, y, w, h); obwódka zależy od postaci i motywu (`postac` z gry).
/// `id` rozróżnia postacie w pamięci duszków (np. osiołek w innej koszulce to inny obrazek).
func postac(_ c: Plotno, _ id: String, osiolek: Bool = false, _ x: Double, _ y: Double, _ w: Double, _ h: Double, ciemny: Bool,
            _ rysuj: @escaping (Plotno, Double, Double, Double, Double) -> Void) {
    let kolor: Color? = osiolek ? Obwodka.osiolek : ciemny ? Obwodka.ciemny : nil
    let m = (min(w, h) * 0.12).rounded(.up) + 2
    let klucz = "\(id)|\(Int(w * 10))|\(Int(h * 10))|\(osiolek ? "o" : ciemny ? "c" : "j")"
    if let obraz = Duszki.wspolne.obraz(klucz, w: w, h: h, m: m, rysuj: { cc in
        zObwodka(cc, m, m, w, h, kolor: kolor) { c2 in rysuj(c2, m, m, w, h) }
    }) {
        c.drawImage(Image(decorative: obraz, scale: max(1, min(3, UITraitCollection.current.displayScale))), x - m, y - m, w + 2 * m, h + 2 * m)
    } else {
        zObwodka(c, x, y, w, h, kolor: kolor) { cc in rysuj(cc, x, y, w, h) }
    }
}

/// Ruchoma część planszy, rysowana co klatkę (`rysujPlansze` z gry).
func rysujPlansze(_ c: Plotno, _ gra: Rozgrywka, _ S: Geometria, _ P_: Paleta, t: Double, koszulka: Koszulka?) {
    let lab = gra.lab, C = S.C, ciemny = P_.ciemna, ruch = !gra.ograniczonyRuch
    func sx(_ v: Double) -> Double { S.sx(v) }
    func sy(_ v: Double) -> Double { S.sy(v) }
    for s in gra.slady { lapka(c, sx(Double(lab.ix(s.i))), sy(Double(lab.iy(s.i))), C * 0.13, s.k, kolorK("lapka")) }
    for pr in lab.przeszkody where pr.pole >= 0 {
        // Serduszko pulsuje skalą płótna, nie rozmiarem postaci.
        if !pr.otwarta {
            let f = ruch ? 0.92 + 0.08 * sin(t * 4) : 1
            c.save(); c.translate(sx(Double(lab.ix(pr.klucz))), sy(Double(lab.iy(pr.klucz)))); c.scale(f, f)
            postac(c, "klucz", -C * 0.36, -C * 0.36, C * 0.72, C * 0.72, ciemny: ciemny) { c2, x, y, w, h in wpisz(c2, SERCE_RAMKA, x, y, w, h, rysujSerce) }
            c.restore()
        }
        if !pr.otwarta || pr.znika > 0 {
            c.save(); c.globalAlpha = pr.otwarta ? pr.znika : 1
            postac(c, "krzak", sx(Double(lab.ix(pr.pole))) - C * 0.42, sy(Double(lab.iy(pr.pole))) - C * 0.5, C * 0.84, C, ciemny: ciemny) { c2, x, y, w, h in
                wpisz(c2, KRZAK_RAMKA, x, y, w, h, rysujKrzak)
            }
            c.restore()
        }
    }
    let p = gra.przedmiot
    for i in gra.serca {
        postac(c, "przedmiot-\(p.rawValue)", sx(Double(lab.ix(i))) - C * 0.3, sy(Double(lab.iy(i))) - C * 0.3, C * 0.6, C * 0.6, ciemny: ciemny) { c2, x, y, w, h in
            wpisz(c2, ramkaPrzedmiotu(p), x, y, w, h) { c3, s in rysujPrzedmiot(c3, s, p, kolor: true) }
        }
    }
    // W czasie radości kotek jest rysowany przed osiołkiem (stoją na jednym polu) i nie wyskakuje poza planszę.
    let r = gra.radosc, kx = sx(gra.kot.x) - C * 0.55, ky = sy(gra.kot.y) - C * 0.42
    let R_ = gra.radoscPelna > 0 ? gra.radoscPelna : Rozgrywka.RADOSC_S
    let skok = r > 0 && ruch ? min(ky, abs(sin((R_ - r) / Rozgrywka.RADOSC_S * .pi * 3)) * C * 0.24 * (0.4 + 0.6 * r / R_)) : 0
    if let droga = gra.droga, gra.drogaZostalo > 0 {
        for (n, l) in droga.enumerated() {
            let f = ruch ? 0.85 + 0.15 * sin(t * 6 - Double(n) * 0.7) : 1
            lapka(c, sx(Double(lab.ix(l.i))), sy(Double(lab.iy(l.i))), C * 0.2 * f, l.kat, P_.lapka)
        }
    }
    // Plan robota: niebieskie łapki (ruch w ścianę nie ma łapek), koniec każdego ruchu większy, koniec planu największy.
    if lab.trybGry == .plan {
        for l in gra.lapkiPlanu() { lapka(c, sx(Double(lab.ix(l.i))), sy(Double(lab.iy(l.i))), C * l.r, l.kat, kolorK("plan")) }
    }
    if r <= 0 { postac(c, "kotek", kx, ky, C * 1.1, C * 0.82, ciemny: ciemny) { c2, x, y, w, h in rysujKotka(c2, x, y, w, h) } }
    let drgnij = gra.bum > 0 ? sin(gra.bum * 60) * C * 0.05 : 0
    let podskok = gra.osiol.cel >= 0 && ruch ? abs(sin(t * 14)) * C * 0.06 : 0
    // Na małych polach (duża plansza) osiołek jest trochę większy niż pole, żeby nie zginął w labiryncie.
    let f = min(1.35, max(1, 26 / C))
    var idOsiolka = "osiolek"
    if let k = koszulka { idOsiolka += "-\(k.indeks)-" + (k.kolor ?? "") }
    postac(c, idOsiolka, osiolek: true, sx(gra.osiol.x) - C * 0.5 * f + drgnij, sy(gra.osiol.y) - C * (0.5 + 0.05 * f) * f + C * 0.5 * (f - 1) - podskok,
           C * f, C * 1.05 * f, ciemny: ciemny) { c2, x, y, w, h in rysujOsiolka(c2, x, y, w, h, koszulka) }
    if r > 0 { postac(c, "kotek", kx, ky - skok, C * 1.1, C * 0.82, ciemny: ciemny) { c2, x, y, w, h in rysujKotka(c2, x, y, w, h) } }
}
