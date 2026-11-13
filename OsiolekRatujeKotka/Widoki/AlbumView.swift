import SwiftUI

/// Album z naklejkami: okładka w kolorze albumu, przyklejone naklejki i serduszka za pełne albumy (`rysujAlbumNaklejek`).
/// `zTacka`: obrazek pełnego albumu w „Brawo” pokazuje też naklejki z tacki (w wolnych miejscach).
func rysujAlbumNaklejek(_ c: Plotno, _ w: Double, _ h: Double, _ album: AlbumNaklejek, zTacka: Bool = false) {
    var naklejki = album.przyklejone
    if zTacka {
        let wolne = album.wolneMiejsca
        for (i, n) in album.naTacce.enumerated() {
            let m = i < wolne.count ? wolne[i] : (1035, 735)
            naklejki.append(Naklejka(id: n.id, x: m.0, y: m.1))
        }
    }
    let kolor = KOLORY_ALBUMU[album.indeksKoloru(KOLORY_ALBUMU.count)]
    wpisz(c, ALBUM_RAMKA, 0, 0, w, h) { c2, s in
        rysujAlbum(c2, s, kolor)
        for n in naklejki {
            guard let x = n.x, let y = n.y else { continue }
            let r = rysunekNaklejki(n.id)
            wpisz(c2, r.ramka, x - AlbumNaklejek.NW / 2, y - AlbumNaklejek.NH / 2, AlbumNaklejek.NW, AlbumNaklejek.NH) { c3, s3 in r.rysuj(c3, s * s3) }
        }
        // Serduszka obok albumu: jedno za każdy pełny album (najwyżej cztery, liczbę podaje napis).
        for i in 0..<min(4, album.pelne) {
            wpisz(c2, SERCE_RAMKA, 120, 300 + Double(i) * 215, 180, 180) { c3, s3 in rysujSerce(c3, s * s3) }
        }
    }
}

/// Naklejka w ramce w×h.
struct ObrazNaklejki: View {
    let id: String
    var body: some View {
        Canvas { g, size in
            let r = rysunekNaklejki(id)
            wpisz(Plotno(g), r.ramka, 2, 2, size.width - 4, size.height - 4, r.rysuj)
        }
    }
}

/// Okno albumu: przeciągnij naklejkę z tacki na album albo stuknij naklejkę, a potem miejsce w albumie.
/// Przyklejone naklejki też da się przesuwać palcem.
struct OknoAlbumu: View {
    @Environment(StanGry.self) private var stan
    @State private var ramkaAlbumu: CGRect = .zero
    @State private var ciagnieta: (id: String, punkt: CGPoint)?
    @State private var przesuwana: (id: String, dx: Double, dy: Double)?
    private let przestrzen = "oknoAlbumu"

    var body: some View {
        let album = stan.album
        Panel {
            Text(stan.t("albumH")).font(.kreda(28)).foregroundStyle(Kolory.tekst).accessibilityAddTraits(.isHeader)
            Canvas { g, size in rysujAlbumNaklejek(Plotno(g), size.width, size.height, album) }
                .aspectRatio(ALBUM_RAMKA[2] / ALBUM_RAMKA[3], contentMode: .fit)
                .frame(maxWidth: 560)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(przestrzen)) } action: { ramkaAlbumu = $0 }
                .gesture(gestAlbumu)
                .accessibilityElement()
                .accessibilityLabel(album.przyklejone.isEmpty ? stan.t("albumAltPusty")
                                    : stan.t("albumAlt", ["n": album.przyklejone.map { nazwa($0.id) }.joined(separator: ", ")]))
                .accessibilityAction(named: Text(stan.t("tackaH"))) {
                    // VoiceOver: wybraną naklejkę przykleja w kolejnym wolnym miejscu.
                    if let id = stan.album.wybrana {
                        let m = stan.album.wolneMiejsca.first ?? (1035, 735)
                        stan.album.przyklej(id, m.0, m.1); stan.klik()
                    }
                }
            if !album.naTacce.isEmpty {
                Text(stan.t("tackaH")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche)
                Tacka(przestrzen: przestrzen, ramkaAlbumu: ramkaAlbumu, ciagnieta: $ciagnieta, przyklej: przyklejZTacki)
            } else if !album.naklejki.isEmpty {
                Text(stan.t("tackaPusta")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche)
            }
            Text((album.naklejki.isEmpty ? stan.t("albumPusty") : stan.t("albumStan", ["n": album.naklejki.count, "m": AlbumNaklejek.wszystkie.count]))
                 + (album.pelne > 0 ? stan.t("albumPelne", ["n": album.pelne]) : ""))
                .font(.kreda(18)).foregroundStyle(Kolory.tekst).multilineTextAlignment(.center)
            Text(stan.t("albumWskazowka")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Button(stan.t("wroc")) { stan.zamknijAlbum() }.buttonStyle(.kreska)
        }
        .coordinateSpace(.named(przestrzen))
        .overlay(alignment: .topLeading) {
            // Naklejka „w palcu” idzie za palcem po ekranie.
            if let c = ciagnieta {
                ObrazNaklejki(id: c.id).frame(width: 84, height: 84)
                    .position(c.punkt)
                    .allowsHitTesting(false)
            }
        }
    }

    private func nazwa(_ id: String) -> String { Teksty.surowy(stan.jezyk, "nazwy")[id].napis }

    /// Punkt w oknie → układ rysunku albumu (odwrotność `wpisz` dla ramki albumu).
    private func wAlbumie(_ p: CGPoint, _ rozmiar: CGSize) -> (Double, Double) {
        let rx = ALBUM_RAMKA[0], ry = ALBUM_RAMKA[1], rw = ALBUM_RAMKA[2], rh = ALBUM_RAMKA[3]
        let s = min(rozmiar.width / rw, rozmiar.height / rh)
        return (rx + (p.x - (rozmiar.width - rw * s) / 2) / s, ry + (p.y - (rozmiar.height - rh * s)) / s)
    }

    private func przyklejZTacki(_ id: String, _ punkt: CGPoint) {
        guard ramkaAlbumu.contains(punkt) else { return }
        let lokalny = CGPoint(x: punkt.x - ramkaAlbumu.minX, y: punkt.y - ramkaAlbumu.minY)
        let (x, y) = wAlbumie(lokalny, ramkaAlbumu.size)
        stan.album.przyklej(id, x, y); stan.klik()
    }

    private var gestAlbumu: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                let (x, y) = wAlbumie(v.location, ramkaAlbumu.size)
                if let p = przesuwana {
                    stan.album.przesun(p.id, x + p.dx, y + p.dy)
                } else if v.translation == .zero, let id = stan.album.naklejkaPod(x, y),
                          let n = stan.album.naklejki.first(where: { $0.id == id }), let nx = n.x, let ny = n.y {
                    stan.album.naWierzch(id)
                    przesuwana = (id, nx - x, ny - y)
                }
            }
            .onEnded { v in
                if przesuwana != nil { przesuwana = nil; stan.klik(); return }
                if let id = stan.album.wybrana {
                    let (x, y) = wAlbumie(v.location, ramkaAlbumu.size)
                    stan.album.przyklej(id, x, y); stan.klik()
                }
            }
    }
}

