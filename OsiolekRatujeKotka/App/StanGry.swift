import SwiftUI
import UIKit
import Observation

enum Ekran { case start, szafa, gra }
enum Nakladka: Equatable { case menu, brawo, album }
enum WyborMotywu: String, CaseIterable { case system, jasny, ciemny }

/// Stan aplikacji widoczny dla SwiftUI. Logika poziomu żyje w `Rozgrywka`; tu są ekrany, nakładki,
/// ustawienia i napisy, które zmieniają się rzadko (nie co klatkę), żeby nie przeliczać całego widoku 60× na sekundę.
@Observable
final class StanGry {
    var ekran: Ekran = .start
    var nakladka: Nakladka?
    var jezyk: String = Teksty.jezykUrzadzenia() { didSet { if przerwaTrwa { odswiezPrzerwe() } } }
    var motyw: WyborMotywu = .system
    /// Wybrana koszulka (indeks rysunku) i kolor z palety; nil — kolor z rysunku.
    var koszulkaIndeks: Int?
    var kolorKoszulki: String?
    /// Koszulka, którą osiołek ma na sobie (`zalozona` z gry).
    var koszulka: Koszulka? { koszulkaIndeks.map { Koszulka(indeks: $0, kolor: kolorKoszulki) } }
    var album = AlbumNaklejek()
    /// Limit czasu dla dziecka. Licznik zmienia się co klatkę, więc SwiftUI go nie obserwuje;
    /// widoki czytają `przerwaTrwa` i `pytanieRodzica`, które zmieniają się tylko przy przerwie.
    @ObservationIgnored private(set) var limit = Limit()
    private(set) var przerwaTrwa = false
    private(set) var pytanieRodzica = ""

    // Napisy paska, odświeżane przy zmianie.
    private(set) var poziom = 1
    private(set) var faza: Faza = .szukaj
    private(set) var sekunda = 0
    private(set) var zebrane = 0
    private(set) var wersja = 0
    /// Licznik uderzeń w ścianę — wyzwala wibrację.
    private(set) var uderzenia = 0
    private(set) var spotkania = 0
    private(set) var komunikat = ""
    /// Przycisk podpowiedzi: sekundy do odblokowania (0 — gotowa) i wypełnienie paska.
    private(set) var podpZa = 0
    private(set) var podpPasek = 0.0
    /// Licznik pokazanych podpowiedzi — wyzwala rozjaśnienie żarówki.
    private(set) var podpGotowa = 0
    var muzyka = true { didSet { Syntezator.wspolny.muzyka = muzyka; if muzyka && ekran == .gra { Syntezator.wspolny.wlaczMuzyke() } } }
    var dzwieki = true { didSet { Syntezator.wspolny.dzwieki = dzwieki } }

    @ObservationIgnored let gra = Rozgrywka()
    /// Rozmiar ramki planszy (punkty) — do wielkości labiryntu i geometrii.
    @ObservationIgnored var ramka: CGSize = .zero
    @ObservationIgnored private var brawoZa = 0.0
    /// Nowy poziom czeka na pierwszy pomiar ramki planszy (wielkość labiryntu zależy od miejsca na ekranie).
    @ObservationIgnored private var czekaNaRamke = false
    @ObservationIgnored private var zegar: ZegarGry?
    /// Zapisany poziom czeka na „W drogę”: wtedy dziecko wraca do tego samego labiryntu i miejsca.
    @ObservationIgnored private var zapisanaPlansza: StanPlanszy?
    @ObservationIgnored private var odZapisu = 0.0

    init() {
        gra.naZdarzenie = { [weak self] z in self?.zdarzenie(z) }
        wczytaj()
    }

