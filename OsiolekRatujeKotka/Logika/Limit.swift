import Foundation

/// Limit czasu dla dzieci (`LIMIT` z gry webowej).
/// Po 15 minutach grania (plansza i szafa) gra się zatrzymuje. Odblokowuje rodzic: wpisuje cyframi liczbę 21–49 zapisaną
/// słowami, czego dziecko w tym wieku jeszcze nie przeczyta. Przedłużenia wybiera rodzic; w trybie dla dziecka każde
/// kolejne jest krótsze. Po prawdziwej przerwie (co najmniej godzina od zatrzymania gry) wraca pełny limit.
/// W aplikacji stan limitu jest zapisywany, więc ponowne uruchomienie nie obchodzi przerwy.
struct Limit: Codable, Equatable {
    static let LIMIT_S = 15.0 * 60
    static let PRZERWA_S = 60.0 * 60

    var uplynelo = 0.0
    var liczba = 0
    var zablokowana = false
    var limit = Limit.LIMIT_S
    var przedluzenia = 0
    var razem = 0.0
    /// Chwila zatrzymania gry (sekundy od 1970).
    var od = 0.0
    var ostatnie = 0
    var poPrzerwie = false

    /// Liczy czas gry; zwraca true, gdy właśnie trzeba zrobić przerwę.
    mutating func licz(_ dt: Double) -> Bool {
        guard !zablokowana else { return false }
        uplynelo += dt; razem += dt
        return uplynelo >= limit
    }

    mutating func nowePytanie(_ los: inout Los) {
        liczba = 21 + los.ri(29)
        if liczba % 10 == 0 { liczba += 1 }
    }

    mutating func przerwa(teraz: Double, _ los: inout Los) {
        zablokowana = true
        od = teraz
        nowePytanie(&los)
    }

    /// Odpowiedź rodzica. Po co najmniej godzinie od zatrzymania gry liczy się jak prawdziwa przerwa.
    mutating func sprawdz(_ odpowiedz: Int?, teraz: Double) -> Bool {
        guard odpowiedz == liczba else { return false }
        if teraz - od >= Limit.PRZERWA_S { przedluzenia = 0; razem = 0; ostatnie = 0; poPrzerwie = true }
        return true
    }

    /// Przedłużenia do wyboru w trybie dla dziecka (gra zawsze w nim działa): po przerwie pełne 15 min,
    /// potem 10 albo 5, po 10 — 5, po 5 — 3, potem po 3.
    var opcjePrzedluzenia: [Int] {
        if poPrzerwie { return [Int(Limit.LIMIT_S / 60)] }
        if ostatnie == 0 || ostatnie >= 15 { return [10, 5] }
        return ostatnie >= 10 ? [5] : [3]
    }

    /// „Pamiętaj: to ograniczenie jest dla dobra dziecka” — gdy przedłużenia doszły do 3 minut.
    var pokazDobro: Bool { !poPrzerwie && ostatnie == 3 }

    mutating func przedluz(_ minuty: Int) {
        limit = Double(minuty) * 60
        uplynelo = 0
        przedluzenia += 1
        poPrzerwie = false
        ostatnie = minuty
        zablokowana = false
    }

    /// Po odczytaniu zapisu: gdy aplikacja była zamknięta co najmniej godzinę, a gra nie była zablokowana,
    /// to była prawdziwa przerwa — limit wraca do pełnych 15 minut.
    mutating func poPowrocie(zapisano: Double, teraz: Double) {
        if !zablokowana && teraz - zapisano >= Limit.PRZERWA_S { self = Limit() }
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
