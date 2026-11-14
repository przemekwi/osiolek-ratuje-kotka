import XCTest
@testable import OsiolekRatujeKotka

final class LimitTests: XCTestCase {
    func testOstrzezenieIPrzerwaPoSesji() {
        var l = Limit(), los = Los(ziarno: 1)
        l.nowyDzien("2026-11-14")
        XCTAssertEqual(l.licz(12 * 60, wLabiryncie: false), .nic)
        XCTAssertEqual(l.licz(60 + 1, wLabiryncie: false), .ostrzezenie)
        XCTAssertEqual(l.licz(10, wLabiryncie: false), .nic)
        XCTAssertEqual(l.licz(120, wLabiryncie: false), .przerwa)
        l.przerwa(teraz: 1000, &los)
        XCTAssertEqual(l.blokada, .sesja)
        XCTAssertTrue((6...9).contains(l.a) && (6...9).contains(l.b))
        XCTAssertEqual(l.odpowiedz, l.a * l.b)
        XCTAssertFalse(l.sprawdz(l.odpowiedz + 1))
        XCTAssertTrue(l.sprawdz(l.odpowiedz))
        XCTAssertFalse(l.przerwaMinela(teraz: 1000 + 29 * 60))
        XCTAssertTrue(l.przerwaMinela(teraz: 1000 + 30 * 60))
    }

    func testDokonczenieLabiryntuNajwyzejDwieMinuty() {
        var l = Limit()
        l.nowyDzien("d")
        _ = l.licz(15 * 60, wLabiryncie: true)
        XCTAssertEqual(l.licz(1, wLabiryncie: true), .dokonczLabirynt)
        XCTAssertEqual(l.licz(Limit.DOGRYWKA, wLabiryncie: true), .przerwa)
    }

    func testPrzedluzeniaCorazKrotszeNajwyzejDwa() {
        var l = Limit(), los = Los(ziarno: 2)
        l.nowyDzien("d")
        _ = l.licz(15 * 60, wLabiryncie: false)
        l.przerwa(teraz: 0, &los)
        XCTAssertEqual(l.opcjePrzedluzenia, [10, 5])
        l.przedluz(10)
        _ = l.licz(5 * 60, wLabiryncie: false)   // dzień: 20 min z 30
        XCTAssertFalse(l.zablokowana)
        _ = l.licz(5 * 60, wLabiryncie: false)
        l.przerwa(teraz: 0, &los)
        XCTAssertEqual(l.blokada, .sesja)
        XCTAssertEqual(l.opcjePrzedluzenia, [5])
        l.przedluz(5)
        _ = l.licz(5 * 60, wLabiryncie: false)
        l.przerwa(teraz: 0, &los)
        XCTAssertEqual(l.blokada, .dzien, "30 minut dnia wykorzystane")
        XCTAssertEqual(l.opcjePrzedluzenia, [])
    }

    func testLimitDnia() {
        var l = Limit(), los = Los(ziarno: 3)
        l.ustaw(sesja: 30, dzien: 20)
        l.nowyDzien("d")
        _ = l.licz(20 * 60, wLabiryncie: false)
        l.przerwa(teraz: 0, &los)
        XCTAssertEqual(l.blokada, .dzien)
        XCTAssertFalse(l.przerwaMinela(teraz: 99_999))
        l.ustaw(sesja: 30, dzien: 30)
        XCTAssertFalse(l.zablokowana, "rodzic podniósł limit dnia")
        l.ustaw(sesja: 30, dzien: 90)
        XCTAssertLessThanOrEqual(l.dzienMin, 60)
    }

    func testNowyDzienIPowrotPoPrzerwie() {
        var l = Limit(), los = Los(ziarno: 4)
        l.nowyDzien("2026-11-14")
        _ = l.licz(30 * 60, wLabiryncie: false)
        l.przerwa(teraz: 0, &los)
        XCTAssertEqual(l.blokada, .dzien)
        l.poPowrocie(zapisano: 0, teraz: 10, dzien: "2026-11-15")
        XCTAssertFalse(l.zablokowana)
        XCTAssertEqual(l.dzisiaj, 0)
        _ = l.licz(10 * 60, wLabiryncie: false)
        l.poPowrocie(zapisano: 0, teraz: Limit.PRZERWA_PO_SESJI, dzien: "2026-11-15")
        XCTAssertEqual(l.sesja, 0, "pół godziny z zamkniętą aplikacją to przerwa")
        XCTAssertEqual(l.dzisiaj, 10 * 60, "ale czas dnia się nie zeruje")
    }

    func testStaryZapisSieOdczytuje() throws {
        let stary = #"{"uplynelo":100,"liczba":27,"zablokowana":false}"#.data(using: .utf8)!
        let l = try JSONDecoder().decode(Limit.self, from: stary)
        XCTAssertEqual(l.sesjaMin, 15)
        XCTAssertFalse(l.zablokowana)
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
