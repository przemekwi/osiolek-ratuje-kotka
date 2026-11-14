import SwiftUI

/// „O grze” jako wizytówka autora: autor i córka, witryny (linki za bramką rodzica), opis gry i rysunki dziecka.
struct OGrzeView: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.openURL) private var otworz
    let zamknij: () -> Void
    /// Link czekający na bramkę rodzica.
    @State private var link: URL?

    private var pl: Bool { stan.jezyk == "pl" }
    private var gry: URL { URL(string: pl ? "https://gry.wilde.pl/" : "https://gry.wilde.pl/en/")! }
    private var osobista: URL { URL(string: pl ? "https://przemyslaw.wilde.pl/" : "https://przemyslaw.wilde.pl/en/")! }

    var body: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t("oGrze")).font(.kreda(28)).accessibilityAddTraits(.isHeader)
                    // Obrazek z rysunków dziecka (`rysujOGrze`): słońce, zwierzątko, krzaczek, łapka.
                    Canvas { g, size in
                        let c = Plotno(g), w = size.width, h = size.height
                        wpisz(c, RYS["SLONCE2"]["ramka"].liczby, 0, 0, w * 0.24, h, rysujSlonce2)
                        wpisz(c, RYS["ZWIERZATKO"]["ramka"].liczby, w * 0.26, h * 0.1, w * 0.26, h * 0.9, rysujZwierzatko)
                        wpisz(c, KRZAK_RAMKA, w * 0.55, h * 0.05, w * 0.18, h * 0.95, rysujKrzak)
                        wpisz(c, LAPKA_RAMKA, w * 0.76, h * 0.25, w * 0.22, h * 0.7) { c2, s in rysujLapke(c2, s, kolorK("lapka")) }
                    }
                    .frame(maxWidth: 420).frame(height: 120)
                    .accessibilityHidden(true)

                    Text(stan.t("oKrotko")).font(.kreda(16, gruby: false)).multilineTextAlignment(.center)
                    wizytowka
                    rysunki

                    // Przy innych językach niż polski krótka informacja, że tłumaczenie jest maszynowe.
                    if !pl {
                        Text(Teksty.surowy(stan.jezyk, "o")[8].napis)
                            .font(.kreda(12, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
                    }
                    Text("© 2026 Przemysław Wilde").font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche)
                    Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            if link != nil { bramka }
        }
    }

    // MARK: Wizytówka autora
    private var wizytowka: some View {
        VStack(spacing: 10) {
            Text(stan.t("autorH")).font(.kreda(20)).accessibilityAddTraits(.isHeader)
            Text("Przemysław Wilde").font(.kreda(26))
            Text(stan.t("autorOpis")).font(.kreda(16, gruby: false)).multilineTextAlignment(.center)
            // Autorzy gry, jak na stronie: pomysł i rysunki — córka, realizacja — tata + AI.
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                ForEach(Array(Teksty.surowy(stan.jezyk, "autorzy").tablica.enumerated()), id: \.offset) { _, para in
                    GridRow {
                        Text(para[0].napis).font(.kreda(15))
                        Text(para[1].napis).font(.kreda(15, gruby: false))
                    }
                }
            }
            Divider().overlay(Kolory.ciche)
            Text(stan.t("witrynyH")).font(.kreda(18))
            witryna("gry.wilde.pl", stan.t("witrynaGry"), gry, Kolory.zielony)
            witryna("przemyslaw.wilde.pl", stan.t("witrynaOsobista"), osobista, Kolory.niebieski)
            Text(stan.t("linkRodzic")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }

    private func witryna(_ nazwa: String, _ opis: String, _ url: URL, _ kolor: Color) -> some View {
        VStack(spacing: 4) {
            Button(nazwa) { stan.klik(); stan.nowaBramka(); link = url }
                .buttonStyle(.kreska(kolor, maly: true))
                .accessibilityHint(stan.t("linkRodzic"))
            Text(opis).font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
        }
    }

    /// Bramka rodzica przed otwarciem przeglądarki (wymóg Apple dla aplikacji dla dzieci).
    private var bramka: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            Panel {
                Text(stan.t("dlaRodzica")).font(.kreda(24))
                BramkaRodzica {
                    if let u = link { otworz(u) }
                    link = nil
                }
                Button(stan.t("wroc")) { stan.klik(); link = nil }.buttonStyle(.kreska(Kolory.niebieski, maly: true))
            }
            .foregroundStyle(Kolory.tekst)
        }
    }

    // MARK: Rysunki dziecka (jak „pary” w grze, bez zdjęć kartek)
    private var rysunki: some View {
        let nazwy = Teksty.surowy(stan.jezyk, "nazwy")
        let postacie = ["osiolek", "kotek", "dom", "robot", "lapka", "krzak", "slonce", "zwierzatko", "dziewczynka", "jednorozec",
                        "gwiazdki", "serce", "trawa", "samochod", "kon", "grzybek", "pilka"]
        let ikony = ["strzalka", "idz", "cofnij", "odnowa", "podpowiedz", "menu"]
        return VStack(spacing: 8) {
            Text(stan.t("rysunkiH")).font(.kreda(20)).accessibilityAddTraits(.isHeader)
            Zawijanie(odstep: 8) {
                ForEach(postacie, id: \.self) { id in
                    karta(nazwy[id == "dom" ? "domek" : id].napis) { ObrazNaklejki(id: id) }
                }
                karta(nazwy["album"].napis) {
                    Canvas { g, size in
                        wpisz(Plotno(g), ALBUM_RAMKA, 2, 2, size.width - 4, size.height - 4) { c, s in rysujAlbum(c, s, KOLORY_ALBUMU[0]) }
                    }
                }
                ForEach(Koszulka.wszystkie.indices, id: \.self) { n in
                    let k = Koszulka.wszystkie[n]
                    karta(stan.t("koszulka", ["n": n + 1])) {
                        Canvas { g, size in wpisz(Plotno(g), k.ramka, 4, 4, size.width - 8, size.height - 8) { c, s in rysujKoszulke(c, s, k) } }
                    }
                }
                ForEach(ikony, id: \.self) { id in
                    karta(nazwy[id].napis) { IkonaDziecka(id: id, kolor: Kolory.tusz) }
                }
            }
        }
    }

    private func karta<Obraz: View>(_ nazwa: String, @ViewBuilder _ obraz: () -> Obraz) -> some View {
        VStack(spacing: 2) {
            obraz().frame(width: 80, height: 80)
            Text(nazwa).font(.kreda(12, gruby: false)).lineLimit(2).multilineTextAlignment(.center).frame(width: 90)
        }
        .padding(6)
        .kreska(Kolory.karta)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stan.t("wGrzeAlt", ["n": nazwa]))
    }
}
