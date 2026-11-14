import SwiftUI

/// Bramka rodzica (zalecana przez Apple w kategorii dla dzieci): mnożenie i cztery odpowiedzi do wyboru,
/// bez klawiatury. Przy błędzie nowe działanie.
struct BramkaRodzica: View {
    @Environment(StanGry.self) private var stan
    let otwarta: () -> Void
    @State private var blad = false

    var body: some View {
        VStack(spacing: 8) {
            Text(stan.t("rodzicMnozenie")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Text(stan.pytanieRodzica).font(.kreda(24)).multilineTextAlignment(.center)
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(0..<2, id: \.self) { rz in
                    GridRow {
                        ForEach(0..<2, id: \.self) { k in
                            let i = rz * 2 + k
                            if i < stan.opcjeBramki.count {
                                let o = stan.opcjeBramki[i]
                                Button {
                                    if stan.odblokuj(o) { blad = false; otwarta() } else { blad = true }
                                } label: { Text("\(o)").frame(minWidth: 70) }
                                .buttonStyle(.kreska(Kolory.karta))
                            }
                        }
                    }
                }
            }
            if blad { Text(stan.t("rodzicBlad")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche) }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }
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
            .defaultScrollAnchor(.center)
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

    var body: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t("dlaRodzica")).font(.kreda(28)).foregroundStyle(Kolory.tekst).accessibilityAddTraits(.isHeader)
                    if otwarta { UstawieniaLimitu() } else { BramkaRodzica { otwarta = true } }
                    Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center)
        }
        .onAppear { stan.nowaBramka() }
    }
}
