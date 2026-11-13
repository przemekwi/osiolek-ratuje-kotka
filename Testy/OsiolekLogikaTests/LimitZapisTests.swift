import XCTest
@testable import OsiolekLogika

final class LimitTests: XCTestCase {
    func testPrzerwaPo15MinutachIOdblokowanie() {
        var l = Limit(), los = Los(ziarno: 1)
        XCTAssertFalse(l.licz(14 * 60))
        XCTAssertTrue(l.licz(60))
        l.przerwa(teraz: 1000, &los)
        XCTAssertTrue(l.zablokowana)
        XCTAssertTrue((21...49).contains(l.liczba) && l.liczba % 10 != 0)
        XCTAssertFalse(l.sprawdz(l.liczba + 1, teraz: 1010))
        XCTAssertTrue(l.sprawdz(l.liczba, teraz: 1010))
        XCTAssertEqual(l.opcjePrzedluzenia, [10, 5])
        l.przedluz(10)
        XCTAssertFalse(l.zablokowana)
        XCTAssertEqual(l.opcjePrzedluzenia, [5])
        l.przedluz(5)
        XCTAssertEqual(l.opcjePrzedluzenia, [3])
        l.przedluz(3)
        XCTAssertTrue(l.pokazDobro)
    }

    func testPrawdziwaPrzerwaPrzywracaPelnyLimit() {
        var l = Limit(), los = Los(ziarno: 2)
        _ = l.licz(Limit.LIMIT_S)
        l.przerwa(teraz: 0, &los)
        XCTAssertTrue(l.sprawdz(l.liczba, teraz: Limit.PRZERWA_S))
        XCTAssertEqual(l.opcjePrzedluzenia, [15])
    }

    func testZamknietaAplikacjaGodzinaToPrzerwa() {
        var l = Limit()
        _ = l.licz(600)
        l.poPowrocie(zapisano: 0, teraz: Limit.PRZERWA_S + 1)
        XCTAssertEqual(l.uplynelo, 0)
        var z = Limit(), los = Los(ziarno: 3)
        z.przerwa(teraz: 0, &los)
        z.poPowrocie(zapisano: 0, teraz: 99_999)
        XCTAssertTrue(z.zablokowana, "zablokowanej gry nie odblokowuje samo zamknięcie aplikacji")
    }

    func testLiczbySlownie() {
        XCTAssertEqual(Limit.slownie(21, "pl"), "dwadzieścia jeden")
        XCTAssertEqual(Limit.slownie(38, "it"), "trentotto")
        XCTAssertEqual(Limit.slownie(41, "fr"), "quarante et un")
        XCTAssertEqual(Limit.slownie(24, "de"), "vierundzwanzig")
    }
}

final class ZapisTests: XCTestCase {
    func testMigawkaWracaTakaSama() throws {
        let r = Rozgrywka(lab: Labirynt(los: Los(ziarno: 11)))
        r.lab.trudnosc = 4
        r.zacznijPoziom(szer: 800, wys: 600)
        let s = try XCTUnwrap(r.migawka())
        var z = Zapis(); z.plansza = s
        let dane = try JSONEncoder().encode(z)
        let odczyt = try JSONDecoder().decode(Zapis.self, from: dane)
        let r2 = Rozgrywka(lab: Labirynt(los: Los(ziarno: 12)))
        r2.przywroc(try XCTUnwrap(odczyt.plansza))
        XCTAssertEqual(r2.lab.G, r.lab.G)
        XCTAssertEqual(r2.osiol.pole, r.osiol.pole)
        XCTAssertEqual(r2.lab.kotekI, r.lab.kotekI)
        XCTAssertEqual(r2.serca, r.serca)
    }
}
