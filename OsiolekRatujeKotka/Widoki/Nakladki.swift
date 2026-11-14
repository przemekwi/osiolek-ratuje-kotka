import SwiftUI

/// Nakładki nad planszą: przyciemnione tło i panel (menu pauzy, „Brawo”).
struct NakladkiGry: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        if stan.nakladka == .oGrze {
            OGrzeView { stan.nakladka = .menu }
        } else if let n = stan.nakladka {
            GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.44).ignoresSafeArea()
                ScrollView {
                    Group {
                        switch n {
                        case .menu: MenuPauzy(rozmiarEkranu: geo.size)
                        case .brawo: Brawo(rozmiarEkranu: geo.size)
                        case .album: OknoAlbumu(rozmiarEkranu: geo.size)
                        case .rozdzial: KoniecRozdzialu()
                        case .krzak: WyjasnienieKrzaka()
                        case .oGrze: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 0)
                }
                .scrollBounceBehavior(.basedOnSize)
                .defaultScrollAnchor(.center)
            }
            }
            .transition(.opacity)
        }
    }
}

/// Menu pauzy dla dziecka: tylko to, co dotyczy gry. Ustawienia są w „Dla rodzica” na ekranie startowym.
struct MenuPauzy: View {
    @Environment(StanGry.self) private var stan
    let rozmiarEkranu: CGSize

    var body: some View {
        if rozmiarEkranu.width > rozmiarEkranu.height && rozmiarEkranu.height <= 700 {
            // Telefon poziomo: przyciski parami, „Graj dalej” i „Wyjdź” na całą szerokość.
            Panel(maksSzerokosc: 760) {
                Text(stan.t("pauza")).font(.kreda(20)).foregroundStyle(Kolory.tekst)
                Grid(horizontalSpacing: 12, verticalSpacing: 6) {
                    GridRow { grajDalej(maly: true).gridCellColumns(2) }
                    GridRow { przebierz; album }
                    GridRow { strzalki; PrzyciskDzwieku(pelnaSzerokosc: true) }
                    GridRow { wyjdz.gridCellColumns(2) }
                }
            }
        } else {
            Panel {
                Text(stan.t("pauza")).font(.kreda(30)).foregroundStyle(Kolory.tekst)
                VStack(spacing: 12) {
                    grajDalej(maly: false)
                    przebierz
                    album
                    strzalki
                    PrzyciskDzwieku(pelnaSzerokosc: true)
                    wyjdz
                }
                .frame(maxWidth: 420)
            }
        }
    }

    private func grajDalej(maly: Bool) -> some View {
        Button { stan.wznow() } label: { Text(stan.t("grajDalej")).frame(maxWidth: .infinity) }
            .buttonStyle(.kreska(Kolory.zolty, maly: maly))
    }

    private var przebierz: some View {
        Button { stan.przebierz() } label: {
            HStack(spacing: 6) { IkonaKoszulki().frame(width: 26, height: 26); Text(stan.t("przebierz")) }.frame(maxWidth: .infinity)
        }
        .buttonStyle(.kreska(Kolory.rozowy, maly: true))
    }

    private var album: some View {
        Button { stan.pokazAlbum() } label: {
            HStack(spacing: 6) { IkonaDziecka(id: "album").frame(width: 24, height: 24); Text(stan.napisAlbumu).monospacedDigit() }
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.kreska(Kolory.rozowy, maly: true))
    }

