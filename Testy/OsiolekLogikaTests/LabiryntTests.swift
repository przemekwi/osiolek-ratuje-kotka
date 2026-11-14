import XCTest
@testable import OsiolekRatujeKotka

final class LabiryntTests: XCTestCase {
    /// Każde pole labiryntu jest osiągalne z domku, a kotek stoi gdzie indziej.
    func testLabiryntSpojny() {
        for t in 1...14 {
            let lab = Labirynt(los: Los(ziarno: UInt64(t) * 7919))
            lab.trudnosc = t
            lab.wymusKrzak = false
            lab.nowyLabirynt(szer: 900, wys: 700)
            let d = lab.bfs(lab.domI)
            var y = 1
            while y < lab.TH {
                var x = 1
                while x < lab.TW { XCTAssertGreaterThanOrEqual(d[y * lab.TW + x], 0, "trudność \(t)"); x += 2 }
                y += 2
            }
            XCTAssertNotEqual(lab.domI, lab.kotekI)
            XCTAssertTrue(lab.jestPolem(lab.domI) && lab.jestPolem(lab.kotekI))
            // Brzeg planszy to zawsze ściana.
            for x in 0..<lab.TW { XCTAssertEqual(lab.G[x], 1); XCTAssertEqual(lab.G[(lab.TH - 1) * lab.TW + x], 1) }
        }
    }

    func testRozmiarJakNaStronie() {
        XCTAssertTrue(Labirynt.naturalny(1) == (4, 3))
        XCTAssertTrue(Labirynt.naturalny(3) == (5, 4))
        XCTAssertTrue(Labirynt.naturalny(5) == (6, 4))
        XCTAssertTrue(Labirynt.naturalny(7) == (7, 5))
        XCTAssertTrue(Labirynt.naturalny(9) == (8, 6))
        // Pionowy ekran telefonu: dłuższy bok planszy w pionie.
        let (a, b) = Labirynt.rozmiar(9, szer: 360, wys: 520)
        XCTAssertLessThanOrEqual(a, b)
    }

    func testTenSamLabiryntDlaTegoSamegoZiarna() {
        let a = Labirynt(los: Los(ziarno: 42)), b = Labirynt(los: Los(ziarno: 42))
        a.trudnosc = 6; b.trudnosc = 6
        a.nowyLabirynt(szer: 800, wys: 600); b.nowyLabirynt(szer: 800, wys: 600)
        XCTAssertEqual(a.G, b.G)
        XCTAssertEqual(a.kotekI, b.kotekI)
    }

    func testLiczbaKrzakowRosnieZeStopniem() {
        XCTAssertEqual((1...16).map(Labirynt.liczbaKrzakow), [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3])
    }

    /// Tysiące plansz: każdy krzaczek zamyka drogę do kotka, serduszka leżą po kolei (drugie za pierwszym krzaczkiem),
    /// a symulacja przejścia dochodzi do kotka i wraca do domku.
    func testKazdaPlanszaZKrzaczkamiDaSiePrzejsc() {
        var pelne = 0, wszystkie = 0
        for t in 5...24 {
            for z in 1...40 {
                for (szer, wys) in [(900.0, 700.0), (390.0, 640.0)] {
                    let lab = Labirynt(los: Los(ziarno: UInt64(t * 1000 + z)))
                    lab.trudnosc = t
                    lab.nowyLabirynt(szer: szer, wys: wys)
                    let n = lab.przeszkody.count, cel = Labirynt.liczbaKrzakow(t)
                    wszystkie += 1
                    if n == cel { pelne += 1 }
                    XCTAssertTrue(n >= 1 && n <= cel, "stopień \(t): \(n) krzaczków")
                    XCTAssertLessThan(lab.bfs(lab.domI)[lab.kotekI], 0, "krzaczki nie zagradzają drogi (stopień \(t))")
                    let zajete = lab.przeszkody.flatMap { [$0.pole, $0.klucz] }
                    XCTAssertEqual(Set(zajete).count, zajete.count, "krzaczki i serduszka na różnych polach")
                    XCTAssertFalse(zajete.contains(lab.domI) || zajete.contains(lab.kotekI))
                    // Po kolei: serduszko i-te osiągalne dopiero po otwarciu krzaczka i-1, a krzaczek i zamyka drogę dalej.
                    for i in 0..<n {
                        for j in 0..<n { lab.przeszkody[j].otwarta = j < i }
                        let d = lab.bfs(lab.domI)
                        XCTAssertGreaterThan(d[lab.przeszkody[i].klucz], 0, "serduszko \(i) nieosiągalne (stopień \(t))")
                        XCTAssertLessThan(d[lab.kotekI], 0, "krzaczek \(i) nie zamyka drogi")
                        if i > 0 {
                            lab.przeszkody[i - 1].otwarta = false
                            XCTAssertLessThan(lab.bfs(lab.domI)[lab.przeszkody[i].klucz], 0, "serduszko \(i) przed krzaczkiem \(i - 1)")
                        }
                    }
                    for j in 0..<n { lab.przeszkody[j].otwarta = false }
                    XCTAssertTrue(lab.daSiePrzejsc(), "plansza nie do przejścia (stopień \(t), ziarno \(z))")
                }
            }
        }
        XCTAssertGreaterThan(Double(pelne) / Double(wszystkie), 0.8, "zwykle mieści się tyle krzaczków, ile przewiduje stopień")
    }

