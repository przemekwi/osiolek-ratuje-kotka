# Osiołek ratuje kotka — kontekst dla kolejnych sesji

Natywna gra iOS/iPadOS (SwiftUI, iOS 18+) przeniesiona z gry webowej na gry.wilde.pl
(`gry/src/assets/gry/osiolek-ratuje-kotka-w-labiryncie/osiolek.html` w repo `przemekwi/gry`).
Właściciel: Przemysław Wilde. Rysunki: jego córka. Architektura, plan i opis funkcji: `README.md`.

## Zasady pracy (ustalone z właścicielem)
- Komunikacja po polsku. Commity po polsku, w trybie rozkazującym, **bez atrybutów AI**
  (`Co-Authored-By`, wzmianki o Claude) w commitach, pull requestach i plikach.
- Gra **nie łączy się z siecią** i nie zbiera danych. Bez reklam, zakupów, kont, analityki, powiadomień,
  Game Center i uprawnień (aparat, mikrofon, lokalizacja). Jedyne linki (w „O grze”) — za bramką rodzica.
- Tylko frameworki Apple, bez zewnętrznych bibliotek. Grafiki wyłącznie z rysunków córki
  (punkty eksportowane z gry webowej: `narzedzia/eksport-z-gry.mjs`; zdjęcia kartek w `Zasoby/Zdjecia/`).
- Logika (`OsiolekRatujeKotka/Logika/`) jest czystym Swiftem przeniesionym 1:1 z gry webowej (te same nazwy).
  Zmiany w logice — z testem w `Testy/` (⌘U, cel `OsiolekRatujeKotkaTests`).
- Teksty: gra webowa → `Zasoby/Teksty.json` (eksport), teksty tylko aplikacji → `Teksty/TekstyAplikacji.swift`
  (8 języków; polski źródłowy, tłumaczenia maszynowe do sprawdzenia przez człowieka).
- Tekst od właściciela poprawiamy tylko w interpunkcji; inne zmiany zgłaszamy jako „przed → po”.
- Tryb dla dziecka zawsze włączony (bez zegara na pasku, rozdział co 5 poziomów).
- Środowisko chmurowe nie ma Xcode ani symulatora: kodu Swift nie da się tu zbudować. Po każdej zmianie
  właściciel buduje w Xcode (Integrate → Pull, ⌘R, ⌘U) i przysyła zrzuty błędów albo ekranów.

## Wersje
- Każda zmiana podnosi wersję (`App/Wersja.swift`, ten sam numer w grze webowej: `WERSJA` w `osiolek.html`):
  nowy tryb albo przebudowa → całość (2.0), większa zmiana → o 0.1 (1.2), mała zmiana → litera (1.1a, 1.1b…).
- App Store przyjmuje tylko cyfry: `MARKETING_VERSION` = numer z literą jako trzecią liczbą (1.1a → 1.1.1);
  `CURRENT_PROJECT_VERSION` (kompilacja) rośnie o 1 przy każdej zmianie wersji.
- Każdą wersję dopisujemy do „Historii wersji” w `README.md`.

## Kluczowe decyzje
- Poza zakresem: gra w karty „Osiołek rozsypał karty” (osobna gra), udostępnianie, PWA, wyzwania z linku,
  plansza „Widzisz krótszą drogę?” po wygranej (usunięta).
- Menu: dla dziecka start (Graj, Album, Przebierz osiołka, Dźwięk) i menu pauzy (Graj dalej, Przebierz,
  Album, Strzałki, Dźwięk, Wyjdź); pasek gry: Podpowiedź i Menu. Ustawienia w „Dla rodzica”:
  „O grze” bez bramki; za bramką limity, wibracje, Dostęp z przewodnikiem, tryb dla dorosłych
  i rozwijane „Ustawienia gry” (muzyka, dźwięki, kolory, język, nowa gra z potwierdzeniem).
- Bramka rodzica: mnożenie z tabliczki (6–9 × 6–9) wpisywane na klawiaturze cyfr w grze, bez podpowiedzi.
  Tryb dla dorosłych: druga bramka (12–19 × 6–9), ostrzeżenie, limity wyłączone do północy.
- Limit czasu: sesja 10/15/20/30 min (domyślnie 15), dzień 20/30/45/60 min (domyślnie 30, nigdy > 60),
  ostrzeżenie 2 min przed końcem, dokończenie labiryntu (najwyżej 2 min), przerwa 30 min, najwyżej
  2 przedłużenia dziennie.
- „O grze”: Autor: Przemysław Wilde i Córcia, opis właściciela, linki: Wilde.pl, wpis na blogu o grze,
  gry.wilde.pl; rysunki za przyciskiem (zdjęcie kartki → przenikanie → rysowanie).
- Trudność dopasowana do dziecka (rośnie, gdy radzi sobie samo; stoi po dużej pomocy; spada po dwóch trudnych).
  Krzaczki z serduszkami: od stopnia 5 jeden, od 9 dwa, od 13 trzy — nigdy więcej; serduszka po kolei,
  każda plansza przechodzi symulację przejścia (`daSiePrzejsc`). Gra webowa ma tę samą logikę.
- Gra webowa (repo `gry`) wygląda i działa jak aplikacja (iOS jest wzorcem); rozwijamy tylko aplikację.
- Identyfikator pakietu: `pl.wilde.osiolek-ratuje-kotka` (po pierwszej wysyłce niezmienny).
- Konto Apple Developer: Individual / Sole Proprietor (w sklepie widoczne imię i nazwisko).

## Stan (14.11.2026)
- Wersja 1.0 gotowa w kodzie; pull request: przemekwi/osiolek-ratuje-kotka#1
  (`claude/relaxed-mayer-bdg0iv` → `main`). Ostatnie zmiany (bramka z klawiaturą, nowe „O grze”,
  tryb dla dorosłych, usunięcie porównania drogi, nowy identyfikator) nie były jeszcze budowane przez właściciela.

## Następne kroki
1. Właściciel: Pull, wybór zespołu w Signing & Capabilities (nowy identyfikator), ⌘U (oczekiwane 24 testy),
   test na iPhonie i z córką; poprawki zgłaszane zrzutami.
2. Scalenie PR #1 do `main` (decyzja właściciela).
3. Formalności: konto Apple Developer (opłata), konsultacja statusu przedsiębiorcy w UE (DSA) z księgową,
   publikacja polityki prywatności (tekst: `AppStore/polityka-prywatnosci.md`; według zasad witryn WILDE
   wspólna polityka mieszka na przemyslaw.wilde.pl — repo `przemyslaw.wilde`, osobna decyzja właściciela).
4. Materiały: zrzuty (iPhone 17 Pro Max, iPad Pro 13″; lista w `AppStore/zrzuty.md`), opis i formularze
   z `AppStore/` (klasyfikacja 4+, Dla dzieci 6–8 lat, „Brak gromadzenia danych”).
5. Wysyłka: App Store Connect → nowa aplikacja → Xcode Archive → TestFlight (rodzina) → przegląd.
   Dostępność: najpierw Polska, po 1–2 tygodniach cały świat bez Chin kontynentalnych (licencja na gry).
6. Wersja 1.1: tryb „Zaplanuj drogę z robotem” (z gry webowej), kontroler do gier, widżet, wybór strony
   strzałek, przycisk „Oceń grę” za bramką (po publikacji, wymaga identyfikatora aplikacji w App Store).