    // MARK: Zapis (nowość względem gry webowej)
    private static var plikZapisu: URL? {
        guard let katalog = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                          appropriateFor: nil, create: true) else { return nil }
        return katalog.appendingPathComponent("zapis.json")
    }

    /// Zapisuje ustawienia, album, koszulkę, limit czasu i bieżący labirynt (z położeniem osiołka i kotka).
    func zapisz() {
        var z = Zapis()
        z.zapisano = Date().timeIntervalSince1970
        z.jezyk = jezyk; z.motyw = motyw.rawValue; z.muzyka = muzyka; z.dzwieki = dzwieki
        z.koszulkaIndeks = koszulkaIndeks; z.kolorKoszulki = kolorKoszulki
        z.album = album; z.limit = limit
        z.poziom = poziom; z.trudnosc = gra.lab.trudnosc; z.pomocZRzedu = gra.lab.pomocZRzedu
        z.ostatniCharakter = gra.lab.ostatnia.charakter; z.ostatniRog = gra.lab.ostatnia.rog; z.ostatniZwodniczy = gra.lab.ostatnia.zwodniczy
        z.plansza = gra.lab.G.isEmpty ? zapisanaPlansza : gra.migawka()
        guard let plik = StanGry.plikZapisu, let dane = try? JSONEncoder().encode(z) else { return }
        try? dane.write(to: plik, options: .atomic)
        odZapisu = 0
    }

    private func wczytaj() {
        guard let plik = StanGry.plikZapisu, let dane = try? Data(contentsOf: plik),
              let z = try? JSONDecoder().decode(Zapis.self, from: dane) else { return }
        if let j = z.jezyk, Teksty.jezyki.contains(j) { jezyk = j }
        if let m = z.motyw, let w = WyborMotywu(rawValue: m) { motyw = w }
        muzyka = z.muzyka; dzwieki = z.dzwieki
        koszulkaIndeks = z.koszulkaIndeks.flatMap { Koszulka.wszystkie.indices.contains($0) ? $0 : nil }
        kolorKoszulki = z.kolorKoszulki
        album = z.album
        var l = z.limit
        l.poPowrocie(zapisano: z.zapisano, teraz: Date().timeIntervalSince1970)
        limit = l
        odswiezPrzerwe()
        poziom = max(1, z.poziom)
        gra.lab.trudnosc = max(1, z.trudnosc); gra.lab.pomocZRzedu = z.pomocZRzedu
        gra.lab.ostatnia = (z.ostatniCharakter, z.ostatniRog, z.ostatniZwodniczy)
        if let p = z.plansza {
            // Poziom skończony przed zamknięciem: po powrocie od razu następny.
            if p.faza == .koniec { poziom += 1 } else { zapisanaPlansza = p }
        }
    }

    // MARK: Przerwa dla dziecka
    private func przerwa() {
        limit.przerwa(teraz: Date().timeIntervalSince1970, &gra.lab.los)
        gra.puscWszystko()
        gra.pauza = true
        dzwiek.wstrzymaj()
        odswiezPrzerwe()
        zapisz()
    }

    /// Odpowiedź rodzica na pytanie o liczbę; przy błędzie nowe pytanie.
    func odblokuj(_ tekst: String) -> Bool {
        if limit.sprawdz(Int(tekst.trimmingCharacters(in: .whitespaces)), teraz: Date().timeIntervalSince1970) { klik(); return true }
        limit.nowePytanie(&gra.lab.los)
        odswiezPrzerwe()
        return false
    }

    /// „Koniec grania, przerwa”: gra zostaje zablokowana z nowym pytaniem.
    func koniecGrania() { klik(); limit.nowePytanie(&gra.lab.los); odswiezPrzerwe() }

    func przedluz(_ minuty: Int) {
        klik()
        limit.przedluz(minuty)
        odswiezPrzerwe()
        dzwiek.wznow()
        if ekran == .gra && nakladka == nil { gra.pauza = false }
        zapisz()
    }

    private func odswiezPrzerwe() {
        przerwaTrwa = limit.zablokowana
        pytanieRodzica = t("rodzicPytanie", ["s": Limit.slownie(limit.liczba, jezyk)])
    }

    let dzwiek = Syntezator.wspolny
    func klik() { dzwiek.klik() }

    func t(_ k: String, _ p: [String: CustomStringConvertible] = [:]) -> String { Teksty.t(jezyk, k, p) }

    var schematKolorow: ColorScheme? {
        switch motyw { case .system: return nil; case .jasny: return .light; case .ciemny: return .dark }
    }

    // MARK: Przebieg
    func zacznijPoziom() {
        nakladka = nil
        let w = max(ramka.width, 200), h = max(ramka.height, 200)
        gra.zacznijPoziom(szer: w, wys: h)
        gra.poziom = poziom
        brawoZa = 0
        dzwiek.nowaMelodia()
        odswiez()
        komunikat = t("start", ["n": poziom])
        zapisz()
    }

    /// „Graj”: najpierw szafa, jak w grze.
    func graj() {
        klik()
        dzwiek.wlaczMuzyke()
        ekran = .szafa
        uruchomZegar()
    }

    /// „Przebierz osiołka” w menu: szafa, a potem powrót do tego samego labiryntu.
    func przebierz() {
        klik()
        nakladka = nil
        gra.puscWszystko()
        ekran = .szafa
    }

    func losujKoszulke() {
        klik()
        let inne = Koszulka.wszystkie.indices.filter { $0 != koszulkaIndeks }
        koszulkaIndeks = inne.randomElement()
    }

    func wDroge() {
        klik()
        dzwiek.wlaczMuzyke()
        gra.pauza = false
        ekran = .gra
        if gra.lab.G.isEmpty, let p = zapisanaPlansza {
            // Powrót do zapisanego labiryntu w tym samym miejscu.
            zapisanaPlansza = nil
            gra.przywroc(p)
            gra.poziom = poziom
            dzwiek.nowaMelodia()
            odswiez()
        } else if gra.lab.G.isEmpty || gra.faza == .koniec {
            if ramka.width > 0 && ramka.height > 0 { zacznijPoziom() } else { czekaNaRamke = true }
        }
        uruchomZegar()
    }

    func ustawRamke(_ r: CGSize) {
        ramka = r
        if czekaNaRamke && r.width > 0 && r.height > 0 { czekaNaRamke = false; zacznijPoziom() }
    }

    func nastepnyPoziom() {
        klik()
        poziom += 1
        zacznijPoziom()
    }

    func pauza(cicho: Bool = false) {
        guard ekran == .gra else { return }
        if !cicho { klik() }
        if gra.faza == .koniec { nakladka = .brawo; return }
        gra.puscWszystko()
        gra.pauza = true
        nakladka = .menu
    }

    func wznow() { klik(); nakladka = nil; gra.pauza = false }

    func pokazAlbum() {
        klik()
        if gra.faza != .koniec { gra.pauza = true; gra.puscWszystko() }
        nakladka = .album
    }

    func zamknijAlbum() {
        klik()
        if gra.faza == .koniec { nakladka = .brawo } else { nakladka = nil; gra.pauza = false }
    }

    var napisAlbumu: String { t("album", ["n": album.naklejki.count, "m": AlbumNaklejek.wszystkie.count]) }

    /// „Podpowiedź”: łapki pokazują kawałek drogi albo komunikat, za ile sekund będzie gotowa.
    func pokazPodpowiedz() {
        guard nakladka == nil else { return }
        switch gra.pokazDroge() {
        case .pokazana: klik(); komunikat = t("podpPokazana"); odswiezPodp()
        case .zaWczesnie(let s): komunikat = t("podpZa", ["s": s])
        case nil: break
        }
    }

    private func odswiezPodp() {
        let za = gra.podpZostalo
        if za != podpZa {
            if za == 0 { podpGotowa += 1 }
            podpZa = za
        }
        let pasek = (gra.podpPostep * 50).rounded() / 50
        if pasek != podpPasek { podpPasek = pasek }
    }

    func nowaGra() {
        poziom = 1
        gra.lab.trudnosc = 1
        gra.lab.pomocZRzedu = 0
        // Nowa gra to także nowy, pusty album (na stronie album znika dopiero po zamknięciu karty).
        album = AlbumNaklejek()
        zacznijPoziom()
    }

    func doStartu() {
        nakladka = nil
        gra.pauza = false
        ekran = .start
        zatrzymajZegar()
    }

    // MARK: Pętla
    func uruchomZegar() {
        if zegar == nil { zegar = ZegarGry { [weak self] dt in self?.tik(dt) } }
        zegar?.start()
    }
    func zatrzymajZegar() { zegar?.stop() }

    private func tik(_ dt: Double) {
        // Limit liczy czas na planszy i w szafie (jak `liczLimit` w grze).
        if (ekran == .gra || ekran == .szafa) && !limit.zablokowana && limit.licz(min(0.05, dt)) { przerwa() }
        odZapisu += dt
        if odZapisu >= 5 { zapisz() }
        guard ekran == .gra, !gra.lab.G.isEmpty, !limit.zablokowana else { return }
        gra.tik(min(0.05, dt))
        if brawoZa > 0 {
            brawoZa -= dt
            if brawoZa <= 0 { nakladka = .brawo }
        }
        let s = Int(gra.czas)
        if s != sekunda { sekunda = s }
        odswiezPodp()
    }

    private func odswiez() {
        poziom = gra.poziom
        faza = gra.faza
        sekunda = Int(gra.czas)
        zebrane = gra.zebrane
        wersja = gra.lab.wersja
        odswiezPodp()
    }

    private func zdarzenie(_ z: Zdarzenie) {
        switch z {
        case .bum(let krzak):
            uderzenia += 1
            dzwiek.bum()
            if krzak { komunikat = t("krzakZamkniety") }
        case .krokRuchu: dzwiek.krokRuchu()
        case .radosc: dzwiek.radosc()
        case .serce:
            dzwiek.serce()
            zebrane = gra.zebrane
            komunikat = gra.serca.isEmpty ? t("wszystkoPowiedz") : t("zebranePowiedz", ["z": gra.serca.count])
        case .krzakZnika:
            dzwiek.radosc()
            komunikat = t("krzakZnika")
        case .kotekZnaleziony:
            faza = gra.faza; spotkania += 1
            komunikat = t("kotekJest")
        case .wygrana:
            dzwiek.brawo()
            album.dajNaklejke(&gra.lab.los)
            zapisz()
            faza = gra.faza; spotkania += 1
            brawoZa = gra.ograniczonyRuch ? 0.2 : gra.lab.trybGry == .plan ? 1.4 : 0.9
        }
    }

    // MARK: Napisy
    var napisZadania: String {
        t(gra.lab.trybGry == .plan ? "zadaniePlan" : faza == .szukaj ? "zadanieKotek" : "zadanieDomek")
    }
    var napisCzasu: String { t("czas", ["s": sekunda]) }
    var tytulBrawo: String { t(gra.lab.trybGry == .plan ? "brawoPlanH" : "brawoH") }
    var wynikBrawo: String { t("wynikCzas", ["s": Int(gra.czas)]) }
    var wynikPodp: String {
        var s = ""
        if gra.sercaN > 0 {
            let co = Teksty.surowy(jezyk, "przedmioty")[gra.przedmiot.rawValue][1].napis
            s = t("zebraneWynik", ["co": co, "n": gra.zebrane, "m": gra.sercaN]) + " "
        }
        // `opisPodp` z gry: bez podpowiedzi, z małą pomocą (najwyżej stopień 2) albo liczba podpowiedzi.
        let opis = gra.podpowiedzi == 0 ? t("bezPodp")
            : gra.podpMaks < 3 && gra.lab.trybGry != .plan ? t("malaPomoc") : t("podpN", ["n": gra.podpowiedzi])
        return s + opis
    }
    var wynikDrogi: String? {
        guard let p = gra.porownanie else { return nil }
        let n = Teksty.kroki(jezyk, p.najkrotsza.count - 1), tw = Teksty.kroki(jezyk, p.twoja.count - 1)
        return p.twoja.count <= p.najkrotsza.count ? t("drogaNajkrotsza", ["n": n]) : t("drogaTwoja", ["t": tw, "n": n])
    }
}

/// Pętla klatek zsynchronizowana z ekranem (CADisplayLink), jak `requestAnimationFrame` w grze.
final class ZegarGry: NSObject {
    private var link: CADisplayLink?
    private var ostatni: CFTimeInterval = 0
    private let krok: (Double) -> Void

    init(_ krok: @escaping (Double) -> Void) { self.krok = krok }

    func start() {
        guard link == nil else { return }
        ostatni = 0
        let l = CADisplayLink(target: self, selector: #selector(klatka(_:)))
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() { link?.invalidate(); link = nil }

    @objc private func klatka(_ l: CADisplayLink) {
        let teraz = l.timestamp
        let dt = ostatni == 0 ? 0 : teraz - ostatni
        ostatni = teraz
        krok(dt)
    }
}
