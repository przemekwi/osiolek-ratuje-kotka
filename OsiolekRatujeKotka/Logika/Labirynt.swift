import Foundation

/// Kierunki w kolejności z gry: prawo, lewo, dół, góra.
let DX = [1, -1, 0, 0]
let DY = [0, 0, 1, -1]
enum Kierunek: Int, CaseIterable, Codable { case prawo = 0, lewo, dol, gora }

/// Szerokość pasa ściany względem szerokości korytarza.
let SCIANA = 0.42

/// Charakter planszy: jak często korytarz ciągnie się dalej (`nowe`) i czy woli biec poziomo czy pionowo (`bok`).
struct Charakter { let nazwa: String; let nowe: Double; let bok: Double }
let CHARAKTERY: [Charakter] = [
    Charakter(nazwa: "kretny", nowe: 1, bok: 0),
    Charakter(nazwa: "mieszany", nowe: 0.6, bok: 0),
    Charakter(nazwa: "rozgaleziony", nowe: 0.2, bok: 0),
    Charakter(nazwa: "poziomy", nowe: 0.8, bok: 0.7),
    Charakter(nazwa: "pionowy", nowe: 0.8, bok: -0.7),
]

/// Plan budowy planszy (`planPlanszy` / `DOMYSLNA` z gry).
struct Budowa {
    var charakter = "kretny"
    var nowe = 1.0
    var bok = 0.0
    var q = 0.0
    var wzrost = 1.0
    var kot = "daleko"      // "daleko" albo "zwodniczy"
    var dom = "rog"         // "rog" albo "brzeg"
    var unikaj = -1
}

/// Wynik budowy jednego labiryntu (z cechami trudności).
struct Kandydat {
    var G: [UInt8]
    var TW: Int
    var TH: Int
    var dom: Int
    var kot: Int
    var dlugosc: Int
    var slepe: Int
    var objazd: Bool
    var zwodniczy: Bool
    var korzen: [UInt8]
    var waga: Double
    var decyzje: Int
    var zwodniczosc: Double
}

struct Przeszkoda: Codable, Equatable {
    var pole = -1
    var klucz = -1
    var otwarta = true
    var znika = 0.0
}

enum TrybGry: String, Codable { case zwykly, plan }

/// Labirynt i jego budowa — przeniesione 1:1 z gry webowej (te same nazwy funkcji).
/// Plansza to siatka TW×TH: kolumny i wiersze parzyste to ściany, nieparzyste — pola. G[i] == 1 oznacza ścianę.
final class Labirynt {
    var los: Los
    var G: [UInt8] = []
    var TW = 0
    var TH = 0
    var domI = 0
    var kotekI = 0
    var wersja = 0
    /// Trudność dopasowana do dziecka (rozmiar planszy zależy od niej, nie od numeru poziomu).
    var trudnosc = 1
    var pomocZRzedu = 0
    var byly = Set<String>()
    var ostatnia = (charakter: "", rog: -1, zwodniczy: false)
    var przeszkoda = Przeszkoda()
    var trybGry: TrybGry = .zwykly
    /// Do testów: wymusza (albo zabrania) krzaczka na etapie 3.
    var wymusKrzak: Bool?

    init(los: Los = Los()) { self.los = los }

    @inline(__always) func ix(_ i: Int) -> Int { i % TW }
    @inline(__always) func iy(_ i: Int) -> Int { i / TW }
    @inline(__always) func jestPolem(_ i: Int) -> Bool { ix(i) % 2 == 1 && iy(i) % 2 == 1 }

    var zamknietyKrzak: Int { przeszkoda.otwarta ? -1 : przeszkoda.pole }

