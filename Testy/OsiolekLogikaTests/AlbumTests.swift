import XCTest
@testable import OsiolekRatujeKotka

final class AlbumTests: XCTestCase {
    func testPierwszaNaklejkaToOsiolek() {
        var a = AlbumNaklejek(), los = Los(ziarno: 3)
        a.dajNaklejke(&los)
        XCTAssertEqual(a.naklejki.first?.id, "osiolek")
        XCTAssertNil(a.naklejki.first?.x)
    }

    func testPelnyAlbumZaczynaNowy() {
        var a = AlbumNaklejek(), los = Los(ziarno: 4)
        for _ in AlbumNaklejek.wszystkie { a.dajNaklejke(&los) }
        XCTAssertTrue(a.pelny)
        XCTAssertEqual(a.pelne, 1)
        XCTAssertEqual(Set(a.naklejki.map(\.id)).count, AlbumNaklejek.wszystkie.count, "bez powtórzeń")
        // Wszystkie czekają na tacce: nie ma nowej naklejki.
        a.dajNaklejke(&los)
        XCTAssertTrue(a.czeka)
        // Po przyklejeniu jednej następny kotek zaczyna nowy album, a tacka przechodzi do niego.
        a.przyklej("kotek", 800, 700)
        a.dajNaklejke(&los)
        XCTAssertFalse(a.czeka)
        XCTAssertEqual(a.naklejki.count, AlbumNaklejek.wszystkie.count)
        XCTAssertEqual(a.pelne, 2)
    }

    func testNaklejkaZostajeNaOkladce() {
        var a = AlbumNaklejek(), los = Los(ziarno: 5)
        a.dajNaklejke(&los)
        a.przyklej("osiolek", 0, 99_999)
        let n = a.przyklejone[0]
        XCTAssertEqual(n.x, 380 + AlbumNaklejek.NW / 2)
        XCTAssertEqual(n.y, 1140 - AlbumNaklejek.NH / 2)
        XCTAssertEqual(a.naklejkaPod(n.x!, n.y!), "osiolek")
    }
}
