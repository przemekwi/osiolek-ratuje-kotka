import Foundation

/// Migawka bieżącego poziomu: labirynt i położenie postaci (nowość względem gry webowej, która niczego nie zapisuje).
struct StanPlanszy: Codable, Equatable {
    var G: [UInt8]
    var TW: Int
    var TH: Int
    var domI: Int
    var kotekI: Int
    var wersja: Int
    /// Dawny zapis z jednym krzaczkiem (odczyt starszych plików).
    var przeszkoda: Przeszkoda?
    var przeszkody: [Przeszkoda]?
    var trybGry: TrybGry
    var faza: Faza
    var osiol: Ruchomy
    var kot: Ruchomy
    var serca: [Int]
    var sercaN: Int
    var zebrane: Int
    var przedmiot: Przedmiot
    var trasa: [Int]
    var trasaKot: Int
    var slady: [Slad]
    var podpowiedzi: Int
    var podpMaks: Int
    var czas: Double
    var start: Bool
}

/// Wszystko, co aplikacja pamięta między uruchomieniami (plik zapis.json w Application Support).
struct Zapis: Codable, Equatable {
    var wersjaZapisu = 1
    var zapisano = 0.0
    // Ustawienia
    var jezyk: String?
    var motyw: String?
    var muzyka = true
    var dzwieki = true
    /// Opcjonalne: starszy zapis bez tego pola nadal się odczytuje.
    var strzalkiUkryte: Bool?
    var krzakWyjasniony: Bool?
    var wibracje: Bool?
    // Szafa i album
    var koszulkaIndeks: Int?
    var kolorKoszulki: String?
    var album = AlbumNaklejek()
    // Limit czasu
    var limit = Limit()
    // Postęp
    var poziom = 1
    var trudnosc = 1
    var pomocZRzedu = 0
    var ostatniCharakter = ""
    var ostatniRog = -1
    var ostatniZwodniczy = false
    var plansza: StanPlanszy?
}

extension Rozgrywka {
    /// Migawka do zapisu. Postać w ruchu zapisuje się na polu, do którego właśnie idzie.
    func migawka() -> StanPlanszy? {
        guard !lab.G.isEmpty else { return nil }
        func doCelu(_ o: Ruchomy) -> Ruchomy {
            let p = o.cel >= 0 ? o.cel : o.pole
            return Ruchomy(pole: p, x: Double(lab.ix(p)), y: Double(lab.iy(p)), cel: -1)
        }
        return StanPlanszy(G: lab.G, TW: lab.TW, TH: lab.TH, domI: lab.domI, kotekI: lab.kotekI, wersja: lab.wersja,
                           przeszkoda: nil, przeszkody: lab.przeszkody.map { Przeszkoda(pole: $0.pole, klucz: $0.klucz, otwarta: $0.otwarta, znika: 0) },
                           trybGry: lab.trybGry, faza: faza, osiol: doCelu(osiol), kot: doCelu(kot), serca: serca, sercaN: sercaN,
                           zebrane: zebrane, przedmiot: przedmiot, trasa: trasa, trasaKot: trasaKot, slady: slady,
                           podpowiedzi: podpowiedzi, podpMaks: podp.maks, czas: czas, start: start)
    }

    /// Odtwarza zapisany poziom w tym samym miejscu, w którym dziecko skończyło.
    func przywroc(_ s: StanPlanszy) {
        lab.G = s.G; lab.TW = s.TW; lab.TH = s.TH; lab.domI = s.domI; lab.kotekI = s.kotekI
        lab.wersja = s.wersja + 1
        lab.przeszkody = s.przeszkody ?? (s.przeszkoda.map { $0.pole >= 0 ? [$0] : [] } ?? [])
        lab.trybGry = s.trybGry
        puscWszystko()
        faza = s.faza; osiol = s.osiol; kot = s.kot
        serca = s.serca; sercaN = s.sercaN; zebrane = s.zebrane; przedmiot = s.przedmiot
        trasa = s.trasa; trasaKot = s.trasaKot; slady = s.slady
        podpowiedzi = s.podpowiedzi; czas = s.czas; start = s.start
        oparty = nil; bum = 0; radosc = 0; pauza = false; droga = nil; drogaZostalo = 0
        geo = nil
        podpStart()
        podp.maks = s.podpMaks
    }
}