    /// Odległości od pola s. Zamknięty krzaczek działa jak ściana, dopóki osiołek nie zbierze serduszka.
    func bfs(_ s: Int, bezKrzaka: Bool = false) -> [Int] {
        let n = TW * TH
        var d = [Int](repeating: -1, count: n)
        var q = [Int](repeating: 0, count: n)
        let z = bezKrzaka ? -1 : zamknietyKrzak
        var h = 0, t = 0
        d[s] = 0; q[t] = s; t += 1
        while h < t {
            let c = q[h]; h += 1
            for k in 0..<4 {
                let m = c + DX[k] + DY[k] * TW
                if G[m] == 0 && m != z && d[m] < 0 { d[m] = d[c] + 1; q[t] = m; t += 1 }
            }
        }
        return d
    }

    func otwarte(_ i: Int) -> Int { [1, -1, TW, -TW].filter { G[i + $0] == 0 }.count }

    /// Krok po najkrótszej drodze w stronę źródła odległości d.
    func krokBlizej(_ cur: Int, _ d: [Int]) -> Int {
        for k in 0..<4 {
            let m = cur + DX[k] + DY[k] * TW
            if G[m] == 0 && d[m] == d[cur] - 1 { return m }
        }
        return cur
    }

    // MARK: Etapy gry logicznej
    /// Etap 1 (stopnie 1–2): jedna droga. Etap 2 (od 3): objazdy. Etap 3 (od 5): krzaczek z serduszkiem.
    var etap: Int { trudnosc <= 2 ? 1 : trudnosc <= 4 ? 2 : 3 }

    /// Stopnie 1–2: 4×3 pól, 3–4: 5×4, 5–6: 6×4, 7–8: 7×5, 9–10: 8×6; dalej o jedno pole co dwa stopnie.
    static func naturalny(_ n: Int) -> (Int, Int) {
        let a = 4 + (n - 1) / 2
        return (a, Int((Double(a) * 0.72).rounded()))
    }

    /// Rozmiar planszy mieszczący się w ramce (pole co najmniej 36 pt).
    static func rozmiar(_ n: Int, szer: Double, wys: Double) -> (Int, Int) {
        let (a, b) = naturalny(n)
        let dl = max(szer, wys), kr = min(szer, wys)
        let MIN = 36.0
        func maks(_ x: Double) -> Int { max(3, Int(((x / MIN - SCIANA) / (1 + SCIANA)).rounded(.down))) }
        let A = min(a, maks(dl)), B = min(b, maks(kr), A)
        return szer >= wys ? (A, B) : (B, A)
    }

    // MARK: Budowa planszy
    /// „Rosnące drzewo”: korytarz ciągnie się od ostatniego pola (jak DFS) albo odgałęzia z losowego (jak Prim).
    func drzewo(_ cw: Int, _ ch: Int, _ b: Budowa) {
        TW = cw * 2 + 1; TH = ch * 2 + 1
        G = [UInt8](repeating: 1, count: TW * TH)
        var vis = [UInt8](repeating: 0, count: cw * ch)
        var akt = [los.ri(cw * ch)]
        func pole(_ k: Int) -> Int { ((k / cw) * 2 + 1) * TW + (k % cw) * 2 + 1 }
        vis[akt[0]] = 1; G[pole(akt[0])] = 0
        while !akt.isEmpty {
            let j = los.R() < b.nowe ? akt.count - 1 : los.ri(akt.count)
            let c = akt[j], x = c % cw, y = c / cw
            var o: [(Int, Double)] = []
            var suma = 0.0
            for k in 0..<4 {
                let nx = x + DX[k], ny = y + DY[k]
                if nx >= 0 && ny >= 0 && nx < cw && ny < ch && vis[ny * cw + nx] == 0 {
                    let w = k < 2 ? 1 + b.bok : 1 - b.bok
                    o.append((k, w)); suma += w
                }
            }
            if o.isEmpty { akt.remove(at: j); continue }
            var r = los.R() * suma, k = o[o.count - 1].0
            for (kk, w) in o { r -= w; if r < 0 { k = kk; break } }
            let n = c + DX[k] + DY[k] * cw
            G[pole(c) + DX[k] + DY[k] * TW] = 0; G[pole(n)] = 0; vis[n] = 1; akt.append(n)
        }
    }

