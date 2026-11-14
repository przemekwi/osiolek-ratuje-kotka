import Foundation

/// Jeden ruch planu: kierunek, pola korytarza, pole na końcu ruchu i czy ruch idzie w ścianę.
struct KrokPlanu: Codable, Equatable {
    var k: Int
    var pola: [Int]
    var pole: Int
    var sciana: Bool
}

/// Plan robota (`plan` z gry webowej): ułożone ruchy, pole na końcu planu, wykonywany ruch (-1: dziecko układa),
/// ile pól siatki zostało w bieżącym ruchu (nil: ruch jeszcze nie zaczęty) i ile razy dziecko nacisnęło „Idź”.
struct StanPlanu: Equatable {
    var kroki: [KrokPlanu] = []
    var koniec = 0
    var wyk = -1
    var zostalo: Int? = 0
    var ile = 0
}

/// Komunikat robota w dymku (klucz tekstu i liczba ruchów dla `robotKroki`).
struct KomunikatRobota: Equatable {
    var k: String
    var n: Int?
}

/// Tryb „Zaplanuj drogę z robotem”, przeniesiony 1:1 z gry webowej (te same nazwy funkcji).
/// Dziecko najpierw układa drogę do kotka strzałkami, a osiołek rusza dopiero po „Idź”. Jedna strzałka to cały
/// korytarz: osiołek idzie, aż dojdzie do ściany, do rozwidlenia (żeby dało się skręcić) albo do kotka.
/// Celem jest dojście do kotka, bez powrotu do domku. Robot mówi, ile ruchów jest w planie, ale nie poprawia dziecka
/// w trakcie układania: ruch w ścianę też trafia do planu. Błąd wychodzi dopiero po „Idź”: osiołek staje przy ścianie,
/// robot mówi, co się stało, a dziecko układa dalszą drogę od tego miejsca. Plan widać jako niebieskie łapki.
extension Rozgrywka {
    /// Kąt łapki planu dla kierunku k (prawo, lewo, dół, góra).
    static let KAT: [Double] = [.pi / 2, -.pi / 2, .pi, 0]
    static let KOMUNIKATY_ROBOTA = ["robotStart", "robotSciana", "robotKroki", "robotPusty", "robotIdzie", "robotGotowe",
                                    "robotKoniec", "robotPodp"]

    func mowRobot(_ k: String, _ n: Int? = nil) {
        robotMowi = KomunikatRobota(k: k, n: n)
        naZdarzenie?(.robot)
    }

    func planOdNowa() { plan.kroki = []; plan.koniec = osiol.pole; plan.wyk = -1; plan.zostalo = 0 }

    var planuje: Bool { lab.trybGry == .plan && wGrze && plan.wyk < 0 }

    /// Pola, przez które przejdzie osiołek jedną strzałką z pola p w stronę k (pusta lista: ściana).
    func korytarz(_ start: Int, _ k: Int) -> [Int] {
        let G = lab.G, TW = lab.TW
        func sciana(_ i: Int) -> Bool? { G.indices.contains(i) ? G[i] != 0 : nil }
        var pola: [Int] = [], p = start
        let krok = DX[k] + DY[k] * TW, bok = k < 2 ? [TW, -TW] : [1, -1]
        while sciana(p + krok) == false {
            p += 2 * krok; pola.append(p)
            if p == lab.kotekI { break }
            guard let dalej = sciana(p + krok), !dalej else { break }
            if sciana(p + bok[0]) == false || sciana(p + bok[1]) == false { break }
        }
        return pola
    }

    /// Strzałka w trybie planu: dokłada ruch na koniec planu. Zwraca true, gdy ruch trafił do planu (dźwięk kroku).
    @discardableResult
    func dodajKrok(_ k: Int) -> Bool {
        guard planuje else { return false }
        if plan.koniec == lab.kotekI { mowRobot("robotGotowe"); return false }
        let pola = korytarz(plan.koniec, k)
        if let ost = pola.last { plan.koniec = ost }
        plan.kroki.append(KrokPlanu(k: k, pola: pola, pole: plan.koniec, sciana: pola.isEmpty))
        if plan.koniec == lab.kotekI { mowRobot("robotGotowe") } else { mowRobot("robotKroki", plan.kroki.count) }
        return true
    }

