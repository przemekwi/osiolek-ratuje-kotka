import Foundation

/// Coś, co chodzi po planszy płynnie: pole, położenie ułamkowe (kolumna/wiersz siatki) i pole docelowe.
struct Ruchomy: Codable, Equatable {
    var pole = 0
    var x = 0.0
    var y = 0.0
    var cel = -1
}

enum Faza: String, Codable { case szukaj, prowadz, koniec }

/// Rzeczy do zebrania z rysunków dziecka (1–3 na planszy, od etapu 2).
enum Przedmiot: String, CaseIterable, Codable { case serce, grzybek, pilka, trawa }

/// Ślad łapki kotka na polu (kąt obrotu k).
struct Slad: Codable, Equatable { var i: Int; var k: Double }

/// Zdarzenia dla dźwięku, wibracji i komunikatów VoiceOver.
enum Zdarzenie: Equatable {
    case bum(krzak: Bool)
    case krokRuchu
    case serce
    case radosc
    case krzakZnika
    case kotekZnaleziony
    case wygrana
    /// Robot mówi coś nowego (tryb „Zaplanuj drogę z robotem”).
    case robot
}


/// Przebieg poziomu — przeniesiony 1:1 z obiektu `gra` i funkcji `idz`, `przesun`, `krokAnimacji`, `wygrana`.
final class Rozgrywka {
    let lab: Labirynt
    var poziom = 1
    var faza: Faza = .szukaj
    var osiol = Ruchomy()
    var kot = Ruchomy()
    /// Kierunek, w który osiołek już uderzył (żeby nie dudnić co klatkę).
    var oparty: Int?
    var kroki = 0
    var czas = 0.0
    var start = false
    var pauza = false
    var podpowiedzi = 0
    var bum = 0.0
    var slady: [Slad] = []
    var radosc = 0.0
    var radoscPelna = 0.0
    var trasa: [Int] = []
    var trasaKot = 0
    var serca: [Int] = []
    var sercaN = 0
    var zebrane = 0
    var przedmiot: Przedmiot = .serce
    /// Podpowiedź stopniowana (Podpowiedz.swift) i łapki aktualnie pokazanej drogi.
    var podp = StanPodp()
    var droga: [LapkaPodp]?
    var drogaZostalo = 0.0
    /// Najwyższy stopień podpowiedzi użyty na poziomie.
    var podpMaks: Int { podp.maks }
    var ograniczonyRuch = false
    /// Tryb „Zaplanuj drogę z robotem” (Plan.swift): ułożony plan i komunikat robota.
    var plan = StanPlanu()
    var robotMowi = KomunikatRobota(k: "robotStart")

    /// Trzymane strzałki: klawisz, przycisk albo palec. Liczy się ostatnio wciśnięta.
    private(set) var trzymane: [(zrodlo: String, kier: Int?)] = []
    /// Palec na planszy w punktach planszy (do kierunku palca).
    var palec: (x: Double, y: Double)?
    var geo: Geometria?

    var naZdarzenie: ((Zdarzenie) -> Void)?

    /// Radość kotka: trzy podskoki po spotkaniu z osiołkiem.
    static let RADOSC_S = 1.2
    static let BLADZENIE = 2.0

    init(lab: Labirynt = Labirynt()) { self.lab = lab }

    private var TW: Int { lab.TW }
    private func ix(_ i: Int) -> Int { lab.ix(i) }
    private func iy(_ i: Int) -> Int { lab.iy(i) }

    var wGrze: Bool { !pauza && (faza == .szukaj || faza == .prowadz) }