    static func rogi(_ cw: Int, _ ch: Int) -> [(Int, Int)] { [(0, 0), (cw - 1, 0), (0, ch - 1), (cw - 1, ch - 1)] }

    func miejsceDomu(_ cw: Int, _ ch: Int, _ b: Budowa) -> Int {
        var x: Int, y: Int
        if b.dom == "brzeg" {
            var brzeg: [(Int, Int)] = []
            if cw > 2 { for i in 1..<(cw - 1) { brzeg.append((i, 0)); brzeg.append((i, ch - 1)) } }
            if ch > 2 { for j in 1..<(ch - 1) { brzeg.append((0, j)); brzeg.append((cw - 1, j)) } }
            (x, y) = los.pick(brzeg)
        } else {
            let r = Labirynt.rogi(cw, ch).enumerated().filter { $0.offset != b.unikaj }.map { $0.element }
            (x, y) = los.pick(r)
        }
        return (y * 2 + 1) * TW + x * 2 + 1
    }

    /// Kotek „daleko” (z najdalszych pól) albo „blisko, a daleko” (w linii prostej blisko, drogą co najmniej 2× dalej).
    func wybierzKotka(_ dom: Int, _ d: [Int], _ pola: [Int], _ maks: Int, _ tryb: String) -> (Int, Bool) {
        if tryb == "zwodniczy" {
            func prosto(_ c: Int) -> Double { Double(abs(ix(c) - ix(dom)) + abs(iy(c) - iy(dom))) / 2 }
            let k = pola.filter { $0 != dom && Double(d[$0]) >= max(8, Double(maks) * 0.6) }
                .map { ($0, Double(d[$0]) / 2 / max(1, prosto($0))) }
                .sorted { $0.1 > $1.1 }
                .prefix(3)
                .filter { $0.1 >= 2 }
            if !k.isEmpty { return (los.pick(Array(k)).0, true) }
        }
        let prog = max(2, Int((Double(maks) * 0.9).rounded(.down)))
        return (los.pick(pola.filter { $0 != dom && d[$0] >= prog }), false)
    }

    /// Trudność planszy: ślepe odnogi przy drodze do kotka (pierwiastek z długości), rozwidlenia i zwodniczość.
    func cechy(_ dom: Int, _ kot: Int) -> (waga: Double, decyzje: Int, zwodniczosc: Double) {
        let d = bfs(dom, bezKrzaka: true)
        var droga = [UInt8](repeating: 0, count: TW * TH)
        var pola = 0, decyzje = 0
        var cur = kot
        while true {
            droga[cur] = 1
            if jestPolem(cur) {
                pola += 1
                if cur != kot && otwarte(cur) >= (cur == dom ? 2 : 3) { decyzje += 1 }
            }
            if cur == dom { break }
            cur = krokBlizej(cur, d)
        }
        var byl = [UInt8](repeating: 0, count: TW * TH)
        var waga = 0.0
        for s in 0..<(TW * TH) {
            if G[s] != 0 || droga[s] != 0 || byl[s] != 0 { continue }
            var q = [s]; byl[s] = 1
            var n = 0, styk = -1, wiele = false
            var h = 0
            while h < q.count {
                let c = q[h]; h += 1
                if jestPolem(c) { n += 1 }
                for k in 0..<4 {
                    let m = c + DX[k] + DY[k] * TW
                    if G[m] != 0 { continue }
                    if droga[m] != 0 {
                        if styk < 0 { styk = m } else if styk != m { wiele = true }
                    } else if byl[m] == 0 { byl[m] = 1; q.append(m) }
                }
            }
            if !wiele && n > 0 { waga += Double(min(n, 16)).squareRoot() }
        }
        let prosto = Double(abs(ix(kot) - ix(dom)) + abs(iy(kot) - iy(dom))) / 2
        return (waga, decyzje, Double(pola - 1) / max(1, prosto))
    }

