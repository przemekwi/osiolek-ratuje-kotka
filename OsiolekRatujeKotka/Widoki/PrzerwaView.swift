import SwiftUI

/// Klawiatura cyfr w grze (bez klawiatury systemowej): pole z wpisaną liczbą, cyfry, kasowanie i „OK”.
struct KlawiaturaCyfr: View {
    @Environment(StanGry.self) private var stan
    @Binding var wpisane: String
    let etykieta: String
    let ok: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(wpisane.isEmpty ? " " : wpisane)
                .font(.kreda(28)).monospacedDigit()
                .frame(width: 120, height: 48)
                .kreska(Kolory.karta)
                .accessibilityLabel(etykieta)
                .accessibilityValue(wpisane)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { rz in
                    GridRow { ForEach(rz, id: \.self) { cyfra($0) } }
                }
                GridRow {
                    Button { stan.klik(); if !wpisane.isEmpty { wpisane.removeLast() } } label: {
                        Image(systemName: "delete.left").frame(width: 44, height: 30)
                    }
                    .buttonStyle(.kreska(Kolory.karta, maly: true))
                    .accessibilityLabel(stan.t("cofnijCyfre"))
                    cyfra(0)
                    Button(action: ok) { Text("OK").frame(width: 44, height: 30) }
                        .buttonStyle(.kreska(Kolory.zielony, maly: true))
                        .disabled(wpisane.isEmpty)
                        .accessibilityLabel(stan.t("odblokuj"))
                }
            }
        }
    }

    private func cyfra(_ c: Int) -> some View {
        Button {
            stan.klik()
            if wpisane.count < 4 { wpisane += String(c) }
        } label: { Text("\(c)").frame(width: 44, height: 30) }
        .buttonStyle(.kreska(Kolory.karta, maly: true))
    }
}

/// Bramka rodzica (wymóg Apple w kategorii dla dzieci): działanie z tabliczki mnożenia, np. „Ile to 7 × 8?”,
/// bez podpowiedzi, odpowiedź na klawiaturze cyfr w grze. Przy błędzie nowe działanie.
struct BramkaRodzica: View {
    @Environment(StanGry.self) private var stan
    let otwarta: () -> Void
    @State private var wpisane = ""
    @State private var blad = false

