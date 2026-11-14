import XCTest
@testable import OsiolekRatujeKotka

/// Tryb „Zaplanuj drogę z robotem”: plan ułożony korytarzami doprowadza osiołka do kotka, ruch w ścianę zatrzymuje
/// osiołka, a cofnięcie i obrót planszy nie psują planu.
final class PlanTests: XCTestCase {
    private func gra(_ ziarno: UInt64, trudnosc: Int = 6, szer: Double = 900, wys: Double = 700) -> Rozgrywka {
        let lab = Labirynt(los: Los(ziarno: ziarno))
        lab.trybGry = .plan
        lab.trudnosc = trudnosc
        let r = Rozgrywka(lab: lab)
        r.zacznijPoziom(szer: szer, wys: wys)
        return r
    }

    /// Kierunek z końca planu w stronę kotka po najkrótszej drodze.
    private func wStroneKotka(_ r: Rozgrywka) -> Int? {
        let lab = r.lab, d = lab.bfs(lab.kotekI), p = r.plan.koniec
        return (0..<4).first { k in
            let m = p + DX[k] + DY[k] * lab.TW
            return lab.G[m] == 0 && d[m] == d[p] - 1
        }
    }

    private func ulozDoKotka(_ r: Rozgrywka) {
        var n = 0
        while r.plan.koniec != r.lab.kotekI && n < 200 {
            guard let k = wStroneKotka(r) else { return XCTFail("brak drogi do kotka") }
            XCTAssertTrue(r.dodajKrok(k))
            n += 1
        }
    }

    private func wykonaj(_ r: Rozgrywka) {
        var n = 0
        while r.plan.wyk >= 0 && r.faza != .koniec && n < 20000 { r.tik(0.05); n += 1 }
    }

    func testPlanKorytarzamiDochodziDoKotka() {
        for z in 1...30 {
            let r = gra(UInt64(z) * 101, trudnosc: 1 + z % 12)
            XCTAssertEqual(r.robotMowi.k, "robotStart")
            XCTAssertTrue(r.lab.przeszkody.isEmpty, "w trybie z robotem nie ma krzaczków")
            ulozDoKotka(r)
            XCTAssertEqual(r.robotMowi.k, "robotGotowe")
            // Plan gotowy: kolejna strzałka nic nie dokłada.
            XCTAssertFalse(r.dodajKrok(0))
            XCTAssertTrue(r.idzPlan())
            wykonaj(r)
            XCTAssertEqual(r.faza, .koniec, "ziarno \(z)")
            XCTAssertEqual(r.osiol.pole, r.lab.kotekI)
            XCTAssertEqual(r.plan.ile, 1)
        }
    }

    func testRuchWScianeZatrzymujeOsiolka() {
        let r = gra(7)
        let d = r.lab.domI
        guard let sciana = (0..<4).first(where: { r.lab.G[d + DX[$0] + DY[$0] * r.lab.TW] != 0 }) else { return XCTFail() }
        XCTAssertTrue(r.dodajKrok(sciana))
        XCTAssertTrue(r.plan.kroki[0].sciana)
        XCTAssertEqual(r.plan.koniec, d)
        XCTAssertEqual(r.robotMowi, KomunikatRobota(k: "robotKroki", n: 1))
        r.idzPlan()
        wykonaj(r)
        XCTAssertEqual(r.osiol.pole, d)
        XCTAssertEqual(r.robotMowi.k, "robotSciana")
        XCTAssertTrue(r.plan.kroki.isEmpty)
        XCTAssertTrue(r.planuje)
    }

    func testPustyPlanICofanie() {
        let r = gra(11)
        XCTAssertFalse(r.idzPlan())
        XCTAssertEqual(r.robotMowi.k, "robotPusty")
        guard let k = wStroneKotka(r) else { return XCTFail() }
        r.dodajKrok(k)
        let po = r.plan.koniec
        XCTAssertNotEqual(po, r.lab.domI)
        if let k2 = wStroneKotka(r) { r.dodajKrok(k2) }
        r.cofnijKrok()
        XCTAssertEqual(r.plan.koniec, po)
        r.wyczyscPlan()
        XCTAssertEqual(r.plan.koniec, r.osiol.pole)
        XCTAssertEqual(r.robotMowi.k, "robotStart")
    }

    /// Obrót ekranu w trakcie układania: ten sam plan na odbitej planszy nadal prowadzi do kotka.
    func testObrotPlanszyZachowujePlan() {
        let r = gra(23, trudnosc: 8)
        if let k = wStroneKotka(r) { r.dodajKrok(k) }
        if let k = wStroneKotka(r) { r.dodajKrok(k) }
        r.transponuj()
        ulozDoKotka(r)
        r.idzPlan()
        wykonaj(r)
        XCTAssertEqual(r.faza, .koniec)
    }

    /// Zapis i powrót do gry: ułożony (niewykonany) plan i liczba planów wracają, robot mówi, ile jest ruchów.
    func testZapisPlanu() throws {
        let r = gra(41)
        guard let k = wStroneKotka(r) else { return XCTFail() }
        r.dodajKrok(k)
        r.plan.ile = 2
        let s = try XCTUnwrap(r.migawka())
        let dane = try JSONEncoder().encode(s)
        let r2 = Rozgrywka(lab: Labirynt())
        r2.przywroc(try JSONDecoder().decode(StanPlanszy.self, from: dane))
        XCTAssertEqual(r2.plan.kroki, r.plan.kroki)
        XCTAssertEqual(r2.plan.koniec, r.plan.koniec)
        XCTAssertEqual(r2.plan.ile, 2)
        XCTAssertEqual(r2.robotMowi.k, r.plan.koniec == r.lab.kotekI ? "robotGotowe" : "robotKroki")
    }

    /// Podpowiedź w trybie z robotem pokazuje jeden korytarz od końca planu.
    func testPodpowiedzToJedenKorytarz() {
        let r = gra(31)
        r.podp.t = r.podp.gotowa
        XCTAssertEqual(r.pokazDroge(), .pokazana)
        guard let k = wStroneKotka(r) else { return XCTFail() }
        XCTAssertEqual(r.droga?.map(\.i), r.korytarz(r.plan.koniec, k))
        XCTAssertEqual(r.robotMowi.k, "robotPodp")
    }
}
