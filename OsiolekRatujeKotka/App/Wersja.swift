import Foundation

/// Numer wersji gry pokazywany w „O grze” (ten sam w grze webowej na gry.wilde.pl).
/// Zasada: nowy tryb albo przebudowa — całość (2.0); większa zmiana — o jedną dziesiątą (1.2);
/// mała zmiana — litera (1.1a, 1.1b…). App Store przyjmuje tylko cyfry, więc w ustawieniach projektu
/// (MARKETING_VERSION) litera jest trzecią liczbą: 1.1 → 1.1, 1.1a → 1.1.1, 1.1b → 1.1.2. Przy każdej zmianie
/// wersji rośnie też numer kompilacji (CURRENT_PROJECT_VERSION).
enum Wersja {
    static let numer = "1.1"
}
