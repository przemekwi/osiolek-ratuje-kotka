import SwiftUI
import UIKit
import Observation

enum Ekran { case start, szafa, gra }
enum Nakladka: Equatable { case menu, brawo }
enum WyborMotywu: String, CaseIterable { case system, jasny, ciemny }

/// Stan aplikacji widoczny dla SwiftUI. Logika poziomu żyje w `Rozgrywka`; tu są ekrany, nakładki,
/// ustawienia i napisy, które zmieniają się rzadko (nie co klatkę), żeby nie przeliczać całego widoku 60× na sekundę.
@Observable
final class StanGry {
    var ekran: Ekran = .start
    var nakladka: Nakladka?
    var jezyk: String = Teksty.jezykUrzadzenia()
    var motyw: WyborMotywu = .system
    var koszulka: Koszulka?

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

    @ObservationIgnored let gra = Rozgrywka()
    /// Rozmiar ramki planszy (punkty) — do wielkości labiryntu i geometrii.
    @ObservationIgnored var ramka: CGSize = .zero
    @ObservationIgnored private var brawoZa = 0.0
    /// Nowy poziom czeka na pierwszy pomiar ramki planszy (wielkość labiryntu zależy od miejsca na ekranie).
    @ObservationIgnored private var czekaNaRamke = false
    @ObservationIgnored private var zegar: ZegarGry?

    init() {
        gra.naZdarzenie = { [weak self] z in self?.zdarzenie(z) }
    }

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
        odswiez()
        komunikat = t("start", ["n": poziom])
    }

    func wDroge() {
        ekran = .gra
        if gra.lab.G.isEmpty || gra.faza == .koniec {
            if ramka.width > 0 && ramka.height > 0 { zacznijPoziom() } else { czekaNaRamke = true }
        }
        uruchomZegar()
    }

    func ustawRamke(_ r: CGSize) {
        ramka = r
        if czekaNaRamke && r.width > 0 && r.height > 0 { czekaNaRamke = false; zacznijPoziom() }
    }

    func nastepnyPoziom() {
        poziom += 1
        zacznijPoziom()
    }

    func pauza() {
        guard ekran == .gra else { return }
        if gra.faza == .koniec { nakladka = .brawo; return }
        gra.puscWszystko()
        gra.pauza = true
        nakladka = .menu
    }

    func wznow() { nakladka = nil; gra.pauza = false }

    func nowaGra() {
        poziom = 1
        gra.lab.trudnosc = 1
        gra.lab.pomocZRzedu = 0
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
        guard ekran == .gra, !gra.lab.G.isEmpty else { return }
        gra.tik(min(0.05, dt))
        if brawoZa > 0 {
            brawoZa -= dt
            if brawoZa <= 0 { nakladka = .brawo }
        }
        let s = Int(gra.czas)
        if s != sekunda { sekunda = s }
    }

    private func odswiez() {
        poziom = gra.poziom
        faza = gra.faza
        sekunda = Int(gra.czas)
        zebrane = gra.zebrane
        wersja = gra.lab.wersja
    }

    private func zdarzenie(_ z: Zdarzenie) {
        switch z {
        case .bum(let krzak):
            uderzenia += 1
            if krzak { komunikat = t("krzakZamkniety") }
        case .krokRuchu, .radosc: break
        case .serce:
            zebrane = gra.zebrane
            komunikat = gra.serca.isEmpty ? t("wszystkoPowiedz") : t("zebranePowiedz", ["z": gra.serca.count])
        case .krzakZnika:
            komunikat = t("krzakZnika")
        case .kotekZnaleziony:
            faza = gra.faza; spotkania += 1
            komunikat = t("kotekJest")
        case .wygrana:
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
        return s + (gra.podpowiedzi == 0 ? t("bezPodp") : t("podpN", ["n": gra.podpowiedzi]))
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
