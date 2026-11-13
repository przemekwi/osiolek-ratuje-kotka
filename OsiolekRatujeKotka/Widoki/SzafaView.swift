import SwiftUI

/// Szafa „Ubierz osiołka”: podgląd osiołka, koszulki narysowane przez dziecko i paleta 10 kolorów (`#szafa` z gry).
struct SzafaView: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        GeometryReader { geo in
            // Niski ekran poziomo: podgląd po lewej, koszulki i paleta po prawej.
            let poziomo = geo.size.width > geo.size.height && geo.size.height <= 700
            VStack(spacing: poziomo ? 6 : 12) {
                Text(stan.t("szafaH"))
                    .font(.kreda(poziomo ? 20 : 30))
                    .foregroundStyle(Kolory.tekst)
                    .accessibilityAddTraits(.isHeader)
                if poziomo {
                    HStack(alignment: .top, spacing: 12) {
                        PodgladOsiolka().frame(width: min(geo.size.width * 0.24, 190))
                        VStack(spacing: 6) {
                            ScrollView { Koszulki(maly: true).padding(2) }
                            PaletaKolorow(maly: true)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            VStack(spacing: 6) {
                                PodgladOsiolka()
                                    .frame(width: min(geo.size.width * 0.64, 280), height: min(geo.size.width * 0.82, 360, geo.size.height * 0.44))
                                PaletaKolorow(maly: false)
                            }
                            Koszulki(maly: false)
                        }
                        .frame(maxWidth: 1100)
                        .frame(maxWidth: .infinity)
                    }
                }
                // „W drogę” zawsze na ekranie, także gdy koszulki się nie mieszczą.
                Rzad {
                    Button(stan.t("losuj")) { stan.losujKoszulke() }.buttonStyle(.kreska(Kolory.niebieski))
                    Button(stan.t("wDroge")) { stan.wDroge() }.buttonStyle(.kreska)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Kolory.tlo.ignoresSafeArea())
    }
}

/// Osiołek w wybranej koszulce.
struct PodgladOsiolka: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Canvas { g, size in
            rysujOsiolka(Plotno(g), size.width * 0.04, size.height * 0.03, size.width * 0.92, size.height * 0.94, stan.koszulka)
        }
        .accessibilityElement()
        .accessibilityLabel(stan.t("osiolek"))
        .accessibilityAddTraits(.isImage)
    }
}

/// „Bez koszulki” i osiem koszulek; wybrana ma różowe tło.
struct Koszulki: View {
    @Environment(StanGry.self) private var stan
    let maly: Bool

    var body: some View {
        let szer: CGFloat = maly ? 76 : 104, obraz: CGFloat = maly ? 58 : 84
        LazyVGrid(columns: [GridItem(.adaptive(minimum: szer, maximum: szer), spacing: 10)], spacing: 10) {
            Button {
                stan.klik(); stan.koszulkaIndeks = nil
            } label: {
                Text(stan.t("bezKoszulki"))
                    .font(.kreda(maly ? 12 : 15))
                    .multilineTextAlignment(.center)
                    .frame(width: szer - 12, height: obraz + 24)
            }
            .buttonStyle(PrzyciskKoszulki(wybrany: stan.koszulkaIndeks == nil))
            .accessibilityAddTraits(stan.koszulkaIndeks == nil ? .isSelected : [])
            ForEach(Koszulka.wszystkie.indices, id: \.self) { n in
                let wybrany = stan.koszulkaIndeks == n
                // Wybrana koszulka pokazuje się w kolorze z palety, pozostałe w kolorze z rysunku.
                let k = Koszulka(indeks: n, kolor: wybrany ? stan.kolorKoszulki : nil)
                Button {
                    stan.klik(); stan.koszulkaIndeks = n
                } label: {
                    VStack(spacing: 2) {
                        Canvas { g, size in
                            wpisz(Plotno(g), k.ramka, 5, 5, size.width - 10, size.height - 10) { c2, s in rysujKoszulke(c2, s, k) }
                        }
                        .frame(width: obraz, height: obraz)
                        Text(stan.t("koszulka", ["n": n + 1])).font(.kreda(maly ? 12 : 15, gruby: false)).lineLimit(1)
                    }
                    .frame(width: szer - 12)
                }
                .buttonStyle(PrzyciskKoszulki(wybrany: wybrany))
                .accessibilityAddTraits(wybrany ? .isSelected : [])
            }
        }
        .frame(maxWidth: 600)
    }
}

struct PrzyciskKoszulki: ButtonStyle {
    let wybrany: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(wybrany ? Kolory.napisPrzycisku : Kolory.tekst)
            .padding(6)
            .kreska(wybrany ? Kolory.rozowy : Kolory.karta)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Paleta 10 kolorów dla wybranej koszulki; ponowne stuknięcie wraca do koloru z rysunku.
struct PaletaKolorow: View {
    @Environment(StanGry.self) private var stan
    let maly: Bool

    var body: some View {
        if let n = stan.koszulkaIndeks {
            let rozmiar: CGFloat = maly ? 36 : 48
            let kolumny = maly ? 10 : 5
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(rozmiar), spacing: 4), count: kolumny), spacing: 4) {
                ForEach(KOLORY_KOSZULKI.indices, id: \.self) { i in
                    let kolor = KOLORY_KOSZULKI[i]
                    let wybrany = stan.kolorKoszulki == kolor.hex
                    let k = Koszulka(indeks: n, kolor: kolor.hex)
                    Button {
                        stan.klik()
                        stan.kolorKoszulki = wybrany ? nil : kolor.hex
                    } label: {
                        Canvas { g, size in
                            wpisz(Plotno(g), k.ramka, 2, 2, size.width - 4, size.height - 4) { c2, s in rysujKoszulke(c2, s, k, 1.4) }
                        }
                        .frame(width: rozmiar - 4, height: rozmiar - 4)
                        .padding(2)
                        .background(RoundedRectangle(cornerRadius: 10).fill(wybrany ? Kolory.karta : .clear))
                        .scaleEffect(wybrany ? 1.25 : 1)
                        .animation(.easeOut(duration: 0.15), value: wybrany)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Teksty.surowy(stan.jezyk, "kolory")[kolor.nazwa].napis)
                    .accessibilityAddTraits(wybrany ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stan.t("kolorKoszulki"))
        }
    }
}