    func wagaDrzewa(_ dom: Int) -> Double {
        let d = bfs(dom, bezKrzaka: true)
        var kot = dom
        for i in 0..<d.count where d[i] > d[kot] && jestPolem(i) { kot = i }
        return cechy(dom, kot).waga
    }

    /// Gdy ekran nie mieści większej planszy: drobne zmiany drzewa dokładają rozwidleń, aż waga dojdzie do celu.
    func doskonal(_ cw: Int, _ ch: Int, _ dom: Int, _ cel: Double) {
        var w = wagaDrzewa(dom)
        var n = 0
        while n < 600 && w < cel {
            defer { n += 1 }
            let k = los.ri(cw * ch), x = k % cw, y = k / cw, kier = los.R() < 0.5 ? 0 : 2
            if kier == 0 && x == cw - 1 || kier == 2 && y == ch - 1 { continue }
            let a = (y * 2 + 1) * TW + x * 2 + 1, otwor = a + DX[kier] + DY[kier] * TW
            if G[otwor] == 0 { continue }
            let b = otwor + DX[kier] + DY[kier] * TW, d = bfs(a, bezKrzaka: true)
            var przejscia: [Int] = []
            var c = b
            while c != a {
                let s = krokBlizej(c, d)
                if s == c { break }
                if !jestPolem(s) { przejscia.append(s) }
                c = s
            }
            if przejscia.isEmpty { continue }
            let zamkniete = los.pick(przejscia)
            G[zamkniete] = 1; G[otwor] = 0
            let nowa = wagaDrzewa(dom)
            if nowa >= w { w = nowa } else { G[zamkniete] = 0; G[otwor] = 1 }
        }
    }

    /// Pętle, kotek i objazdy na gotowym drzewie (drzewo zostaje w wyniku, żeby dało się je doskonalić).
    func dokoncz(_ cw: Int, _ ch: Int, _ petle: Double, _ drogi: Int, _ dom: Int, _ b: Budowa) -> Kandydat {
        let korzen = G
        for cy in 0..<ch {
            for cx in 0..<cw {
                let i = (cy * 2 + 1) * TW + cx * 2 + 1
                var otw = 0
                for k in 0..<4 where G[i + DX[k] + DY[k] * TW] == 0 { otw += 1 }
                if otw == 1 && los.R() < petle {
                    var o: [Int] = []
                    for k in 0..<4 {
                        let wx = cx * 2 + 1 + DX[k], wy = cy * 2 + 1 + DY[k]
                        if wx > 0 && wy > 0 && wx < TW - 1 && wy < TH - 1 && G[wy * TW + wx] != 0 { o.append(wy * TW + wx) }
                    }
                    if !o.isEmpty { G[los.pick(o)] = 0 }
                }
            }
        }
        let d = bfs(dom)
        var maks = 0
        var pola: [Int] = []
        for cy in 0..<ch {
            for cx in 0..<cw {
                let c = (cy * 2 + 1) * TW + cx * 2 + 1
                pola.append(c)
                if d[c] > maks { maks = d[c] }
            }
        }
        let (kot, zwodniczy) = wybierzKotka(dom, d, pola, maks, b.kot)
        var objazd = true
        var n = drogi
        while n > 0 { objazd = drugaDroga(dom, kot) && objazd; n -= 1 }
        var slepe = 0
        for c in pola where c != dom && c != kot && [1, -1, TW, -TW].filter({ G[c + $0] == 0 }).count == 1 { slepe += 1 }
        let ce = cechy(dom, kot)
        return Kandydat(G: G, TW: TW, TH: TH, dom: dom, kot: kot, dlugosc: bfs(dom)[kot], slepe: slepe, objazd: objazd,
                        zwodniczy: zwodniczy, korzen: korzen, waga: ce.waga, decyzje: ce.decyzje, zwodniczosc: ce.zwodniczosc)
    }

