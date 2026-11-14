import Foundation

/// Rodzaj blokady: przerwa po sesji albo koniec grania na dziś.
enum Blokada: String, Codable { case brak, sesja, dzien }

/// Co pętla gry ma zrobić po doliczeniu czasu.
enum KrokLimitu: Equatable { case nic, ostrzezenie, dokonczLabirynt, przerwa }

/// Limit czasu dla dzieci 4–8 lat (rozbudowany względem `LIMIT` z gry webowej, zasady ustalone z właścicielem):
/// - rodzic ustawia sesję (10/15/20/30 min, domyślnie 15) i cały dzień (20/30/45/60 min, domyślnie 30, nigdy więcej
///   niż 60 — zalecenie WHO i Amerykańskiej Akademii Pediatrii dla małych dzieci to najwyżej godzina ekranu dziennie);
/// - 2 minuty przed końcem łagodne ostrzeżenie; gra kończy się po bieżącym labiryncie, najpóźniej 2 minuty po czasie;
/// - po sesji przerwa co najmniej 30 minut, potem dziecko gra dalej samo; po limicie dziennym — do następnego dnia;
/// - przedłużenia wybiera rodzic za bramką (mnożenie z tabliczki, odpowiedź wpisana cyframi), coraz krótsze, najwyżej dwa dziennie.
/// Stan jest zapisywany, więc ponowne uruchomienie aplikacji nie omija przerwy.
struct Limit: Codable, Equatable {
    static let OPCJE_SESJI = [10, 15, 20, 30]
    static let OPCJE_DNIA = [20, 30, 45, 60]
    static let PRZERWA_PO_SESJI = 30.0 * 60
    static let OSTRZEZENIE = 120.0
    static let DOGRYWKA = 120.0
    static let MAKS_PRZEDLUZEN = 2

    var sesjaMin = 15
    var dzienMin = 30
    /// Dzień, którego dotyczy `dzisiaj` (rrrr-mm-dd).
    var dzien = ""
    var dzisiaj = 0.0
    var sesja = 0.0
    var limitSesji = 15.0 * 60
    var przedluzeniaDzis = 0
    var ostatnie = 0
    var blokada: Blokada = .brak
    /// Chwila zatrzymania gry (sekundy od 1970).
    var od = 0.0
    var ostrzezono = false
    var dogrywka = 0.0
    /// Bramka rodzica: a × b (obie liczby 6–9) — dla dorosłego chwila, dla dziecka 4–8 lat za trudne.
    var a = 0
    var b = 0

    init() {}