    var body: some View {
        VStack(spacing: 8) {
            Text(stan.t("rodzicMnozenie")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Text(stan.pytanieRodzica).font(.kreda(24)).multilineTextAlignment(.center)
            KlawiaturaCyfr(wpisane: $wpisane, etykieta: stan.pytanieRodzica) {
                if stan.odblokuj(Int(wpisane)) { blad = false; otwarta() } else { blad = true }
                wpisane = ""
            }
            if blad { Text(stan.t("rodzicBlad")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche) }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }
}

/// Tryb dla dorosłych: wyłącza limity czasu do północy. Ostrzeżenie i druga, trudniejsza bramka
/// (liczba dwucyfrowa razy jednocyfrowa, np. 17 × 8), której dziecko 4–8 lat nie rozwiąże.
struct TrybDoroslych: View {
    @Environment(StanGry.self) private var stan
    @State private var rozwiniety = false
    @State private var a = 0
    @State private var b = 0
    @State private var wpisane = ""
    @State private var blad = false

    var body: some View {
        let _ = stan.wersjaLimitu
        VStack(spacing: 8) {
            if stan.limit.bezLimitu {
                Text(stan.t("doroslyWlaczony")).font(.kreda(16)).foregroundStyle(Kolory.zaznaczenie).multilineTextAlignment(.center)
                Button(stan.t("doroslyWylacz")) { stan.wylaczBezLimitu() }.buttonStyle(.kreska(Kolory.zielony, maly: true))
            } else if !rozwiniety {
                Button(stan.t("doroslyH")) { stan.klik(); nowePytanie(); rozwiniety = true }
                    .buttonStyle(.kreska(Kolory.karta, maly: true))
            } else {
                Text(stan.t("doroslyH")).font(.kreda(18))
                Text(stan.t("doroslyOpis")).font(.kreda(14, gruby: false)).multilineTextAlignment(.center)
                // Ostrzeżenie: wyraźne, na tle w kolorze wyróżnienia.
                Text(stan.t("doroslyOstrzezenie"))
                    .font(.kreda(15))
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .kreska(Kolory.rozowy)
                    .foregroundStyle(Kolory.napisPrzycisku)
                Text(stan.t("doroslyBramka")).font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche)
                Text(stan.t("ileTo", ["s": "\(a) × \(b)"])).font(.kreda(24))
                KlawiaturaCyfr(wpisane: $wpisane, etykieta: stan.t("ileTo", ["s": "\(a) × \(b)"])) {
                    if Int(wpisane) == a * b { blad = false; rozwiniety = false; stan.wlaczBezLimitu() } else { blad = true; nowePytanie() }
                    wpisane = ""
                }
                if blad { Text(stan.t("rodzicBlad")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche) }
                Button(stan.t("wroc")) { stan.klik(); rozwiniety = false }.buttonStyle(.kreska(Kolory.karta, maly: true))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }

    private func nowePytanie() { a = Int.random(in: 12...19); b = Int.random(in: 6...9) }
}

/// Ustawienia limitów dla rodzica: sesja i cały dzień, dzisiejszy czas gry, narzędzia systemowe.
struct UstawieniaLimitu: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        let _ = stan.wersjaLimitu
        let l = stan.limit
        VStack(spacing: 10) {
            Text(stan.t("ustawieniaH")).font(.kreda(20))
            Text(stan.t("limitSesji")).font(.kreda(16))
            wybor(Limit.OPCJE_SESJI, l.sesjaMin) { stan.ustawLimit(sesja: $0, dzien: stan.limit.dzienMin) }
            Text(stan.t("limitDnia")).font(.kreda(16))
            wybor(Limit.OPCJE_DNIA, l.dzienMin) { stan.ustawLimit(sesja: stan.limit.sesjaMin, dzien: $0) }
            Text(stan.t("dzisGra", ["m": Int(l.dzisiaj / 60), "d": l.dzienMin])).font(.kreda(16, gruby: false))
            Text(stan.t("przerwaPoSesji")).font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Button(stan.t(stan.wibracje ? "wibracjeWl" : "wibracjeWyl")) { stan.przelaczWibracje() }
                .buttonStyle(.kreska(Kolory.niebieski, maly: true))
                .accessibilityAddTraits(stan.wibracje ? .isSelected : [])
            // Dostęp z przewodnikiem: funkcja iOS, która zatrzymuje telefon w jednej aplikacji.
            VStack(spacing: 4) {
                Text(stan.t("przewodnikH")).font(.kreda(16))
                Text(stan.t("przewodnikKroki")).font(.kreda(14, gruby: false)).multilineTextAlignment(.center)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .kreska(Kolory.tlo)
            Text(stan.t("systemInfo")).font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            TrybDoroslych()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }

    private func wybor(_ opcje: [Int], _ biezaca: Int, _ ustaw: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(opcje, id: \.self) { m in
                Button { stan.klik(); ustaw(m) } label: { Text(stan.t("minut", ["m": m])).lineLimit(1).minimumScaleFactor(0.7) }
                    .buttonStyle(.kreska(m == biezaca ? Kolory.rozowy : Kolory.karta, maly: true))
                    .accessibilityAddTraits(m == biezaca ? .isSelected : [])
            }
        }
    }
}

/// „Czas na przerwę!” albo „Na dziś koniec grania” nad całą aplikacją. Po 30 minutach przerwy dziecko gra dalej samo;
/// wcześniej decyduje rodzic za bramką: przedłużenie (coraz krótsze, najwyżej dwa dziennie) albo koniec grania.
struct PrzerwaView: View {
    @Environment(StanGry.self) private var stan
    @State private var otwarta = false

    var body: some View {
        let dzien = stan.blokada == .dzien
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t(dzien ? "dzienH" : "przerwaH")).font(.kreda(28)).foregroundStyle(Kolory.tekst)
                        .multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
                    Canvas { g, size in
                        let c = Plotno(g), w = size.width, h = size.height
                        wpisz(c, SCENA_RAMKA, w * 0.46, 0, w * 0.54, h) { c2, s in rysujScene(c2, s) }
                        rysujOsiolka(c, 0, h * 0.18, w * 0.26, h * 0.82, stan.koszulka)
                        rysujKotka(c, w * 0.22, h * 0.6, w * 0.24, h * 0.4)
                    }
                    .frame(maxWidth: 420).frame(height: 170)
                    .accessibilityHidden(true)
                    Text(stan.t(dzien ? "dzienTekst" : "przerwaTekst")).font(.kreda(18, gruby: false)).multilineTextAlignment(.center)
                    if stan.przerwaMinela {
                        Text(stan.t("przerwaMinela")).font(.kreda(18)).foregroundStyle(Kolory.zaznaczenie).multilineTextAlignment(.center)
                        Button(stan.t("rozdzialDalej")) { stan.grajPoPrzerwie() }.buttonStyle(.kreska)
                    } else if otwarta {
                        if dzien { UstawieniaLimitu() } else { decyzjaRodzica }
                    } else {
                        if dzien { Text(stan.t("dzienRodzic")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche) }
                        BramkaRodzica { otwarta = true }
                    }
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center, for: .alignment)
        }
        .task {
            // Co kilka sekund: czy przerwa już minęła albo zaczął się nowy dzień.
            while !Task.isCancelled {
                stan.sprawdzPrzerwe()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    /// Rodzic decyduje: koniec grania albo przedłużenie.
    private var decyzjaRodzica: some View {
        let opcje = stan.limit.opcjePrzedluzenia
        return VStack(spacing: 8) {
            Text(stan.t("przedluzTekst", ["m": max(1, Int((stan.limit.dzisiaj / 60).rounded()))]))
                .font(.kreda(18)).multilineTextAlignment(.center)
            Text(stan.t(opcje.isEmpty ? "przedluzBrak" : "przedluzZasady")).font(.kreda(15, gruby: false))
                .foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            if stan.limit.przedluzeniaDzis > 0 {
                Text(stan.t("przedluzDobro")).font(.kreda(18)).multilineTextAlignment(.center)
            }
            Button(stan.t("przedluzKoniec")) {
                stan.koniecGrania()
                otwarta = false
            }
            .buttonStyle(.kreska(Kolory.zielony, maly: true))
            if !opcje.isEmpty {
                Rzad {
                    ForEach(opcje, id: \.self) { m in
                        Button(stan.t("przedluzMin", ["m": m])) {
                            stan.przedluz(m)
                            otwarta = false
                        }
                        .buttonStyle(.kreska(Kolory.zolty, maly: true))
                    }
                }
            }
            // Dorosły, który sam chce grać dłużej, może wyłączyć limity do północy (za trudniejszą bramką).
            TrybDoroslych()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }
}

/// „Dla rodzica” z ekranu startowego: bramka, a za nią ustawienia limitów.
struct OknoRodzica: View {
    @Environment(StanGry.self) private var stan
    let zamknij: () -> Void
    @State private var otwarta = false
    @State private var oGrze = false
    @State private var potwierdzNowa = false
    @State private var ustawieniaOtwarte = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t("dlaRodzica")).font(.kreda(28)).foregroundStyle(Kolory.tekst).accessibilityAddTraits(.isHeader)
                    // „O grze” osobno, bez bramki (linki w środku i tak otwierają się dopiero po bramce).
                    Button(stan.t("oGrze")) { stan.klik(); oGrze = true }.buttonStyle(.kreska(Kolory.rozowy, maly: true))
                    if otwarta {
                        UstawieniaLimitu()
                        // Ustawienia gry rozwijane przyciskiem, żeby za bramką nie było od razu wszystkiego naraz.
                        Button(stan.t("ustawieniaGry")) {
                            stan.klik()
                            withAnimation(.easeInOut(duration: 0.2)) { ustawieniaOtwarte.toggle() }
                        }
                        .buttonStyle(.kreska(Kolory.niebieski, maly: true))
                        .accessibilityAddTraits(ustawieniaOtwarte ? .isSelected : [])
                        if ustawieniaOtwarte { ustawieniaGry }
                    } else {
                        BramkaRodzica { otwarta = true }
                    }
                    Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center, for: .alignment)
        }
        .overlay { if oGrze { OGrzeView { oGrze = false } } }
        .onAppear { stan.nowaBramka() }
    }

    /// Ustawienia gry w jednym miejscu: dźwięk, kolory, język i nowa gra (kasuje postęp i album).
    private var ustawieniaGry: some View {
        VStack(spacing: 10) {
            PrzelacznikiDzwieku()
            Rzad {
                PrzelacznikMotywu()
                WyborJezyka()
            }
            if potwierdzNowa {
                Text(stan.t("nowaGraPotwierdz")).font(.kreda(15, gruby: false)).multilineTextAlignment(.center)
                Rzad {
                    Button(stan.t("nowaGraTak")) { stan.nowaGra(); potwierdzNowa = false; stan.klik() }
                        .buttonStyle(.kreska(Kolory.zielony, maly: true))
                    Button(stan.t("wroc")) { stan.klik(); potwierdzNowa = false }.buttonStyle(.kreska(Kolory.karta, maly: true))
                }
            } else {
                Button(stan.t("nowaGra")) { stan.klik(); potwierdzNowa = true }.buttonStyle(.kreska(Kolory.zielony, maly: true))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }
}