    private var strzalki: some View {
        Button { stan.przelaczStrzalki() } label: {
            HStack(spacing: 6) {
                IkonaDziecka(id: "strzalka", kierunek: stan.strzalkiUkryte ? .gora : .dol).frame(width: 24, height: 24)
                Text(stan.t(stan.strzalkiUkryte ? "pokazStrzalki" : "ukryjStrzalki"))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.kreska(Kolory.niebieski, maly: true))
    }

    private var wyjdz: some View {
        Button { stan.doStartu() } label: { Text(stan.t("wyjdz")).frame(maxWidth: .infinity) }
            .buttonStyle(.kreska(Kolory.zielony, maly: true))
    }
}

/// „Dźwięk: włączony/wyłączony” — przycisk dla dziecka, wycisza naraz muzykę i dźwięki.
struct PrzyciskDzwieku: View {
    @Environment(StanGry.self) private var stan
    var pelnaSzerokosc = false
    var body: some View {
        Button { stan.przelaczDzwiek() } label: {
            Text(stan.t(stan.dzwiekWlaczony ? "dzwiekWl" : "dzwiekWyl")).frame(maxWidth: pelnaSzerokosc ? .infinity : nil)
        }
        .buttonStyle(.kreska(Kolory.niebieski, maly: true))
        .accessibilityAddTraits(stan.dzwiekWlaczony ? .isSelected : [])
    }
}

struct Brawo: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.colorScheme) private var schemat
    let rozmiarEkranu: CGSize

    /// Telefon poziomo: obrazek po lewej, reszta po prawej (jak `#brawo .panel` w grze na niskim ekranie).
    private var poziomo: Bool { rozmiarEkranu.width > rozmiarEkranu.height && rozmiarEkranu.height <= 700 }

    var body: some View {
        if poziomo {
            Panel(maksSzerokosc: 920) {
                HStack(alignment: .center, spacing: 16) {
                    obraz.frame(maxWidth: .infinity).frame(height: min(240, rozmiarEkranu.height * 0.64))
                    VStack(spacing: 6) {
                        tytul(20)
                        opis
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(Kolory.tekst)
        } else {
            Panel {
                tytul(28)
                obraz.frame(maxWidth: 460).frame(height: min(240, rozmiarEkranu.height * 0.3))
                opis
            }
            .foregroundStyle(Kolory.tekst)
        }
    }

    private func tytul(_ r: CGFloat) -> some View {
        Text(stan.tytulBrawo).font(.kreda(r)).foregroundStyle(Kolory.tekst).multilineTextAlignment(.center)
    }

    private var obraz: some View {
        ObrazBrawo(ciemny: schemat == .dark)
            .accessibilityLabel(stan.wynikDrogi ?? "")
            .accessibilityHidden(stan.wynikDrogi == nil)
    }

    @ViewBuilder private var opis: some View {
            Text(stan.wynikPodp).font(.kreda(poziomo ? 15 : 18, gruby: false)).multilineTextAlignment(.center)
            if let d = stan.wynikDrogi { Text(d).font(.kreda(poziomo ? 15 : 18, gruby: false)).multilineTextAlignment(.center) }
            NowaNaklejka()
            Rzad {
                Button(stan.t("nastepny")) { stan.nastepnyPoziom() }.buttonStyle(.kreska)
                Button { stan.nakladka = .menu; stan.gra.pauza = true } label: {
                    HStack(spacing: 6) { IkonaDziecka(id: "menu").frame(width: 24, height: 24); Text(stan.t("menu")) }
                }
                .buttonStyle(.kreska(Kolory.zielony, maly: true))
            }
    }
}

/// Obrazek na „Brawo”: osiołek z kotkiem przy domku albo plan z drogą dziecka i najkrótszą drogą (`rysujBrawo`).
struct ObrazBrawo: View {
    @Environment(StanGry.self) private var stan
    let ciemny: Bool

    var body: some View {
        Canvas { g, size in
            let c = Plotno(g), w = size.width, h = size.height, gra = stan.gra, lab = gra.lab
            if let p = gra.porownanie {
                let S = Geometria(TW: lab.TW, TH: lab.TH, szer: w, wys: h), x0 = (w - S.W) / 2, y0 = (h - S.H) / 2
                c.save(); c.translate(x0, y0)
                rysujTlo(c, lab, S, Paleta(ciemna: ciemny))
                let C = S.C
                func sx(_ q: Int) -> Double { S.sx(Double(lab.ix(q))) }
                func sy(_ q: Int) -> Double { S.sy(Double(lab.iy(q))) }
                c.strokeStyle = Color(hex: "#3f6fb5"); c.lineWidth = max(2, C * 0.12); c.lineCap = .round
                c.lineDash = [C * 0.25, C * 0.22]
                c.beginPath()
                for (i, q) in p.najkrotsza.enumerated() { if i == 0 { c.moveTo(sx(q), sy(q)) } else { c.lineTo(sx(q), sy(q)) } }
                c.stroke(); c.lineDash = []
                var byly = Set<Int>()
                for (i, q) in p.twoja.enumerated() where i + 1 < p.twoja.count && !byly.contains(q) {
                    byly.insert(q)
                    let n = p.twoja[i + 1]
                    lapka(c, sx(q), sy(q), C * 0.16, atan2(Double(lab.iy(n) - lab.iy(q)), Double(lab.ix(n) - lab.ix(q))) + .pi / 2, kolorK("lapka"))
                }
                rysujKotka(c, sx(lab.kotekI) - C * 0.5, sy(lab.kotekI) - C * 0.38, C, C * 0.75)
                c.restore()
                return
            }
            wpisz(c, SCENA_RAMKA, w * 0.44, 0, w * 0.56, h) { c2, s in rysujScene(c2, s) }
            rysujOsiolka(c, 0, h * 0.18, w * 0.26, h * 0.82, stan.koszulka)
            rysujKotka(c, w * 0.22, h * 0.6, w * 0.24, h * 0.4)
        }
    }
}

/// „Muzyka: włączona/wyłączona” i „Dźwięki: włączone/wyłączone”.
struct PrzelacznikiDzwieku: View {
    var body: some View {
        Rzad {
            PrzyciskMuzyki()
            PrzyciskDzwiekow()
        }
    }
}

struct PrzyciskMuzyki: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Button(stan.t(stan.muzyka ? "muzykaWl" : "muzykaWyl")) { stan.muzyka.toggle(); stan.klik() }
            .buttonStyle(.kreska(Kolory.niebieski, maly: true))
            .accessibilityAddTraits(stan.muzyka ? .isSelected : [])
    }
}