    @discardableResult
    func cofnijKrok() -> Bool {
        guard planuje, !plan.kroki.isEmpty else { return false }
        plan.kroki.removeLast()
        plan.koniec = plan.kroki.last?.pole ?? osiol.pole
        mowRobot("robotKroki", plan.kroki.count)
        return true
    }

    @discardableResult
    func wyczyscPlan() -> Bool {
        guard planuje else { return false }
        planOdNowa(); mowRobot("robotStart")
        return true
    }

    @discardableResult
    func idzPlan() -> Bool {
        guard planuje else { return false }
        if plan.kroki.isEmpty { mowRobot("robotPusty"); return false }
        plan.wyk = 0; plan.zostalo = nil; plan.ile += 1; start = true; mowRobot("robotIdzie")
        return true
    }

    /// Każde pole korytarza to dwa pola siatki (otwór w ścianie i pole za nim).
    func krokPlanu() {
        if plan.wyk < 0 { return }
        if plan.zostalo == 0 { plan.wyk += 1; plan.zostalo = nil }
        guard plan.wyk < plan.kroki.count else { planOdNowa(); mowRobot("robotKoniec"); return }
        let s = plan.kroki[plan.wyk]
        if s.sciana {
            bum = ograniczonyRuch ? 0 : 0.25
            naZdarzenie?(.bum(krzak: false))
            planOdNowa(); mowRobot("robotSciana")
            return
        }
        if plan.zostalo == nil { plan.zostalo = 2 * s.pola.count }
        plan.zostalo! -= 1
        idz(s.k)
    }

    /// W trybie planu stuknięcie w planszę dokłada krok w stronę stuknięcia, licząc od końca planu.
    @discardableResult
    func krokPalcem(x: Double, y: Double) -> Bool {
        guard let g = geo else { return false }
        let dx = x - g.sx(Double(lab.ix(plan.koniec))), dy = y - g.sy(Double(lab.iy(plan.koniec)))
        if hypot(dx, dy) < g.C * 0.5 { return false }
        return dodajKrok(abs(dx) > abs(dy) ? (dx > 0 ? 0 : 1) : (dy > 0 ? 2 : 3))
    }

    /// Prowadzenie palcem po planszy rysuje plan: gdy palec wejdzie na pole w korytarzu od końca planu, ruch przez cały
    /// ten korytarz trafia do planu; powrót palcem na koniec poprzedniego ruchu cofa ruch.
    /// Zwraca, co się stało: nil — nic, true — ruch dodany, false — ruch cofnięty.
    func prowadzPalcem(_ c: Int) -> Bool? {
        guard geo != nil, planuje, c >= 0, lab.jestPolem(c), c != plan.koniec else { return nil }
        let poprz = plan.kroki.count > 1 ? plan.kroki[plan.kroki.count - 2].pole : osiol.pole
        if !plan.kroki.isEmpty && c == poprz { return cofnijKrok() ? false : nil }
        // Palec jeszcze w korytarzu, który już jest w planie: to nie nowy ruch.
        if c == osiol.pole || plan.kroki.contains(where: { $0.pola.contains(c) }) { return nil }
        for k in 0..<4 where korytarz(plan.koniec, k).contains(c) { return dodajKrok(k) ? true : nil }
        return nil
    }

    /// Łapki planu do narysowania: pole, kąt i rozmiar względem pola (koniec ruchu większy, koniec planu największy).
    func lapkiPlanu() -> [(i: Int, kat: Double, r: Double)] {
        let od = plan.wyk < 0 ? 0 : plan.wyk, n = plan.kroki.count
        guard od < n else { return [] }
        var wynik: [(i: Int, kat: Double, r: Double)] = []
        for (i, s) in plan.kroki[od...].enumerated() {
            var pola = s.pola
            if i == 0 && plan.wyk >= 0, let z = plan.zostalo {
                pola = Array(s.pola.suffix(Int((Double(z) / 2).rounded(.up))))
            }
            for (j, p) in pola.enumerated() {
                let r = od + i == n - 1 && j == pola.count - 1 ? 0.24 : j == pola.count - 1 ? 0.2 : 0.13
                wynik.append((p, Rozgrywka.KAT[s.k], r))
            }
        }
        return wynik
    }
}
