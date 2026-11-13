import XCTest
@testable import OsiolekLogika

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

    func testKrzakZagradzaDrogeISerduszkoJestOsiagalne() {
        var sprawdzone = 0
        for z in 1...30 {
            let lab = Labirynt(los: Los(ziarno: UInt64(z)))
            lab.trudnosc = 6
            lab.wymusKrzak = true
            lab.nowyLabirynt(szer: 900, wys: 700)
            guard lab.przeszkoda.pole >= 0 else { continue }
            sprawdzone += 1
            XCTAssertLessThan(lab.bfs(lab.domI)[lab.kotekI], 0, "krzak nie zagradza")
            XCTAssertGreaterThan(lab.bfs(lab.domI)[lab.przeszkoda.klucz], 0, "serduszko nieosiągalne")
            lab.przeszkoda.otwarta = true
            XCTAssertGreaterThan(lab.bfs(lab.domI)[lab.kotekI], 0)
        }
        XCTAssertGreaterThan(sprawdzone, 10)
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
