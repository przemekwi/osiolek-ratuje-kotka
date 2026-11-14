import SwiftUI

/// „O grze” jako wizytówka autora: autor i córka, witryny (linki za bramką rodzica), opis gry i rysunki dziecka.
struct OGrzeView: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.openURL) private var otworz
    let zamknij: () -> Void
    /// Link czekający na bramkę rodzica.
    @State private var link: URL?
    /// Rysunek powiększony do „rysowania się”.
    @State private var powiekszony: Rysunek?

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
            if let r = powiekszony { RysunekRysujeSie(rysunek: r) { powiekszony = nil } }
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

    // MARK: Rysunki dziecka (bez zdjęć kartek): stuknięcie powiększa rysunek, który rysuje się sam
    private var rysunki: some View {
        VStack(spacing: 8) {
            Text(stan.t("rysunkiH")).font(.kreda(20)).accessibilityAddTraits(.isHeader)
            Text(stan.t("rysunkiWsk")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Zawijanie(odstep: 8) {
                ForEach(Rysunek.wszystkie(stan), id: \.id) { r in
                    Button {
                        stan.klik(); powiekszony = r
                    } label: {
                        VStack(spacing: 2) {
                            Canvas { g, size in r.rysuj(Plotno(g), size) }.frame(width: 80, height: 80)
                            Text(r.nazwa).font(.kreda(12, gruby: false)).lineLimit(2).multilineTextAlignment(.center).frame(width: 90)
                        }
                        .padding(6)
                        .kreska(Kolory.karta)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(stan.t("wGrzeAlt", ["n": r.nazwa]))
                }
            }
        }
    }
}

/// Rysunek dziecka do galerii w „O grze”.
struct Rysunek {
    let id: String
    let nazwa: String
    let rysuj: (Plotno, CGSize) -> Void

    static func wszystkie(_ stan: StanGry) -> [Rysunek] {
        let nazwy = Teksty.surowy(stan.jezyk, "nazwy")
        var w: [Rysunek] = []
        for id in ["osiolek", "kotek", "dom", "robot", "lapka", "krzak", "slonce", "zwierzatko", "dziewczynka", "jednorozec",
                   "gwiazdki", "serce", "trawa", "samochod", "kon", "grzybek", "pilka"] {
            let r = rysunekNaklejki(id)
            w.append(Rysunek(id: id, nazwa: nazwy[id == "dom" ? "domek" : id].napis) { c, size in
                wpisz(c, r.ramka, 2, 2, size.width - 4, size.height - 4, r.rysuj)
            })
        }
        w.append(Rysunek(id: "album", nazwa: nazwy["album"].napis) { c, size in
            wpisz(c, ALBUM_RAMKA, 2, 2, size.width - 4, size.height - 4) { c2, s in rysujAlbum(c2, s, KOLORY_ALBUMU[0]) }
        })
        for (n, k) in Koszulka.wszystkie.enumerated() {
            w.append(Rysunek(id: k.id, nazwa: stan.t("koszulka", ["n": n + 1])) { c, size in
                wpisz(c, k.ramka, 4, 4, size.width - 8, size.height - 8) { c2, s in rysujKoszulke(c2, s, k) }
            })
        }
        for id in ["strzalka", "idz", "cofnij", "odnowa", "podpowiedz", "menu"] {
            w.append(Rysunek(id: "ikona-" + id, nazwa: nazwy[id].napis) { c, size in rysujIkone(c, size, id, kolor: Kolory.tusz) })
        }
        return w
    }
}

/// Powiększony rysunek, który rysuje się na oczach: najpierw kreski jak długopisem, potem kolor (ok. 3,5 s).
/// Stuknięcie rysuje od nowa. Przy ograniczonym ruchu od razu cały rysunek.
struct RysunekRysujeSie: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.accessibilityReduceMotion) private var ograniczRuch
    let rysunek: Rysunek
    let zamknij: () -> Void
    @State private var start = Date()

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { zamknij() }
            Panel {
                Text(rysunek.nazwa).font(.kreda(24)).multilineTextAlignment(.center)
                TimelineView(.animation(paused: ograniczRuch)) { tl in
                    let p = ograniczRuch ? 1 : min(1, tl.date.timeIntervalSince(start) / 3.5)
                    Canvas { g, size in
                        let c = Plotno(g)
                        c.postep = p < 1 ? p : nil
                        rysunek.rysuj(c, size)
                    }
                }
                .frame(width: 260, height: 260)
                .contentShape(Rectangle())
                .onTapGesture { stan.klik(); start = Date() }
                .accessibilityLabel(stan.t("wGrzeAlt", ["n": rysunek.nazwa]))
                Text(stan.t("rysujPonownie")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche)
                Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
            }
            .foregroundStyle(Kolory.tekst)
        }
        .onAppear { start = Date() }
    }
}