    // MARK: Poziom
    func zacznijPoziom(szer: Double, wys: Double) {
        lab.nowyLabirynt(szer: szer, wys: wys)
        trzymane.removeAll()
        let d = lab.domI, k = lab.kotekI
        faza = .szukaj
        osiol = Ruchomy(pole: d, x: Double(ix(d)), y: Double(iy(d)), cel: -1)
        kot = Ruchomy(pole: k, x: Double(ix(k)), y: Double(iy(k)), cel: -1)
        oparty = nil; kroki = 0; czas = 0; start = false; podpowiedzi = 0; bum = 0
        slady = []; pauza = false; radosc = 0; trasa = [d]; trasaKot = 0; droga = nil; drogaZostalo = 0
        serca = losujSerca(); sercaN = serca.count; zebrane = 0
        let krzak = !lab.przeszkody.isEmpty
        przedmiot = lab.los.pick(Przedmiot.allCases.filter { $0 != przedmiot && !($0 == .serce && krzak) })
        geo = nil
        planOdNowa(); plan.ile = 0
        podpStart()
        if lab.trybGry == .plan { mowRobot("robotStart") }
    }

    func losujSerca() -> [Int] {
        if lab.etap == 1 { return [] }
        var pola: [Int] = []
        var y = 1
        while y < lab.TH {
            var x = 1
            while x < TW {
                let i = y * TW + x
                if i != lab.domI && i != lab.kotekI && !lab.przeszkody.contains(where: { $0.pole == i || $0.klucz == i }) { pola.append(i) }
                x += 2
            }
            y += 2
        }
        let n = min(3, max(1, pola.count / 6))
        var s: [Int] = []
        while s.count < n && s.count < pola.count {
            let i = lab.los.pick(pola)
            if !s.contains(i) { s.append(i) }
        }
        return s
    }

    // MARK: Sterowanie
    /// Osiołek idzie, dopóki dziecko trzyma strzałkę (klawisz, przycisk albo palec), i staje po puszczeniu.
    func trzymaj(_ zrodlo: String, _ kier: Int?) {
        trzymane.removeAll { $0.zrodlo == zrodlo }
        trzymane.append((zrodlo, kier))
        oparty = nil
        if osiol.cel < 0 { krok() }
    }

    func pusc(_ zrodlo: String) { trzymane.removeAll { $0.zrodlo == zrodlo } }
    func puscWszystko() { trzymane.removeAll(); palec = nil }

    func kierunekPalca() -> Int? {
        guard let p = palec, let g = geo else { return nil }
        let dx = p.x - g.sx(osiol.x), dy = p.y - g.sy(osiol.y)
        if hypot(dx, dy) < g.C * 0.5 { return nil }
        return abs(dx) > abs(dy) ? (dx > 0 ? 0 : 1) : (dy > 0 ? 2 : 3)
    }

    func kierunek() -> Int? {
        guard let ost = trzymane.last else { return nil }
        return ost.zrodlo == "palec" ? kierunekPalca() : ost.kier
    }

    func krok() {
        guard wGrze else { return }
        if lab.trybGry == .plan { krokPlanu(); return }
        if let k = kierunek() { idz(k) }
    }

    func idz(_ k: Int) {
        let krok = DX[k] + DY[k] * TW
        let nx = osiol.pole + krok
        let z = lab.zamkniete
        let krzak = z.contains(nx) || z.contains(nx + krok)
        if lab.G[nx] != 0 || krzak {
            if oparty != k {
                bum = ograniczonyRuch ? 0 : 0.25
                oparty = k
                naZdarzenie?(.bum(krzak: krzak))
            }
            return
        }
        oparty = nil; start = true; osiol.cel = nx
        // Kotek idzie śladem osiołka: na pole, z którego osiołek właśnie schodzi.
        if faza == .prowadz && kot.pole != osiol.pole {
            if kot.cel >= 0 { kot.pole = kot.cel; kot.x = Double(ix(kot.cel)); kot.y = Double(iy(kot.cel)) }
            kot.cel = osiol.pole
        }
    }

    private func szer(_ i: Int) -> Double { i % 2 == 1 ? 1 : SCIANA }

