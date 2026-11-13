# Osiołek ratuje kotka w labiryncie

Natywna aplikacja na iPhone'a i iPada (SwiftUI): gra logiczna dla dzieci przeniesiona z
[gry.wilde.pl](https://gry.wilde.pl/osiolek-ratuje-kotka-w-labiryncie/). Osiołek szuka kotka w labiryncie
i prowadzi go do domku. Każdy poziom to nowy labirynt. Wszystko, co widać w grze, narysowało dziecko.

Aplikacja działa w pełni offline: bez internetu, reklam, analityki i logowania.

## Stan prac

| Etap | Zakres | Stan |
|---|---|---|
| 1 | Struktura projektu, generator labiryntu, ruch, kotek, domek, plansza z rysunkami, strzałki, palec, klawiatura, „Brawo” | gotowy, działa w symulatorze (iPhone 17, iOS 26.5) |
| 2 | Krzaczek i serduszko, przedmioty, podpowiedź stopniowana z odliczaniem, porównanie drogi, dźwięki i muzyka | gotowy do sprawdzenia; brakuje wyjaśnienia krzaczka |
| 3 | Tryb „Zaplanuj drogę z robotem” | do zrobienia |
| 4 | Ekran startowy 1:1, szafa z koszulkami, menu, „O grze” | szafa i menu gotowe do sprawdzenia; brakuje „O grze” i przycisku trybu z robotem |
| 5 | Album naklejek, koniec rozdziału co 5 poziomów | album gotowy do sprawdzenia; brakuje końca rozdziału |
| 6 | Limit czasu i przerwa z pytaniem dla rodzica, zapis ostatniego punktu | gotowy do sprawdzenia |

Poza zakresem (decyzja właściciela): gra „Osiołek rozsypał karty” (osobna gra), udostępnianie i linki do witryny,
instalacja PWA, pełny ekran, zdjęcia rysunków.

## Uruchomienie w Xcode

1. Xcode 16 albo nowszy (projekt używa folderów synchronizowanych), iOS/iPadOS 18 lub nowszy.
2. Otwórz `OsiolekRatujeKotka.xcodeproj`.
3. W ustawieniach celu **OsiolekRatujeKotka → Signing & Capabilities** wybierz swój zespół (Team).
   Identyfikator pakietu to `pl.wilde.osiolek`; zmień go, jeśli jest zajęty.
4. Wybierz symulator (np. iPhone 16 albo iPad) albo podłączone urządzenie i naciśnij **Run** (⌘R).

Testy logiki (generator labiryntu, ruch, wygrana) działają bez symulatora:

```bash
swift test
```

## Dane z gry webowej

Teksty (8 języków) i punkty rysunków nie są przepisywane ręcznie. Generuje je skrypt z pliku gry:

```bash
node narzedzia/eksport-z-gry.mjs ../gry/src/assets/gry/osiolek-ratuje-kotka-w-labiryncie/osiolek.html
```

Ikona aplikacji (osiołek i kotek z rysunków dziecka) powstaje w przeglądarce Chromium tymi samymi funkcjami
rysowania co w grze:

```bash
node narzedzia/ikona.mjs ../gry/src/assets/gry/osiolek-ratuje-kotka-w-labiryncie/osiolek.html
```

## Architektura

```
OsiolekRatujeKotka/
  App/       OsiolekApp (wejście), StanGry (@Observable: ekrany, nakładki, ustawienia, pętla klatek CADisplayLink)
  Logika/    czysty Swift bez SwiftUI, przeniesiony 1:1 z gry (te same nazwy funkcji):
             Labirynt (budowa planszy, BFS, krzaczek), Rozgrywka (ruch, kotek, wygrana, trudność),
             Podpowiedz (podpowiedź stopniowana), Album (naklejki), Limit (przerwa dla dziecka),
             Zapis (stan między uruchomieniami), Losowanie
  Rysunki/   Pioro (płótno z API jak w HTML na GraphicsContext, krzywe przez punkty), Postacie, Plansza
  Widoki/    StartView, SzafaView (koszulki, paleta), GraView (pasek, plansza, strzałki), AlbumView (album, tacka),
             Nakladki (menu, „Brawo”), KlawiaturaSprzetowa, Styl (kolory, przyciski „kreska”)
  Dzwiek/    Syntezator (dźwięki i muzyka z tonów, bez plików, jak Web Audio w grze)
  Teksty/    Jezyk (teksty z Teksty.json, odmiana „kroki”)
  Zasoby/    Teksty.json, Rysunki.json, Assets.xcassets
Package.swift   logika jako biblioteka do testów (także na Linuksie)
Testy/          testy jednostkowe logiki
narzedzia/      eksport danych i ikony z gry webowej
```

- **Logika** nie zna SwiftUI, więc da się ją testować bez symulatora. `Rozgrywka.tik(dt)` to jedna klatka gry;
  wywołuje ją pętla zsynchronizowana z ekranem.
- **Rysowanie**: klasa `Plotno` udaje płótno HTML (`beginPath`, `bezierCurveTo`, `save`/`restore`…) na
  `GraphicsContext`, dzięki czemu funkcje rysunków (`osiolekKodem`, `rysujTlo`, `wzorSciany`…) są przeniesione
  linijka po linijce. Tło planszy rysuje się raz na poziom, postacie co klatkę.
- **Sterowanie**: przytrzymanie strzałki, palec na planszy (osiołek idzie w stronę palca), klawiatura sprzętowa
  na iPadzie (strzałki, W A S D, P/Esc — pauza), wibracja przy uderzeniu w ścianę i przy spotkaniu z kotkiem.
  Na niskim ekranie poziomo strzałki stoją obok planszy.

## Zapis i przerwa dla dziecka

Gra webowa niczego nie zapisuje. Aplikacja pamięta między uruchomieniami (plik `zapis.json` w Application Support,
tylko na urządzeniu): bieżący labirynt z położeniem osiołka i kotka, poziom i trudność, album, koszulkę, ustawienia
oraz stan limitu czasu. Zapis następuje przy starcie poziomu, po wygranej, co 5 s gry i przy zejściu aplikacji z ekranu.

Limit czasu działa jak na stronie: po 15 minutach gry (plansza i szafa) pojawia się przerwa, a odblokowuje ją rodzic,
wpisując cyframi liczbę zapisaną słowami. Licznik przetrwa zamknięcie aplikacji, więc ponowne uruchomienie nie omija
przerwy. Prawdziwa przerwa, czyli co najmniej godzina od zatrzymania gry albo od zamknięcia aplikacji, przywraca pełne
15 minut.

## Biblioteki i licencje

Aplikacja nie używa żadnych zewnętrznych bibliotek. Korzysta tylko z frameworków systemowych Apple:
SwiftUI, UIKit (pętla klatek `CADisplayLink`, klawiatura sprzętowa, kolory zależne od motywu), AVFoundation (syntezator dźwięku), Observation i Foundation.
Font Chalkboard SE jest fontem systemowym iOS. Testy używają XCTest.

Narzędzia pomocnicze (nie trafiają do aplikacji): Node.js i Playwright (Apache-2.0) do eksportu danych i ikony.

Rysunki: © autorzy gry (dziecko i tata), te same co w grze na gry.wilde.pl.