struct PrzyciskDzwiekow: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Button(stan.t(stan.dzwieki ? "dzwiekiWl" : "dzwiekiWyl")) { stan.dzwieki.toggle(); stan.klik() }
            .buttonStyle(.kreska(Kolory.niebieski, maly: true))
            .accessibilityAddTraits(stan.dzwieki ? .isSelected : [])
    }
}

/// „Kolory: jak w urządzeniu / jasne / ciemne” — przełącza po kolei, jak w grze.
struct PrzelacznikMotywu: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        let napis = ["system": "motywSystem", "jasny": "motywJasny", "ciemny": "motywCiemny"][stan.motyw.rawValue] ?? "motywSystem"
        Button(stan.t(napis)) {
            stan.klik()
            let w = WyborMotywu.allCases
            stan.motyw = w[(w.firstIndex(of: stan.motyw)! + 1) % w.count]
        }
        .buttonStyle(.kreska(Kolory.niebieski, maly: true))
    }
}

/// Wybór jednego z ośmiu języków gry (nazwy w ich własnym języku).
struct WyborJezyka: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        @Bindable var stan = stan
        // Menu z własną etykietą: etykieta zwykłego Pickera nie przyjmuje fontu gry.
        Menu {
            Picker(stan.t("jezyk"), selection: $stan.jezyk) {
                ForEach(Teksty.jezyki, id: \.self) { Text(Teksty.nazwa($0)).tag($0) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(Teksty.nazwa(stan.jezyk))
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .bold))
            }
            .font(.kreda(17))
            .foregroundStyle(Kolory.tekst)
            .padding(.horizontal, 14).frame(minHeight: 44)
            .kreska(Kolory.karta)
        }
        .accessibilityLabel(stan.t("jezyk"))
        .accessibilityValue(Teksty.nazwa(stan.jezyk))
    }
}