    /// Ruch o jedną klatkę; prędkość w polach na sekundę, wolniej na wąskich pasach ścian.
    func przesun(_ o: inout Ruchomy, _ dt: Double) -> Bool {
        let tx = Double(ix(o.cel)), ty = Double(iy(o.cel)), dx = tx - o.x, dy = ty - o.y, odl = hypot(dx, dy)
        let a = dx != 0 ? ix(o.pole) : iy(o.pole), b = dx != 0 ? ix(o.cel) : iy(o.cel)
        let v = 3.2 * dt / ((szer(a) + szer(b)) / 2)
        if odl <= v { o.x = tx; o.y = ty; o.pole = o.cel; o.cel = -1; return true }
        o.x += dx / odl * v; o.y += dy / odl * v
        return false
    }

    func krokAnimacji(_ dt: Double) {
        if kot.cel >= 0 && przesun(&kot, dt) {
            let p = kot.pole
            if lab.jestPolem(p) {
                slady.append(Slad(i: p, k: lab.los.R() * 0.6 - 0.3))
                if slady.count > 30 { slady.removeFirst() }
            }
        }
        if osiol.cel < 0 { krok(); return }
        if !przesun(&osiol, dt) { return }
        kroki += 1
        let p = osiol.pole
        if lab.jestPolem(p) { naZdarzenie?(.krokRuchu); trasa.append(p) }
        if let j = lab.przeszkody.firstIndex(where: { $0.klucz == p && !$0.otwarta }) {
            lab.przeszkody[j].otwarta = true; lab.przeszkody[j].znika = 1
            naZdarzenie?(.krzakZnika)
        }
        if let s = serca.firstIndex(of: p) {
            serca.remove(at: s); zebrane += 1
            naZdarzenie?(.serce)
        }
        if faza == .szukaj && p == lab.kotekI && lab.trybGry == .plan { radoscKotka(); wygrana(); return }
        if faza == .szukaj && p == lab.kotekI {
            trasaKot = trasa.count; faza = .prowadz; kot.pole = lab.kotekI; radoscKotka(); droga = nil
            naZdarzenie?(.kotekZnaleziony)
        } else if faza == .prowadz && p == lab.domI {
            wygrana(); return
        }
        krok()
    }

    func radoscKotka() {
        radoscPelna = Rozgrywka.RADOSC_S * (podpowiedzi > 0 ? 1 : 2)
        radosc = radoscPelna
        naZdarzenie?(.radosc)
    }

    /// Jedna klatka gry (część `petla` z gry webowej, która dotyczy planszy).
    func tik(_ dt: Double) {
        guard !pauza else { return }
        krokAnimacji(dt)
        if bum > 0 { bum = max(0, bum - dt) }
        if radosc > 0 { radosc = max(0, radosc - dt) }
        for j in lab.przeszkody.indices where lab.przeszkody[j].znika > 0 {
            lab.przeszkody[j].znika = ograniczonyRuch ? 0 : max(0, lab.przeszkody[j].znika - dt * 1.6)
        }
        liczPodp(dt)
        if drogaZostalo > 0 { drogaZostalo -= dt; if drogaZostalo <= 0 { droga = nil } }
        if start && (faza == .szukaj || faza == .prowadz) { czas += dt }
    }

    // MARK: Wygrana i trudność
    /// Dziecko błądzi, gdy przeszło ponad dwa razy więcej pól, niż wynosi najkrótsza droga tam i z powrotem.
    func bladzi() -> Bool {
        if lab.trybGry != .zwykly || trasa.count < 2 { return false }
        func odl(_ a: Int, _ b: Int) -> Double { Double(lab.bfs(a, bezKrzaka: true)[b]) / 2 }
        // Najkrótsza droga przez serduszka po kolei: domek → serduszka → kotek → domek.
        let punkty = [lab.domI] + lab.przeszkody.map(\.klucz).filter { $0 >= 0 } + [lab.kotekI, lab.domI]
        let najkrotsza = zip(punkty, punkty.dropFirst()).reduce(0.0) { $0 + odl($1.0, $1.1) }
        return Double(trasa.count - 1) > Rozgrywka.BLADZENIE * najkrotsza
    }