    func jedenLabirynt(_ cw: Int, _ ch: Int, _ petle: Double, _ drogi: Int? = nil, _ b: Budowa = Budowa()) -> Kandydat {
        drzewo(cw, ch, b)
        return dokoncz(cw, ch, petle, drogi ?? (cw * ch >= 30 ? 2 : 1), miejsceDomu(cw, ch, b), b)
    }

    /// Druga droga do kotka: otwiera ścianę tworzącą objazd części drogi, o podobnej długości (bez oczywistego skrótu).
    @discardableResult
    func drugaDroga(_ dom: Int, _ kot: Int) -> Bool {
        let n = TW * TH, d = bfs(dom), dk = bfs(kot), L = d[kot]
        var przy = [Int](repeating: -1, count: n)
        var q: [Int] = []
        var cur = kot
        while true {
            przy[cur] = d[cur]; q.append(cur)
            if cur == dom { break }
            cur = krokBlizej(cur, d)
        }
        var h = 0
        while h < q.count {
            let c = q[h]; h += 1
            for k in 0..<4 {
                let m = c + DX[k] + DY[k] * TW
                if G[m] == 0 && przy[m] < 0 { przy[m] = przy[c]; q.append(m) }
            }
        }
        var dobre: [Int] = [], inne: [Int] = []
        for y in 1..<(TH - 1) {
            for x in 1..<(TW - 1) {
                let w = y * TW + x
                if G[w] == 0 || (x % 2) == (y % 2) { continue }
                let (u, v) = x % 2 == 1 ? (w - TW, w + TW) : (w - 1, w + 1)
                if G[u] != 0 || G[v] != 0 || abs(przy[u] - przy[v]) < 4 { continue }
                let alt = Double(min(d[u] + dk[v], d[v] + dk[u]) + 2), Ld = Double(L)
                if alt >= Ld * 0.85 && alt <= Ld * 1.6 + 4 && abs(alt - Ld) >= 4 { dobre.append(w) } else { inne.append(w) }
            }
        }
        let w = !dobre.isEmpty ? los.pick(dobre) : !inne.isEmpty ? los.pick(inne) : -1
        if w >= 0 { G[w] = 0 }
        return w >= 0
    }

    /// Ten sam układ obrócony albo w lustrze to dla dziecka ta sama plansza: klucz to najmniejszy zapis po odbiciach.
    static func kluczUkladu(_ l: Kandydat) -> String {
        let w = l.TW, h = l.TH
        var M = [[1, 0, 0, 1], [-1, 0, 0, 1], [1, 0, 0, -1], [-1, 0, 0, -1]]
        if w == h { M += [[0, 1, 1, 0], [0, -1, 1, 0], [0, 1, -1, 0], [0, -1, -1, 0]] }
        var naj = ""
        for m in M {
            let (a, b, c, d) = (m[0], m[1], m[2], m[3])
            func p(_ i: Int) -> Int {
                let x = 2 * (i % w) - (w - 1), y = 2 * (i / w) - (h - 1)
                return ((c * x + d * y + h - 1) / 2) * w + (a * x + b * y + w - 1) / 2
            }
            var t = [UInt8](repeating: 0, count: w * h)
            for i in 0..<(w * h) { t[p(i)] = l.G[i] }
            let k = "\(p(l.dom)):\(p(l.kot)):" + String(decoding: t.map { $0 == 0 ? UInt8(ascii: "0") : UInt8(ascii: "1") }, as: UTF8.self)
            if naj.isEmpty || k < naj { naj = k }
        }
        return "\(w)x\(h):\(naj)"
    }