/// Tacka z naklejkami do przyklejenia: stuknięcie wybiera, przeciągnięcie niesie naklejkę na album.
struct Tacka: View {
    @Environment(StanGry.self) private var stan
    let przestrzen: String
    let ramkaAlbumu: CGRect
    @Binding var ciagnieta: (id: String, punkt: CGPoint)?
    let przyklej: (String, CGPoint) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64, maximum: 64), spacing: 6)], spacing: 6) {
            ForEach(stan.album.naTacce, id: \.id) { n in
                let wybrana = stan.album.wybrana == n.id
                ObrazNaklejki(id: n.id)
                    .frame(width: 56, height: 56)
                    .padding(4)
                    .kreska(wybrana ? Kolory.rozowy : Kolory.karta)
                    .background(KsztaltKreski().fill(Kolory.cien).offset(x: 2, y: 3))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(przestrzen))
                            .onChanged { v in
                                if v.translation == .zero { stan.album.wybrana = n.id }
                                if hypot(v.translation.width, v.translation.height) > 8 { ciagnieta = (n.id, v.location) }
                            }
                            .onEnded { v in
                                if ciagnieta != nil { przyklej(n.id, v.location) }
                                ciagnieta = nil
                            }
                    )
                    .accessibilityElement()
                    .accessibilityLabel(Teksty.surowy(stan.jezyk, "nazwy")[n.id].napis)
                    .accessibilityAddTraits(wybrana ? [.isButton, .isSelected] : .isButton)
                    .accessibilityAction { stan.album.wybrana = wybrana ? nil : n.id }
            }
        }
        .frame(maxWidth: 560)
    }
}

/// Nowa naklejka na „Brawo”: wskakuje na ekran; po pełnym albumie z albumu wylatują serduszka (2,4 s).
struct NowaNaklejka: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.accessibilityReduceMotion) private var ograniczRuch
    @State private var widoczna = false
    @State private var start = Date()

    var body: some View {
        let album = stan.album
        if let ostatnia = album.ostatnia {
            Rzad {
                Group {
                    if album.pelny {
                        TimelineView(.animation(paused: album.czeka || ograniczRuch)) { tl in
                            let f = album.czeka || ograniczRuch ? 1 : min(1, tl.date.timeIntervalSince(start) / 2.4)
                            Canvas { g, size in
                                let c = Plotno(g), w = size.width, h = size.height
                                rysujAlbumNaklejek(c, w, h, album, zTacka: !album.czeka)
                                if !album.czeka {
                                    for i in 0..<5 {
                                        let r = w * 0.18, x = w * (0.1 + 0.2 * Double(i))
                                        let y = h * (0.62 - 0.5 * f * (0.7 + 0.3 * Double((i * 7) % 5) / 4))
                                        wpisz(c, SERCE_RAMKA, x - r / 2, y - r / 2, r, r, rysujSerce)
                                    }
                                }
                            }
                        }
                        .frame(width: 150, height: 110)
                    } else {
                        ObrazNaklejki(id: ostatnia).frame(width: 72, height: 72)
                    }
                }
                .scaleEffect(widoczna || ograniczRuch ? 1 : 0.2)
                .rotationEffect(.degrees(widoczna || ograniczRuch ? 0 : -20))
                .accessibilityHidden(true)
                Text(album.czeka ? stan.t("naklejkiCzekaja")
                     : album.pelny ? stan.t("albumPelny")
                     : stan.t("nowaNaklejka", ["n": Teksty.surowy(stan.jezyk, "nazwy")[ostatnia].napis]))
                    .font(.kreda(18))
                    .foregroundStyle(Kolory.zaznaczenie)
                    .multilineTextAlignment(.center)
                Button { stan.pokazAlbum() } label: {
                    HStack(spacing: 6) { IkonaDziecka(id: "album").frame(width: 24, height: 24); Text(stan.t("albumPrzycisk")) }
                }
                .buttonStyle(.kreska(Kolory.rozowy, maly: true))
            }
            .onAppear {
                start = Date()
                widoczna = false
                withAnimation(.easeOut(duration: 0.6)) { widoczna = true }
            }
        }
    }
}
