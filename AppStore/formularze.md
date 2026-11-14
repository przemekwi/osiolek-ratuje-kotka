# Formularze w App Store Connect

## Prywatność aplikacji (App Privacy)
- „Czy Ty lub Twoi partnerzy zbieracie dane z tej aplikacji?” → **Nie, nie zbieramy danych**.
- W karcie aplikacji pojawi się etykieta „Brak gromadzenia danych” („Data Not Collected”).
- Manifest `OsiolekRatujeKotka/PrivacyInfo.xcprivacy` mówi to samo: bez śledzenia, bez zbierania danych.

## Klasyfikacja wieku (Age Rating)
Na każde pytanie o treści (przemoc, strach, wulgaryzmy, treści medyczne, alkohol, hazard, treści seksualne):
**Brak**. Dalej:
- Nieograniczony dostęp do internetu: **Nie** (linki do witryn tylko za bramką rodzica, otwierane w Safari).
- Treści tworzone przez użytkowników, czat, kontakty z innymi: **Nie**.
- Zakupy w aplikacji, reklamy: **Nie**.
- Kontrola rodzicielska: **Tak** (limit czasu i bramka rodzica), jeśli formularz o to pyta.
Wynik: **4+**.

## Eksport szyfrowania
W `Konfiguracja/Info.plist` jest `ITSAppUsesNonExemptEncryption = NO`: gra nie używa szyfrowania,
więc App Store Connect nie zada pytań przy każdym buildzie.

## Status przedsiębiorcy w UE (DSA)
Do decyzji po konsultacji z księgową. Nie-przedsiębiorca: w sklepie tylko imię i nazwisko.
Przedsiębiorca: w UE widoczny adres, telefon i e-mail.

## Notatki dla recenzenta (App Review Information → Notes)
Wklej po angielsku:

> This is a calm maze game for children aged 4–8, drawn by my daughter. It works offline, collects no data,
> has no ads, no in-app purchases and no accounts.
>
> Parental gate: links to the author's websites (About → gry.wilde.pl / przemyslaw.wilde.pl), the parent
> settings (start screen → "Dla rodzica" / "For parents") and time-limit extensions are behind a parental gate:
> a multiplication question (for example "What is 7 × 8?") with four answer buttons.
>
> Time limits: the game pauses after a play session (default 15 min) and stops after the daily limit
> (default 30 min, at most 60). To see the break screen quickly, a debug-only launch argument exists, but it is
> not active in release builds.
>
> No login is required.

Konto demo: niepotrzebne (brak logowania).