    // Starszy zapis albo brak pól nie kasuje reszty zapisu: brakujące pola dostają wartości domyślne.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Limit()
        sesjaMin = (try? c.decode(Int.self, forKey: .sesjaMin)) ?? d.sesjaMin
        dzienMin = (try? c.decode(Int.self, forKey: .dzienMin)) ?? d.dzienMin
        dzien = (try? c.decode(String.self, forKey: .dzien)) ?? d.dzien
        dzisiaj = (try? c.decode(Double.self, forKey: .dzisiaj)) ?? d.dzisiaj
        sesja = (try? c.decode(Double.self, forKey: .sesja)) ?? d.sesja
        limitSesji = (try? c.decode(Double.self, forKey: .limitSesji)) ?? Double(sesjaMin) * 60
        przedluzeniaDzis = (try? c.decode(Int.self, forKey: .przedluzeniaDzis)) ?? 0
        ostatnie = (try? c.decode(Int.self, forKey: .ostatnie)) ?? 0
        blokada = (try? c.decode(Blokada.self, forKey: .blokada)) ?? .brak
        od = (try? c.decode(Double.self, forKey: .od)) ?? 0
        ostrzezono = (try? c.decode(Bool.self, forKey: .ostrzezono)) ?? false
        dogrywka = (try? c.decode(Double.self, forKey: .dogrywka)) ?? 0
        a = (try? c.decode(Int.self, forKey: .a)) ?? 0
        b = (try? c.decode(Int.self, forKey: .b)) ?? 0
    }

    var zablokowana: Bool { blokada != .brak }
    var zostaloDnia: Double { max(0, Double(dzienMin) * 60 - dzisiaj) }
    /// Czas do końca: sesji albo dnia, co pierwsze.
    var zostalo: Double { min(limitSesji - sesja, zostaloDnia) }
    var czasMinal: Bool { blokada == .brak && zostalo <= 0 }
    var odpowiedz: Int { a * b }

    static func kluczDnia(_ data: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: data)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Nowy dzień: licznik dzienny od zera, a koniec grania z wczoraj przestaje obowiązywać.
    mutating func nowyDzien(_ klucz: String) {
        guard klucz != dzien else { return }
        dzien = klucz; dzisiaj = 0; przedluzeniaDzis = 0; ostatnie = 0
        if blokada == .dzien { blokada = .brak; nowaSesja() }
    }

    mutating func nowaSesja() {
        sesja = 0; limitSesji = Double(sesjaMin) * 60; ostrzezono = false; dogrywka = 0
    }

    /// Liczy czas gry. `wLabiryncie`: dziecko jest w trakcie poziomu (wtedy może go dokończyć).
    mutating func licz(_ dt: Double, wLabiryncie: Bool) -> KrokLimitu {
        guard blokada == .brak else { return .nic }
        sesja += dt; dzisiaj += dt
        if zostalo <= 0 {
            // Dogrywka to czas, który minął po przekroczeniu limitu (sesji albo dnia): najwyżej 2 minuty na dokończenie.
            dogrywka = -zostalo
            if wLabiryncie && dogrywka < Limit.DOGRYWKA { return .dokonczLabirynt }
            return .przerwa
        }
        if !ostrzezono && zostalo <= Limit.OSTRZEZENIE { ostrzezono = true; return .ostrzezenie }
        return .nic
    }

    mutating func przerwa(teraz: Double, _ los: inout Los) {
        blokada = zostaloDnia <= 0 ? .dzien : .sesja
        od = teraz
        nowePytanie(&los)
    }

    mutating func nowePytanie(_ los: inout Los) {
        a = 6 + los.ri(4); b = 6 + los.ri(4)
    }

    func sprawdz(_ o: Int?) -> Bool { o == odpowiedz }

    /// Po 30 minutach przerwy (i gdy zostało coś z dnia) dziecko może grać dalej samo.
    func przerwaMinela(teraz: Double) -> Bool { blokada == .sesja && teraz - od >= Limit.PRZERWA_PO_SESJI && zostaloDnia > 0 }

    mutating func wznowPoPrzerwie() { blokada = .brak; nowaSesja() }

    /// Przedłużenia do wyboru: najpierw 10 albo 5 min, potem 5 (po 10) albo 3; najwyżej dwa dziennie i nie ponad limit dnia.
    var opcjePrzedluzenia: [Int] {
        guard blokada == .sesja, przedluzeniaDzis < Limit.MAKS_PRZEDLUZEN, zostaloDnia >= 60 else { return [] }
        let baza = ostatnie == 0 ? [10, 5] : ostatnie >= 10 ? [5] : [3]
        let maks = Int(zostaloDnia / 60)
        var wynik: [Int] = []
        for m in baza.map({ min($0, maks) }) where !wynik.contains(m) { wynik.append(m) }
        return wynik
    }

    mutating func przedluz(_ minuty: Int) {
        blokada = .brak
        limitSesji = sesja + Double(minuty) * 60
        przedluzeniaDzis += 1
        ostatnie = minuty
        ostrzezono = false
        dogrywka = 0
    }

    /// Ustawienia rodzica. Gdy nowy limit dzienny zostawia jeszcze czas, koniec grania na dziś przestaje obowiązywać.
    mutating func ustaw(sesja s: Int, dzien d: Int) {
        sesjaMin = Limit.OPCJE_SESJI.contains(s) ? s : 15
        dzienMin = min(60, Limit.OPCJE_DNIA.contains(d) ? d : 30)
        if blokada == .brak && przedluzeniaDzis == 0 { limitSesji = Double(sesjaMin) * 60 }
        if blokada == .dzien && zostaloDnia > 0 { blokada = .brak; nowaSesja() }
    }

    /// Po odczytaniu zapisu: nowy dzień zeruje licznik dzienny, a co najmniej 30 minut z zamkniętą aplikacją
    /// (gdy gra nie była zablokowana) to przerwa — zaczyna się nowa sesja.
    mutating func poPowrocie(zapisano: Double, teraz: Double, dzien klucz: String) {
        nowyDzien(klucz)
        if blokada == .brak && teraz - zapisano >= Limit.PRZERWA_PO_SESJI { nowaSesja() }
    }

    /// Liczba 21–49 słowami w języku gry (`SLOWA` z gry).
    static func slownie(_ n: Int, _ jezyk: String) -> String {
        let d = n / 10, j = n % 10
        switch jezyk {
        case "pl":
            return ["", "", "dwadzieścia", "trzydzieści", "czterdzieści"][d]
                + (j != 0 ? " " + ["", "jeden", "dwa", "trzy", "cztery", "pięć", "sześć", "siedem", "osiem", "dziewięć"][j] : "")
        case "en":
            return ["", "", "twenty", "thirty", "forty"][d]
                + (j != 0 ? "-" + ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"][j] : "")
        case "fr":
            let dz = ["", "", "vingt", "trente", "quarante"][d]
            return dz + (j == 1 ? " et un" : j != 0 ? "-" + ["", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf"][j] : "")
        case "es":
            let u = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"][j]
            if n < 30 {
                return ["veinte", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis", "veintisiete",
                        "veintiocho", "veintinueve"][j]
            }
            return ["", "", "", "treinta", "cuarenta"][d] + (j != 0 ? " y " + u : "")
        case "de":
            return (j != 0 ? ["", "ein", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun"][j] + "und" : "")
                + ["", "", "zwanzig", "dreißig", "vierzig"][d]
        case "it":
            // Dziesiątka traci samogłoskę przed „uno” i „otto” (ventuno, trentotto), a „tre” na końcu ma akcent.
            let dz = ["", "", "venti", "trenta", "quaranta"][d]
            let u = ["", "uno", "due", "tré", "quattro", "cinque", "sei", "sette", "otto", "nove"][j]
            return j == 1 || j == 8 ? String(dz.dropLast()) + u : dz + u
        default: // zh-Hans, zh-Hant
            return ["", "", "二", "三", "四"][d] + "十" + (j != 0 ? ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"][j] : "")
        }
    }
}