/// Rząd przycisków, który na wąskim ekranie układa się w kolumnę (jak `.rzad` z zawijaniem w grze),
/// zamiast ucinać napisy.
struct Rzad<Tresc: View>: View {
    @ViewBuilder var tresc: Tresc
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { tresc }
            VStack(spacing: 12) { tresc }
        }
    }
}

/// Koszulka osiołka jako ikona przycisku „Przebierz osiołka” (bez koszulki — pierwsza z szafy).
struct IkonaKoszulki: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        let k = stan.koszulka ?? Koszulka.wszystkie[0]
        Canvas { g, size in wpisz(Plotno(g), k.ramka, 1, 1, size.width - 2, size.height - 2) { c2, s in rysujKoszulke(c2, s, k, 1.2) } }
            .accessibilityHidden(true)
    }
}

/// „Koniec rozdziału” co 5 poziomów: osiołek i kotek odpoczywają; dobry moment, żeby skończyć grę.
struct KoniecRozdzialu: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Panel {
            Text(stan.t("rozdzialH")).font(.kreda(28)).accessibilityAddTraits(.isHeader)
            Canvas { g, size in
                let c = Plotno(g), w = size.width, h = size.height
                wpisz(c, SCENA_RAMKA, w * 0.46, 0, w * 0.54, h) { c2, s in rysujScene(c2, s) }
                rysujOsiolka(c, 0, h * 0.18, w * 0.26, h * 0.82, stan.koszulka)
                rysujKotka(c, w * 0.22, h * 0.6, w * 0.24, h * 0.4)
            }
            .frame(maxWidth: 420).frame(height: 180)
            .accessibilityHidden(true)
            Text(stan.t("rozdzialTekst")).font(.kreda(18, gruby: false)).multilineTextAlignment(.center)
            Button(stan.t("rozdzialKoniec")) { stan.koniecRozdzialu() }.buttonStyle(.kreska(Kolory.zielony))
            Button(stan.t("rozdzialDalej")) { stan.dalejPoRozdziale() }.buttonStyle(.kreska(Kolory.zolty, maly: true))
        }
        .foregroundStyle(Kolory.tekst)
    }
}

/// Pierwszy krzaczek: serduszko → strzałka → znikający krzaczek (`pokazKrzakWyjasnienie`).
struct WyjasnienieKrzaka: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        Panel {
            Text(stan.t("krzakH")).font(.kreda(28)).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Canvas { g, size in
                let c = Plotno(g), w = size.width, h = size.height
                wpisz(c, SERCE_RAMKA, w * 0.02, h * 0.12, w * 0.28, h * 0.76, rysujSerce)
                let D = RYS["IKONY"]["strzalka"]
                c.save()
                wpisz(c, D["ramka"].liczby, w * 0.36, h * 0.25, w * 0.24, h * 0.5) { c2, s in
                    piorko(c2, s, 1, 3)
                    let sr = D["srodek"].liczby
                    c2.translate(sr[0], sr[1]); c2.rotate(0 - D["kat"].liczba); c2.translate(-sr[0], -sr[1])
                    for k in D["ksztalty"].tablica { ksztalt(c2, k.punkty, nil) }
                    for l in D["linie"].tablica { linia(c2, l.punkty) }
                    for o in D["owale"].tablica { owal(c2, o.liczby, nil) }
                }
                c.restore()
                c.save(); c.globalAlpha = 0.35
                wpisz(c, KRZAK_RAMKA, w * 0.66, h * 0.04, w * 0.3, h * 0.92, rysujKrzak)
                c.restore()
            }
            .frame(maxWidth: 420).frame(height: 180)
            .accessibilityLabel(stan.t("krzakTekst"))
            Text(stan.t("krzakTekst")).font(.kreda(18, gruby: false)).multilineTextAlignment(.center)
            Button(stan.t("krzakOk")) { stan.krzakOk() }.buttonStyle(.kreska)
        }
        .foregroundStyle(Kolory.tekst)
    }
}