    /// Plan planszy rozwojowej: charakter inny niż poprzednio, pozycja trudności q, wzrost gdy ekran za mały.
    func planPlanszy(_ cw: Int, _ ch: Int) -> Budowa {
        let t = trudnosc, (a, b) = Labirynt.naturalny(t)
        let nadmiar = max(0, Double(a * b) / Double(cw * ch) - 1)
        let ch_ = los.pick(CHARAKTERY.filter { $0.nazwa != ostatnia.charakter })
        var bud = Budowa()
        bud.charakter = ch_.nazwa; bud.nowe = ch_.nowe; bud.bok = ch_.bok
        bud.q = min(1, t <= 2 ? 0.2 * Double(t) : 0.35 + 0.035 * Double(t) + (t % 2 == 1 ? 0 : 0.1))
        bud.wzrost = pow(1 + nadmiar, 0.7)
        bud.kot = t >= 5 && !ostatnia.zwodniczy && los.R() < min(0.6, 0.3 + 0.3 * nadmiar) ? "zwodniczy" : "daleko"
        bud.dom = t >= 8 && los.R() < min(0.5, 0.3 + 0.2 * nadmiar) ? "brzeg" : "rog"
        bud.unikaj = ostatnia.rog
        return bud
    }

    /// Nowy labirynt dla bieżącej trudności w ramce szer×wys (punkty ekranu).
    func nowyLabirynt(szer: Double, wys: Double) {
        przeszkoda = Przeszkoda()
        let (cw, ch) = Labirynt.rozmiar(trudnosc, szer: szer, wys: wys)
        let e = etap
        let petle = e == 1 ? 0 : max(0, 0.25 - 0.03 * Double(trudnosc - 1))
        let drogi = e == 1 ? 0 : cw * ch >= 30 ? 2 : 1
        let slepeCel = e == 1 ? 0 : min(3, 1 + Int((Double(trudnosc - 3) / 2).rounded(.down)), cw * ch / 8)
        let b = planPlanszy(cw, ch)
        func dobry(_ l: Kandydat) -> Bool { l.slepe >= slepeCel && l.objazd }
        var wybrany: Kandydat?
        var n = 0
        while n < 20 && wybrany == nil {
            var kand: [Kandydat] = []
            for _ in 0..<16 { kand.append(jedenLabirynt(cw, ch, petle, drogi, b)) }
            let dobre = kand.filter(dobry).sorted { $0.waga < $1.waga }
            var l = !dobre.isEmpty
                ? dobre[Int((b.q * Double(dobre.count - 1)).rounded())]
                : kand.reduce(kand[0]) { $1.slepe > $0.slepe ? $1 : $0 }
            // Objazdy i miejsce kotka potrafią skrócić ślepe odnogi, więc z kilku wykończeń zostaje najlepsze.
            if b.wzrost > 1 && dobry(l) {
                G = l.korzen; TW = l.TW; TH = l.TH
                doskonal(cw, ch, l.dom, wagaDrzewa(l.dom) * b.wzrost)
                let korzen = G
                for _ in 0..<8 {
                    G = korzen
                    let m = dokoncz(cw, ch, petle, drogi, l.dom, b)
                    if dobry(m) && m.waga > l.waga { l = m }
                }
            }
            let klucz = Labirynt.kluczUkladu(l)
            if !byly.contains(klucz) || n == 19 { byly.insert(klucz); wybrany = l }
            n += 1
        }
        guard let w = wybrany else { return }
        G = w.G; TW = w.TW; TH = w.TH; domI = w.dom; kotekI = w.kot; wersja += 1
        let dx = (ix(domI) - 1) / 2, dy = (iy(domI) - 1) / 2
        ostatnia = (b.charakter, Labirynt.rogi(cw, ch).firstIndex { $0.0 == dx && $0.1 == dy } ?? -1, w.zwodniczy)
        if etap == 3 && trybGry == .zwykly && (wymusKrzak ?? (los.R() < 0.5)) { ustawKrzak() }
    }

