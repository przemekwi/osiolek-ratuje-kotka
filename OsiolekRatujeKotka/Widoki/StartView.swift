import SwiftUI

/// Ekran startowy: okładka z rysunków dziecka, tytuł i przyciski (jak `#start` w grze).
struct StartView: View {
    @Environment(StanGry.self) private var stan
    @State private var oknoRodzica = false

    var body: some View {
        GeometryReader { geo in
            // Telefon poziomo: okładka po lewej, przyciski po prawej.
            let poziomo = geo.size.width > geo.size.height && geo.size.height <= 700
            ScrollView {
                Group {
                    if poziomo {
                        HStack(spacing: 16) {
                            Okladka().frame(height: min(geo.size.height * 0.78, 360))
                            VStack(spacing: 8) { tytul(20); przyciski }
                        }
                    } else {
                        VStack(spacing: geo.size.height <= 760 ? 8 : 12) {
                            Okladka().frame(maxWidth: 720).frame(height: min(max(130, geo.size.height * 0.34), 420))
                            tytul(min(48, max(26, geo.size.width * 0.055)))
                            przyciski
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Kolory.tlo.ignoresSafeArea())
        .overlay { if oknoRodzica { OknoRodzica { oknoRodzica = false } } }
    }

    private func tytul(_ rozmiar: CGFloat) -> some View {
        Text(stan.t("tytul"))
            .font(.kreda(rozmiar))
            .foregroundStyle(Kolory.tekst)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private var przyciski: some View {
        VStack(spacing: 12) {
            Button { stan.graj() } label: { Text(stan.t("graj")).frame(maxWidth: .infinity) }.buttonStyle(.kreska)
            PrzelacznikiDzwieku()
            PrzelacznikMotywu()
            WyborJezyka()
            // Ustawienia limitu czasu za bramką rodzica.
            Button(stan.t("dlaRodzica")) { stan.klik(); oknoRodzica = true }
                .buttonStyle(.kreska(Kolory.rozowy, maly: true))
        }
        .frame(maxWidth: 420)
    }
}

/// Okładka: domek z otoczeniem, osiołek, kotek i łapka (`rysujOkladke`).
struct Okladka: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Canvas { g, size in
            let c = Plotno(g), w = size.width, h = size.height
            wpisz(c, SCENA_RAMKA, w * 0.52, 0, w * 0.48, h) { c2, s in rysujScene(c2, s) }
            rysujOsiolka(c, w * 0.02, h * 0.22, w * 0.3, h * 0.78, stan.koszulka)
            rysujKotka(c, w * 0.3, h * 0.62, w * 0.26, h * 0.38)
            wpisz(c, LAPKA_RAMKA, w * 0.36, h * 0.05, w * 0.1, h * 0.18) { c2, s in rysujLapke(c2, s, kolorK("lapka")) }
        }
        .accessibilityHidden(true)
    }
}
