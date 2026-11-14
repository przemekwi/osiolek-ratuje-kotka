import Foundation

/// Naklejka w albumie: położenie środka w układzie rysunku albumu; `x == nil` — naklejka czeka na tacce.
struct Naklejka: Codable, Equatable {
    var id: String
    var x: Double?
    var y: Double?
}

/// Album naklejek przeniesiony z gry webowej (`album`, `dajNaklejke`, `przyklej`, `naOkladce`).
/// Za każdego uratowanego kotka dziecko dostaje naklejkę z rysunków; pełny album zaczyna nowy w innym kolorze.
struct AlbumNaklejek: Codable, Equatable {
    /// Kolejność jak `NAKLEJKI` w grze; pierwsza nowa naklejka to zawsze osiołek.
    static let wszystkie = ["osiolek", "kotek", "dom", "robot", "lapka", "krzak", "slonce", "zwierzatko", "dziewczynka",
                            "jednorozec", "gwiazdki", "serce", "trawa", "samochod", "kon", "grzybek", "pilka"]
    /// Naklejka zajmuje NW×NH jednostek rysunku albumu; środek zostaje na okładce.
    static let NW = 180.0, NH = 225.0
    /// Kolejne wolne miejsca: trzy rzędy po siedem.
    static let MIEJSCA: [(Double, Double)] = [450.0, 735, 1020].flatMap { y in [470.0, 658, 846, 1034, 1222, 1410, 1598].map { ($0, y) } }

    var naklejki: [Naklejka] = []
    var pelne = 0
    var ostatnia: String?
    var wybrana: String?
    /// Album pełny, a wszystkie naklejki czekają na tacce: nie ma nowej naklejki ani nowego albumu.
    var czeka = false

    var pelny: Bool { naklejki.count == AlbumNaklejek.wszystkie.count }
    var przyklejone: [Naklejka] { naklejki.filter { $0.x != nil } }
    var naTacce: [Naklejka] { naklejki.filter { $0.x == nil } }
    /// Indeks koloru bieżącego albumu (`kolorAlbumu`).
    func indeksKoloru(_ ile: Int) -> Int { max(0, pelne - (pelny ? 1 : 0)) % ile }

    mutating func dajNaklejke(_ los: inout Los) {
        czeka = false
        if pelny {
            let tacka = naTacce
            if tacka.count == AlbumNaklejek.wszystkie.count { czeka = true; return }
            naklejki = tacka
            if !tacka.contains(where: { $0.id == wybrana }) { wybrana = nil }
        }
        let wolne = AlbumNaklejek.wszystkie.filter { id in !naklejki.contains { $0.id == id } }
        guard !wolne.isEmpty else { return }
        let id = wolne.contains("osiolek") ? "osiolek" : los.pick(wolne)
        naklejki.append(Naklejka(id: id))
        ostatnia = id
        if pelny { pelne += 1 }
    }

    static func naOkladce(_ x: Double, _ y: Double) -> (Double, Double) {
        (max(380 + NW / 2, min(1690 - NW / 2, x)), max(330 + NH / 2, min(1140 - NH / 2, y)))
    }

    var wolneMiejsca: [(Double, Double)] {
        let sa = przyklejone
        return AlbumNaklejek.MIEJSCA.filter { m in !sa.contains { abs($0.x! - m.0) < AlbumNaklejek.NW / 2 && abs($0.y! - m.1) < AlbumNaklejek.NH / 2 } }
    }

    /// Przykleja naklejkę (z tacki albo przesuwaną) w punkcie; przyklejona trafia na wierzch.
    mutating func przyklej(_ id: String, _ x: Double, _ y: Double) {
        guard let i = naklejki.firstIndex(where: { $0.id == id }) else { return }
        var n = naklejki.remove(at: i)
        let p = AlbumNaklejek.naOkladce(x, y)
        n.x = p.0; n.y = p.1
        naklejki.append(n)
        wybrana = nil
    }

    /// Najwyżej leżąca przyklejona naklejka pod punktem.
    func naklejkaPod(_ x: Double, _ y: Double) -> String? {
        przyklejone.reversed().first { abs($0.x! - x) < AlbumNaklejek.NW / 2 && abs($0.y! - y) < AlbumNaklejek.NH / 2 }?.id
    }

    /// Przesuwa przyklejoną naklejkę na wierzch (przy chwyceniu palcem).
    mutating func naWierzch(_ id: String) {
        guard let i = naklejki.firstIndex(where: { $0.id == id }) else { return }
        naklejki.append(naklejki.remove(at: i))
    }

    mutating func przesun(_ id: String, _ x: Double, _ y: Double) {
        guard let i = naklejki.firstIndex(where: { $0.id == id }) else { return }
        let p = AlbumNaklejek.naOkladce(x, y)
        naklejki[i].x = p.0; naklejki[i].y = p.1
    }
}