    /// Krzaczek na polu, przez które musi przejść każda droga do kotka (środkowa część drogi);
    /// serduszko-klucz osiągalne bez przechodzenia przez krzaczek, najchętniej w bocznym korytarzu.
    func ustawKrzak() {
        let d = bfs(domI, bezKrzaka: true)
        var droga: [Int] = []
        var cur = kotekI
        while cur != domI {
            if jestPolem(cur) && cur != kotekI { droga.insert(cur, at: 0) }
            let nast = krokBlizej(cur, d)
            if nast == cur { break }
            cur = nast
        }
        let naDrodze = Set(droga)
        let od = Int((Double(droga.count) * 0.3).rounded(.down)), doo = Int((Double(droga.count) * 0.7).rounded(.up))
        let kand = od < doo ? Array(droga[od..<min(doo, droga.count)]) : []
        for pole in los.tasuj(kand) {
            przeszkoda.pole = pole; przeszkoda.otwarta = false
            let dz = bfs(domI)
            if dz[kotekI] >= 0 { continue }
            var klucze: [Int] = []
            var y = 1
            while y < TH {
                var x = 1
                while x < TW { let i = y * TW + x; if dz[i] > 0 && i != domI { klucze.append(i) }; x += 2 }
                y += 2
            }
            let boczne = klucze.filter { !naDrodze.contains($0) && dz[$0] >= 4 }
            if klucze.isEmpty { continue }
            przeszkoda.klucz = los.pick(boczne.isEmpty ? klucze : boczne)
            return
        }
        przeszkoda = Przeszkoda()
    }

    /// Najkrótsza droga (same pola) od domku do celu, z domkiem na początku.
    func najkrotszaDroga(do cel: Int) -> [Int] {
        let d = bfs(domI, bezKrzaka: true)
        var wynik: [Int] = []
        var cur = cel
        while true {
            if jestPolem(cur) { wynik.insert(cur, at: 0) }
            if cur == domI { break }
            let nast = krokBlizej(cur, d)
            if nast == cur { break }
            cur = nast
        }
        return wynik
    }
}

/// Geometria planszy na ekranie: pola mają szerokość C, ściany C·SCIANA (`geometria` i `srodek` z gry).
struct Geometria: Equatable {
    let C: Double
    let X0: [Double]
    let Y0: [Double]
    var W: Double { X0.last ?? 0 }
    var H: Double { Y0.last ?? 0 }

    init(TW: Int, TH: Int, szer: Double, wys: Double) {
        let cw = Double(TW - 1) / 2, ch = Double(TH - 1) / 2
        let C = max(12, min(szer / (cw + (cw + 1) * SCIANA), wys / (ch + (ch + 1) * SCIANA)).rounded(.down))
        func roz(_ i: Int) -> Double { i % 2 == 1 ? C : (C * SCIANA).rounded() }
        var X0 = [0.0], Y0 = [0.0]
        for i in 0..<TW { X0.append(X0[i] + roz(i)) }
        for i in 0..<TH { Y0.append(Y0[i] + roz(i)) }
        self.C = C; self.X0 = X0; self.Y0 = Y0
    }

    /// Środek (także ułamkowej) kolumny albo wiersza v.
    static func srodek(_ S: [Double], _ v: Double) -> Double {
        let a = Int(v.rounded(.down)), b = min(Int(v.rounded(.up)), S.count - 2), f = v - Double(a)
        func m(_ i: Int) -> Double { (S[i] + S[i + 1]) / 2 }
        return m(a) + (m(b) - m(a)) * f
    }
    func sx(_ v: Double) -> Double { Geometria.srodek(X0, v) }
    func sy(_ v: Double) -> Double { Geometria.srodek(Y0, v) }

    /// Pole siatki pod punktem (x, y) albo nil.
    func pole(x: Double, y: Double, TW: Int, TH: Int) -> Int? {
        guard let gx = (0..<TW).first(where: { x >= X0[$0] && x < X0[$0 + 1] }),
              let gy = (0..<TH).first(where: { y >= Y0[$0] && y < Y0[$0 + 1] }) else { return nil }
        return gy * TW + gx
    }
}
