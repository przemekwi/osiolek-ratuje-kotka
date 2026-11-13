import SwiftUI

// MARK: - Dane rysunków (Rysunki.json wyeksportowane z gry webowej)

/// Wartość z pliku JSON z danymi gry: liczba, napis, tablica, obiekt albo brak.
indirect enum J {
    case liczba(Double), napis(String), tablica([J]), obiekt([String: J]), logiczna(Bool), brak

    init(_ any: Any?) {
        switch any {
        case let n as NSNumber:
            self = CFGetTypeID(n) == CFBooleanGetTypeID() ? .logiczna(n.boolValue) : .liczba(n.doubleValue)
        case let s as String: self = .napis(s)
        case let a as [Any]: self = .tablica(a.map { J($0) })
        case let o as [String: Any]: self = .obiekt(o.mapValues { J($0) })
        default: self = .brak
        }
    }

    static func wczytaj(_ nazwa: String) -> J {
        guard let url = Bundle.main.url(forResource: nazwa, withExtension: "json"),
              let dane = try? Data(contentsOf: url),
              let any = try? JSONSerialization.jsonObject(with: dane) else { return .brak }
        return J(any)
    }

    subscript(_ klucz: String) -> J { if case .obiekt(let o) = self { return o[klucz] ?? .brak }; return .brak }
    subscript(_ i: Int) -> J { if case .tablica(let a) = self, i >= 0, i < a.count { return a[i] }; return .brak }

    var tablica: [J] { if case .tablica(let a) = self { return a }; return [] }
    var liczba: Double { if case .liczba(let n) = self { return n }; return 0 }
    var napis: String { if case .napis(let s) = self { return s }; return "" }
    var logiczna: Bool { if case .logiczna(let b) = self { return b }; return false }
    var istnieje: Bool { if case .brak = self { return false }; return true }
    var liczby: [Double] { tablica.map(\.liczba) }
    /// Tablica punktów [[x, y], …].
    var punkty: [CGPoint] { tablica.map { CGPoint(x: $0[0].liczba, y: $0[1].liczba) } }
    var klucze: [String] { if case .obiekt(let o) = self { return Array(o.keys) }; return [] }
}

/// Wszystkie rysunki dziecka zapisane jako punkty (OSIOLEK, KOTEK, SCENA, …).
let RYS = J.wczytaj("Rysunki")

extension Color {
    /// Kolor z zapisu „#rrggbb” albo „#rrggbbaa”, jak w grze webowej.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((v >> 24) & 0xff) / 255; g = Double((v >> 16) & 0xff) / 255
            b = Double((v >> 8) & 0xff) / 255; a = Double(v & 0xff) / 255
        } else {
            r = Double((v >> 16) & 0xff) / 255; g = Double((v >> 8) & 0xff) / 255; b = Double(v & 0xff) / 255; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Płótno

/// Nakładka na `GraphicsContext` z API płótna HTML (beginPath, bezierCurveTo, save/restore…),
/// żeby kod rysunków dało się przenieść z gry webowej linijka po linijce.
final class Plotno {
    var g: GraphicsContext
    var fillStyle: Color = .black
    var strokeStyle: Color = .black
    var lineWidth: CGFloat = 1
    var lineCap: CGLineCap = .butt
    var lineJoin: CGLineJoin = .miter
    /// Kreska przerywana (`setLineDash`); pusta tablica — ciągła.
    var lineDash: [CGFloat] = []
    /// Najcieńsza kreska na ekranie (w punktach), jak `minKreska` w grze.
    var minKreska: Double = 2
    private var sciezka = Path()
    private var stos: [(GraphicsContext, Color, Color, CGFloat, CGLineCap, CGLineJoin)] = []

    init(_ g: GraphicsContext) { self.g = g }

    var globalAlpha: Double {
        get { g.opacity }
        set { g.opacity = newValue }
    }

    func save() { stos.append((g, fillStyle, strokeStyle, lineWidth, lineCap, lineJoin)) }
    func restore() {
        guard let s = stos.popLast() else { return }
        (g, fillStyle, strokeStyle, lineWidth, lineCap, lineJoin) = s
    }
    func translate(_ x: Double, _ y: Double) { g.translateBy(x: x, y: y) }
    func scale(_ x: Double, _ y: Double) { g.scaleBy(x: x, y: y) }
    func rotate(_ a: Double) { g.rotate(by: .radians(a)) }
    func clip(_ x: Double, _ y: Double, _ w: Double, _ h: Double) { g.clip(to: Path(CGRect(x: x, y: y, width: w, height: h))) }

    func beginPath() { sciezka = Path() }
    func moveTo(_ x: Double, _ y: Double) { sciezka.move(to: CGPoint(x: x, y: y)) }
    func lineTo(_ x: Double, _ y: Double) {
        if sciezka.isEmpty { sciezka.move(to: CGPoint(x: x, y: y)) } else { sciezka.addLine(to: CGPoint(x: x, y: y)) }
    }
    func bezierCurveTo(_ c1x: Double, _ c1y: Double, _ c2x: Double, _ c2y: Double, _ x: Double, _ y: Double) {
        sciezka.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: c1x, y: c1y), control2: CGPoint(x: c2x, y: c2y))
    }
    func quadraticCurveTo(_ cx: Double, _ cy: Double, _ x: Double, _ y: Double) {
        sciezka.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    func closePath() { sciezka.closeSubpath() }
    func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) { sciezka.addRect(CGRect(x: x, y: y, width: w, height: h)) }
    func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ obrot: Double = 0) {
        let t = CGAffineTransform(translationX: x, y: y).rotated(by: obrot)
        sciezka.addEllipse(in: CGRect(x: -rx, y: -ry, width: 2 * rx, height: 2 * ry), transform: t)
    }
    func arc(_ x: Double, _ y: Double, _ r: Double) { ellipse(x, y, r, r) }

    func fill(evenOdd: Bool = false) { g.fill(sciezka, with: .color(fillStyle), style: FillStyle(eoFill: evenOdd)) }
    func stroke() {
        g.stroke(sciezka, with: .color(strokeStyle),
                 style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap, lineJoin: lineJoin, dash: lineDash))
    }
    func fillRect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) {
        g.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(fillStyle))
    }
    func drawImage(_ obraz: Image, _ x: Double, _ y: Double, _ w: Double, _ h: Double) {
        g.draw(obraz, in: CGRect(x: x, y: y, width: w, height: h))
    }
    /// Rysowanie w osobnej warstwie (np. z filtrem), jak rysowanie na pomocniczym płótnie w grze.
    func warstwa(filtry: [GraphicsContext.Filter] = [], _ rysuj: (Plotno) -> Void) {
        let min = minKreska, f = fillStyle, s = strokeStyle, lw = lineWidth
        g.drawLayer { l in
            for filtr in filtry { l.addFilter(filtr) }
            let p = Plotno(l)
            p.minKreska = min; p.fillStyle = f; p.strokeStyle = s; p.lineWidth = lw
            rysuj(p)
        }
    }
}