    func testLosPolaJakWJavaScripcie() {
        // Wartości policzone funkcją los(i,s) z gry webowej (wersja = 1).
        XCTAssertEqual(losPola(0, 0, wersja: 1), 0.4915040940977633, accuracy: 1e-12)
        XCTAssertEqual(losPola(57, 7, wersja: 3), 0.6873467836994678, accuracy: 1e-12)
        XCTAssertEqual(losPola(40, 12.37 * 7 + 1, wersja: 2), 0.1654458672273904, accuracy: 1e-12)
    }
}

final class RozgrywkaTests: XCTestCase {
    /// Prowadzi osiołka najkrótszą drogą: do kotka, potem z kotkiem do domku.
    func testPrzejscieDoKotkaIDoDomku() {
        let r = Rozgrywka(lab: Labirynt(los: Los(ziarno: 5)))
        r.lab.wymusKrzak = false
        r.zacznijPoziom(szer: 800, wys: 600)
        func dojdz(do cel: Int) {
            var bezpiecznik = 0
            while r.osiol.pole != cel && bezpiecznik < 10_000 {
                let d = r.lab.bfs(cel)
                let nast = r.lab.krokBlizej(r.osiol.pole, d)
                let k = (0..<4).first { r.osiol.pole + DX[$0] + DY[$0] * r.lab.TW == nast }!
                // Krótkie naciśnięcie: jeden krok (przy trzymaniu osiołek szedłby dalej).
                r.trzymaj("test", k)
                r.pusc("test")
                while r.osiol.cel >= 0 { r.tik(1 / 60) }
                bezpiecznik += 1
            }
        }
        XCTAssertEqual(r.faza, .szukaj)
        dojdz(do: r.lab.kotekI)
        XCTAssertEqual(r.faza, .prowadz)
        dojdz(do: r.lab.domI)
        XCTAssertEqual(r.faza, .koniec)
        XCTAssertEqual(r.lab.trudnosc, 2, "bez pomocy trudność rośnie")
    }

    /// Prawdziwa rozgrywka na planszach z krzaczkami: osiołek zbiera serduszka po kolei (cel podpowiedzi),
    /// otwiera krzaczki, dochodzi do kotka i wraca z nim do domku.
    func testPrzejscieZKrzaczkamiPoKolei() {
        for (t, z) in [(5, 1), (9, 2), (11, 3), (13, 4), (16, 5), (20, 6)] {
            let r = Rozgrywka(lab: Labirynt(los: Los(ziarno: UInt64(z))))
            r.lab.trudnosc = t
            r.zacznijPoziom(szer: 900, wys: 700)
            var bezpiecznik = 0
            while r.faza != .koniec && bezpiecznik < 20_000 {
                let d = r.lab.bfs(r.celPodp)
                let nast = r.lab.krokBlizej(r.osiol.pole, d)
                guard let k = (0..<4).first(where: { r.osiol.pole + DX[$0] + DY[$0] * r.lab.TW == nast }) else { break }
                r.trzymaj("test", k)
                r.pusc("test")
                while r.osiol.cel >= 0 { r.tik(1 / 60) }
                bezpiecznik += 1
            }
            XCTAssertEqual(r.faza, .koniec, "stopień \(t): nie udało się przejść")
            XCTAssertTrue(r.lab.przeszkody.allSatisfy(\.otwarta), "stopień \(t): krzaczek został zamknięty")
        }
    }

    func testOsiolekNieWchodziWSciane() {
        let r = Rozgrywka(lab: Labirynt(los: Los(ziarno: 9)))
        r.lab.wymusKrzak = false
        r.zacznijPoziom(szer: 800, wys: 600)
        var zdarzenia: [Zdarzenie] = []
        r.naZdarzenie = { zdarzenia.append($0) }
        let k = (0..<4).first { r.lab.G[r.osiol.pole + DX[$0] + DY[$0] * r.lab.TW] != 0 }!
        let przed = r.osiol.pole
        r.trzymaj("test", k)
        for _ in 0..<60 { r.tik(1 / 60) }
        XCTAssertEqual(r.osiol.pole, przed)
        XCTAssertEqual(zdarzenia.filter { if case .bum = $0 { return true }; return false }.count, 1, "jedno uderzenie, nie co klatkę")
    }

    func testGeometriaSrodek() {
        let g = Geometria(TW: 9, TH: 7, szer: 400, wys: 300)
        XCTAssertEqual(g.X0.count, 10)
        XCTAssertLessThanOrEqual(g.W, 400)
        XCTAssertEqual(g.sx(1.5), (g.sx(1) + g.sx(2)) / 2, accuracy: 1e-9)
    }
}

final class TranspozycjaTests: XCTestCase {
    func testDwaOdbiciaDajaTenSamPoziom() {
        let r = Rozgrywka(lab: Labirynt(los: Los(ziarno: 21)))
        r.lab.trudnosc = 5
        r.zacznijPoziom(szer: 400, wys: 800)
        let G = r.lab.G, kot = r.lab.kotekI, tw = r.lab.TW
        XCTAssertTrue(r.zlyKsztalt(szer: 800, wys: 400))
        r.transponuj()
        XCTAssertFalse(r.zlyKsztalt(szer: 800, wys: 400))
        XCTAssertEqual(r.lab.bfs(r.lab.domI, bezKrzaka: true)[r.lab.kotekI] >= 0, true)
        r.transponuj()
        XCTAssertEqual(r.lab.G, G); XCTAssertEqual(r.lab.kotekI, kot); XCTAssertEqual(r.lab.TW, tw)
    }
}
