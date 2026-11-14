# Osiołek ratuje kotka w labiryncie

Natywna aplikacja na iPhone'a i iPada (SwiftUI): gra logiczna dla dzieci przeniesiona z
[gry.wilde.pl](https://gry.wilde.pl/osiolek-ratuje-kotka-w-labiryncie/). Osiołek szuka kotka w labiryncie
i prowadzi go do domku. Każdy poziom to nowy labirynt. Wszystko, co widać w grze, narysowało dziecko.

Aplikacja działa w pełni offline: bez internetu, reklam, analityki i logowania.

## Stan prac

| Etap | Zakres | Stan |
|---|---|---|
| 1 | Struktura projektu, generator labiryntu, ruch, kotek, domek, plansza z rysunkami, strzałki, palec, klawiatura, „Brawo” | gotowy, działa w symulatorze (iPhone 17, iOS 26.5) |
| 2 | Krzaczek i serduszko, przedmioty, podpowiedź stopniowana z odliczaniem, porównanie drogi, dźwięki i muzyka | gotowy |
| 3 | Tryb „Zaplanuj drogę z robotem” | odłożony |
| 4 | Ekran startowy, szafa z koszulkami, menu, „O grze” (wizytówka autora) | gotowy do sprawdzenia |
| 5 | Album naklejek, koniec rozdziału co 5 poziomów, wyjaśnienie krzaczka | gotowy do sprawdzenia |
| 6 | Limit czasu i przerwa z pytaniem dla rodzica, zapis ostatniego punktu | gotowy do sprawdzenia |

Poza zakresem (decyzja właściciela): gra „Osiołek rozsypał karty” (osobna gra), udostępnianie i linki do witryny,
instalacja PWA, pełny ekran, zdjęcia rysunków.

## Plan

**Wersja 1.0 (przed wydaniem):**
- [x] Dostęp z przewodnikiem: wskazówka dla rodzica w „Dla rodzica”, jak zablokować telefon w grze (funkcja iOS).
- [x] Lepsze wibracje: przy zebraniu przedmiotu, radość przy kotku i nowej naklejce, wyłącznik w ustawieniach.
- [x] Przygotowanie do App Store: manifest prywatności (`PrivacyInfo.xcprivacy`), teksty i formularze w `AppStore/`.
- [x] Uporządkowanie menu: dla dziecka start (Graj, Album, Przebierz, Dźwięk) i menu pauzy, ustawienia w „Dla rodzica”.
- [ ] Zrzuty ekranu, polityka prywatności na witrynie, konto Apple Developer, TestFlight (właściciel).

**Później (1.1 i dalej):** tryb „Zaplanuj drogę z robotem”, kontroler do gier, widżet na ekran główny,
strzałki po lewej albo prawej stronie, przycisk „Oceń grę” w „Dla rodzica” (za bramką, po wydaniu).

**Świadomie bez:** powiadomień, rankingów i Game Center, reklam, zakupów, analityki, aparatu, mikrofonu, lokalizacji.

## Uruchomienie w Xcode

1. Xcode 16 albo nowszy (projekt używa folderów synchronizowanych), iOS/iPadOS 18 lub nowszy.
2. Otwórz `OsiolekRatujeKotka.xcodeproj`.
3. W ustawieniach celu **OsiolekRatujeKotka → Signing & Capabilities** wybierz swój zespół (Team).
   Identyfikator pakietu to `pl.wilde.osiolek`; zmień go, jeśli jest zajęty.
4. Wybierz symulator (np. iPhone 16 albo iPad) albo podłączone urządzenie i naciśnij **Run** (⌘R).

Testy logiki (labirynt, ruch, podpowiedź, album, limit czasu, zapis): w Xcode **Product → Test** (⌘U).

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
Testy/          testy jednostkowe logiki (cel OsiolekRatujeKotkaTests w projekcie Xcode)
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

Limit czasu dla dzieci 4–8 lat (rozbudowany względem strony; zasady ustalone z właścicielem):
- rodzic ustawia w „Dla rodzica” jedną sesję (10/15/20/30 min, domyślnie 15) i cały dzień (20/30/45/60 min,
  domyślnie 30, nigdy więcej niż 60 — zalecenie WHO i AAP dla małych dzieci to najwyżej godzina ekranu dziennie);
- 2 minuty przed końcem dymek „Jeszcze chwilka, potem przerwa”; gra kończy się po bieżącym labiryncie,
  najpóźniej 2 minuty po czasie;
- po sesji przerwa co najmniej 30 minut, potem dziecko gra dalej samo; po limicie dziennym — do jutra;
- przedłużenia tylko za bramką rodzica (mnożenie z tabliczki, np. „Ile to 7 × 8?”, odpowiedź wpisana cyframi),
  coraz krótsze (10 albo 5, potem 5 albo 3), najwyżej dwa dziennie;
- licznik przetrwa zamknięcie aplikacji; pół godziny z zamkniętą aplikacją liczy się jako przerwa po sesji.

Test w Xcode bez czekania: **Product → Scheme → Edit Scheme… → Run → Arguments** i zaznacz `-szybkiLimit`
(tylko wersja Debug: czas limitu płynie 30× szybciej, 15 minut mija w 30 sekund).

## Bezpieczeństwo, prywatność, bateria i dostępność

- **Sieć:** gra nie łączy się z internetem. Jedyne odnośniki (wilde.pl, blog, gry.wilde.pl w „O grze”) otwierają
  Safari dopiero po bramce rodzica. Brak uprawnień (aparat, mikrofon, lokalizacja, zdjęcia, kontakty), brak
  zewnętrznych bibliotek, analityki, reklam i zakupów. Manifest prywatności: `PrivacyInfo.xcprivacy`.
- **Dane:** jeden plik `zapis.json` w katalogu aplikacji (Application Support); usunięcie aplikacji go usuwa.
- **Bateria:** plansza odświeża się tylko przy ruchu (do 120 klatek na ekranach ProMotion), przy samym pulsowaniu
  30 razy na sekundę, a w spoczynku i pod nakładkami wcale. Postacie z obwódką są rysowane raz i trzymane jako
  obrazki. Przy wyłączonej muzyce i dźwiękach silnik dźwięku stoi; w tle gra się zatrzymuje. Zapis co 10 s gry.
- **Dostępność:** VoiceOver (opisy przycisków i planszy w 8 językach), ograniczenie ruchu (bez animacji podskoków,
  pulsowania i rysowania), kontrast co najmniej 4,5:1 w obu motywach, przyciski co najmniej 44 pt, większa czcionka
  systemowa do „xxLarge”, klawiatura sprzętowa, sterowanie bez precyzyjnych gestów.

## Biblioteki i licencje

Aplikacja nie używa żadnych zewnętrznych bibliotek. Korzysta tylko z frameworków systemowych Apple:
SwiftUI, UIKit (pętla klatek `CADisplayLink`, klawiatura sprzętowa, kolory zależne od motywu), AVFoundation (syntezator dźwięku), Observation i Foundation.
Font Chalkboard SE jest fontem systemowym iOS. Testy używają XCTest. Zdjęcia rysunków w `Zasoby/Zdjecia/` to
kartki narysowane przez córkę autora (te same co na gry.wilde.pl).

Narzędzia pomocnicze (nie trafiają do aplikacji): Node.js i Playwright (Apache-2.0) do eksportu danych i ikony.

Rysunki: © autorzy gry (dziecko i tata), te same co w grze na gry.wilde.pl.
