import SwiftUI
import UIKit

/// „O grze”: autorzy, krótka historia, linki (za bramką rodzica) i rysunki dziecka za przyciskiem.
struct OGrzeView: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.openURL) private var otworz
    let zamknij: () -> Void
    /// Link czekający na bramkę rodzica.
    @State private var link: URL?
    /// Galeria rysunków i rysunek powiększony do „rysowania się”.
    @State private var galeria = false
    @State private var powiekszony: Rysunek?

    private var pl: Bool { stan.jezyk == "pl" }
    private var wilde: URL { URL(string: pl ? "https://wilde.pl/" : "https://wilde.pl/en/")! }
    private var historia: URL {
        URL(string: pl ? "https://przemyslaw.wilde.pl/blog/gra-z-dzieckiem-i-ai-osiolek-ratuje-kotka/"
                       : "https://przemyslaw.wilde.pl/en/blog/a-game-made-with-a-child-and-ai/")!
    }
    private var gry: URL { URL(string: pl ? "https://gry.wilde.pl/" : "https://gry.wilde.pl/en/")! }

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

                    VStack(spacing: 4) {
                        Text(stan.t("autorH")).font(.kreda(16, gruby: false)).foregroundStyle(Kolory.ciche)
                        Text(stan.t("autorzyGry")).font(.kreda(24)).multilineTextAlignment(.center)
                    }
                    Text(stan.t("oOpis")).font(.kreda(16, gruby: false)).multilineTextAlignment(.center)

                    // Linki: przeglądarka otwiera się dopiero po bramce rodzica.
                    VStack(spacing: 8) {
                        odnosnik(stan.t("stworzonePrzez"), "Wilde.pl", wilde, Kolory.zolty)
                        odnosnik(stan.t("historiaGry"), stan.t("przeczytajHistorie"), historia, Kolory.niebieski)
                        odnosnik(stan.t("inneGry"), "gry.wilde.pl", gry, Kolory.zielony)
                        Text(stan.t("linkRodzic")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .kreska(Color.clear)

                    Button { stan.klik(); galeria = true } label: { Text(stan.t("rysunkiH")).frame(maxWidth: .infinity) }
                        .buttonStyle(.kreska(Kolory.rozowy, maly: true))

                    // Przy innych językach niż polski krótka informacja, że tłumaczenie jest maszynowe.
                    if !pl {
                        Text(Teksty.surowy(stan.jezyk, "o")[8].napis)
                            .font(.kreda(12, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
                    }
                    Text(stan.t("wersja", ["w": Wersja.numer]) + " · © 2026 Przemysław Wilde").font(.kreda(14, gruby: false)).foregroundStyle(Kolory.ciche)
                    Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            if galeria { GaleriaRysunkow(wybierz: { powiekszony = $0 }) { galeria = false } }
            if let r = powiekszony { RysunekRysujeSie(rysunek: r) { powiekszony = nil } }
            if link != nil { bramka }
        }
    }

    private func odnosnik(_ etykieta: String, _ napis: String, _ url: URL, _ kolor: Color) -> some View {
        HStack(spacing: 10) {
            Text(etykieta).font(.kreda(15, gruby: false)).frame(maxWidth: .infinity, alignment: .trailing)
            Button(napis) { stan.klik(); stan.nowaBramka(); link = url }
                .buttonStyle(.kreska(kolor, maly: true))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHint(stan.t("linkRodzic"))
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

}

/// Galeria rysunków dziecka; stuknięcie wybiera rysunek do „rysowania się”.
struct GaleriaRysunkow: View {
    @Environment(StanGry.self) private var stan
    let wybierz: (Rysunek) -> Void
    let zamknij: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t("rysunkiH")).font(.kreda(24)).accessibilityAddTraits(.isHeader)
                    Text(stan.t("rysunkiWsk")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
                    Zawijanie(odstep: 8) {
                        ForEach(Rysunek.wszystkie(stan), id: \.id) { r in
                            Button {
                                stan.klik(); wybierz(r)
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
                    Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

/// Rysunek dziecka do galerii w „O grze”.
struct Rysunek {
    let id: String
    let nazwa: String
    /// Nazwa zdjęcia oryginalnej kartki w zasobach (rysunek-….jpg).
    let zdjecie: String
    let rysuj: (Plotno, CGSize) -> Void

    /// Zdjęcie rysunku z kartki (dołączone do aplikacji, bez sieci).
    var obrazKartki: UIImage? {
        Bundle.main.path(forResource: "rysunek-" + zdjecie, ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }
    }

    static func wszystkie(_ stan: StanGry) -> [Rysunek] {
        let nazwy = Teksty.surowy(stan.jezyk, "nazwy")
        var w: [Rysunek] = []
        for id in ["osiolek", "kotek", "dom", "robot", "lapka", "krzak", "slonce", "zwierzatko", "dziewczynka", "jednorozec",
                   "gwiazdki", "serce", "trawa", "samochod", "kon", "grzybek", "pilka"] {
            let r = rysunekNaklejki(id)
            let klucz = id == "dom" ? "domek" : id
            w.append(Rysunek(id: id, nazwa: nazwy[klucz].napis, zdjecie: klucz) { c, size in
                wpisz(c, r.ramka, 2, 2, size.width - 4, size.height - 4, r.rysuj)
            })
        }
        w.append(Rysunek(id: "album", nazwa: nazwy["album"].napis, zdjecie: "album") { c, size in
            wpisz(c, ALBUM_RAMKA, 2, 2, size.width - 4, size.height - 4) { c2, s in rysujAlbum(c2, s, KOLORY_ALBUMU[0]) }
        })
        for (n, k) in Koszulka.wszystkie.enumerated() {
            w.append(Rysunek(id: k.id, nazwa: stan.t("koszulka", ["n": n + 1]), zdjecie: k.id) { c, size in
                wpisz(c, k.ramka, 4, 4, size.width - 8, size.height - 8) { c2, s in rysujKoszulke(c2, s, k) }
            })
        }
        for id in ["strzalka", "idz", "cofnij", "odnowa", "podpowiedz", "menu"] {
            w.append(Rysunek(id: "ikona-" + id, nazwa: nazwy[id].napis, zdjecie: id) { c, size in rysujIkone(c, size, id, kolor: Kolory.tusz) })
        }
        return w
    }
}

/// Powiększony rysunek: najpierw zdjęcie oryginału z kartki (1,6 s), potem przenikanie w rysunek z gry, który
/// rysuje się na oczach — kreski jak długopisem, na końcu kolor. Stuknięcie odtwarza całość od nowa.
/// Przy ograniczonym ruchu: zdjęcie, a potem od razu gotowy rysunek, bez przenikania i animacji.
struct RysunekRysujeSie: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.accessibilityReduceMotion) private var ograniczRuch
    let rysunek: Rysunek
    let zamknij: () -> Void
    @State private var start = Date()

    private static let KARTKA = 1.6, PRZENIKANIE = 0.8, RYSOWANIE = 3.5

    var body: some View {
        let kartka = rysunek.obrazKartki
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { zamknij() }
            Panel {
                Text(rysunek.nazwa).font(.kreda(24)).multilineTextAlignment(.center)
                TimelineView(.animation(minimumInterval: ograniczRuch ? 0.25 : nil)) { tl in
                    let e = tl.date.timeIntervalSince(start) - (kartka == nil ? Self.KARTKA : 0)
                    let rysunekWidac = ograniczRuch
                        ? (e >= Self.KARTKA ? 1.0 : 0.0)
                        : max(0, min(1, (e - Self.KARTKA) / Self.PRZENIKANIE))
                    let postep = ograniczRuch ? 1 : max(0, min(1, (e - Self.KARTKA) / Self.RYSOWANIE))
                    ZStack {
                        if let kartka {
                            Image(uiImage: kartka).resizable().scaledToFit()
                                .opacity(1 - rysunekWidac)
                                .accessibilityHidden(true)
                        }
                        Canvas { g, size in
                            let c = Plotno(g)
                            c.postep = postep < 1 ? postep : nil
                            rysunek.rysuj(c, size)
                        }
                        .opacity(rysunekWidac)
                    }
                }
                .frame(width: 260, height: 260)
                .contentShape(Rectangle())
                .onTapGesture { stan.klik(); start = Date() }
                .accessibilityElement()
                .accessibilityLabel(stan.t("wGrzeAlt", ["n": rysunek.nazwa]))
                Text(stan.t("rysujPonownie")).font(.kreda(13, gruby: false)).foregroundStyle(Kolory.ciche)
                Button(stan.t("wroc")) { stan.klik(); zamknij() }.buttonStyle(.kreska)
            }
            .foregroundStyle(Kolory.tekst)
        }
        .onAppear { start = Date() }
    }
}