    /// Po poziomie z dużą pomocą trudność stoi; dwa takie z rzędu — spada o stopień; inaczej rośnie.
    func nastepnaTrudnosc() -> Int {
        let trudno = podpMaks >= 3 || bladzi() || (lab.trybGry == .plan && (plan.ile >= 4 || podpowiedzi >= 2))
        lab.pomocZRzedu = trudno ? lab.pomocZRzedu + 1 : 0
        if lab.pomocZRzedu >= 2 { lab.pomocZRzedu = 0; return max(1, lab.trudnosc - 1) }
        return lab.trudnosc + (trudno ? 0 : 1)
    }

    func wygrana() {
        lab.trudnosc = nastepnaTrudnosc()
        faza = .koniec
        trzymane.removeAll()
        droga = nil
        if kot.cel < 0 { kot.cel = osiol.pole == kot.pole ? -1 : kot.pole }
        naZdarzenie?(.wygrana)
    }
}

extension Rozgrywka {
    /// Coś na planszy porusza się płynnie (osiołek, kotek, radość, uderzenie, znikający krzaczek).
    var ruchNaPlanszy: Bool { osiol.cel >= 0 || kot.cel >= 0 || radosc > 0 || bum > 0 || lab.przeszkody.contains { $0.znika > 0 } }
    /// Tylko łagodna animacja: pulsujące serduszko albo łapki podpowiedzi (wystarczy rzadsze odświeżanie).
    var spokojnaAnimacja: Bool { lab.przeszkody.contains { !$0.otwarta } || (droga != nil && drogaZostalo > 0) }

    /// Ułożenie planszy nie pasuje do ramki (np. labirynt pionowy na ekranie poziomym).
    func zlyKsztalt(szer: Double, wys: Double) -> Bool {
        guard !lab.G.isEmpty, lab.TW != lab.TH, szer > 0, wys > 0 else { return false }
        return (szer > wys) != (lab.TW > lab.TH)
    }

    /// Odbija bieżący poziom względem przekątnej (kolumny ↔ wiersze): ta sama plansza z tymi samymi drogami
    /// i postaciami, ułożona wzdłuż ekranu po obrocie (nowość względem gry webowej, która zostawia pionową planszę).
    func transponuj() {
        let tw = lab.TW, th = lab.TH
        func t(_ i: Int) -> Int { i < 0 ? i : (i % tw) * th + i / tw }
        var g = [UInt8](repeating: 1, count: tw * th)
        for i in 0..<(tw * th) { g[t(i)] = lab.G[i] }
        lab.G = g; lab.TW = th; lab.TH = tw
        lab.domI = t(lab.domI); lab.kotekI = t(lab.kotekI)
        lab.przeszkody = lab.przeszkody.map { Przeszkoda(pole: t($0.pole), klucz: t($0.klucz), otwarta: $0.otwarta, znika: $0.znika) }
        func r(_ o: Ruchomy) -> Ruchomy { Ruchomy(pole: t(o.pole), x: o.y, y: o.x, cel: t(o.cel)) }
        osiol = r(osiol); kot = r(kot)
        serca = serca.map(t); trasa = trasa.map(t)
        slady = slady.map { Slad(i: t($0.i), k: $0.k) }
        // Kąt łapki po odbiciu: atan2 z zamienionymi osiami.
        droga = droga?.map { LapkaPodp(i: t($0.i), kat: 3 * .pi / 2 - $0.kat) }
        // Kierunki planu: prawo ↔ dół, lewo ↔ góra.
        let K2 = [2, 3, 0, 1]
        plan.kroki = plan.kroki.map { KrokPlanu(k: K2[$0.k], pola: $0.pola.map(t), pole: t($0.pole), sciana: $0.sciana) }
        plan.koniec = t(plan.koniec)
        oparty = nil
        podp.cel = -1
        geo = nil
        lab.wersja += 1
    }
}