// MARK: - Pióro dziecka (te same funkcje co w grze)

let TAU = Double.pi * 2
let TUSZ = Color(hex: RYS["TUSZ"].napis)
/// Kolory postaci i domku (te same w obu motywach, jak naklejki).
let K: [String: Color] = {
    var k: [String: Color] = [:]
    for n in RYS["K"].klucze { k[n] = Color(hex: RYS["K"][n].napis) }
    return k
}()
func kolorK(_ n: String) -> Color { K[n] ?? .gray }

/// Kreska prowadzi gładko przez punkty, jak długopis (krzywa Catmulla-Roma zamieniona na krzywe Béziera).
func sciezka(_ c: Plotno, _ pts: [CGPoint], _ zamknij: Bool) {
    let n = pts.count
    guard n > 0 else { return }
    func P(_ i: Int) -> CGPoint { pts[zamknij ? ((i % n) + n) % n : max(0, min(n - 1, i))] }
    c.beginPath(); c.moveTo(pts[0].x, pts[0].y)
    for i in 0..<(zamknij ? n : n - 1) {
        let p0 = P(i - 1), p1 = P(i), p2 = P(i + 1), p3 = P(i + 2)
        c.bezierCurveTo(p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6,
                        p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6, p2.x, p2.y)
    }
    if zamknij { c.closePath() }
}

/// Owal [x, y, rx, ry, kąt].
func owal(_ c: Plotno, _ o: [Double], _ wypelnij: Color?) {
    c.beginPath(); c.ellipse(o[0], o[1], o[2], o[3], o.count > 4 ? o[4] : 0)
    if let w = wypelnij { c.fillStyle = w; c.fill() }
    c.stroke()
}
func ksztalt(_ c: Plotno, _ pts: [CGPoint], _ wypelnij: Color?) {
    sciezka(c, pts, true)
    if let w = wypelnij { c.fillStyle = w; c.fill() }
    c.stroke()
}
func linia(_ c: Plotno, _ pts: [CGPoint]) { sciezka(c, pts, false); c.stroke() }

/// Grubość kreski na ekranie nie spada poniżej ok. 2 pt, jak długopis na małym rysunku.
func piorko(_ c: Plotno, _ s: Double, _ grubosc: Double = 6, _ minPx: Double = 0) {
    c.strokeStyle = TUSZ
    c.lineWidth = max(grubosc == 0 ? 6 : grubosc, (minPx == 0 ? c.minKreska : minPx) / s)
    c.lineCap = .round; c.lineJoin = .round
}

/// Wpisuje rysunek w prostokąt (x, y, w, h): cały widoczny, wyśrodkowany, stoi na dolnej krawędzi.
func wpisz(_ c: Plotno, _ ramka: [Double], _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ rysuj: (Plotno, Double) -> Void) {
    let rx = ramka[0], ry = ramka[1], rw = ramka[2], rh = ramka[3], s = min(w / rw, h / rh)
    c.save(); c.translate(x + (w - rw * s) / 2, y + h - rh * s); c.scale(s, s); c.translate(-rx, -ry)
    rysuj(c, s)
    c.restore()
}
