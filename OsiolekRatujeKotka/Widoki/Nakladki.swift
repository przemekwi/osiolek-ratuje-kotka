import SwiftUI

/// Nakładki nad planszą: przyciemnione tło i panel (menu pauzy, „Brawo”).
struct NakladkiGry: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        if let n = stan.nakladka {
            ZStack {
                Color.black.opacity(0.44).ignoresSafeArea()
                ScrollView {
                    Group {
                        switch n {
                        case .menu: MenuPauzy()
                        case .brawo: Brawo()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 0)
                }
                .scrollBounceBehavior(.basedOnSize)
                .defaultScrollAnchor(.center)
            }
            .transition(.opacity)
        }
    }
}

struct MenuPauzy: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        Panel {
            Text(stan.t("pauza")).font(.kreda(30)).foregroundStyle(Kolory.tekst)
            VStack(spacing: 12) {
                Button(stan.t("grajDalej")) { stan.wznow() }.buttonStyle(.kreska)
                Button(stan.t("nowaGra")) { stan.nowaGra() }.buttonStyle(.kreska(Kolory.zielony, maly: true))
                PrzelacznikMotywu()
                WyborJezyka()
                Button(stan.t("wyjdz")) { stan.doStartu() }.buttonStyle(.kreska(Kolory.zielony, maly: true))
            }
            .frame(maxWidth: 420)
        }
    }
}

struct Brawo: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.colorScheme) private var schemat

    var body: some View {
        Panel {
            Text(stan.tytulBrawo).font(.kreda(28)).foregroundStyle(Kolory.tekst).multilineTextAlignment(.center)
            ObrazBrawo(ciemny: schemat == .dark)
                .frame(maxWidth: 460).frame(height: 240)
                .accessibilityLabel(stan.wynikDrogi ?? "")
                .accessibilityHidden(stan.wynikDrogi == nil)
            Text(stan.wynikBrawo).font(.kreda(18, gruby: false))
            Text(stan.wynikPodp).font(.kreda(18, gruby: false)).multilineTextAlignment(.center)
            if let d = stan.wynikDrogi { Text(d).font(.kreda(18, gruby: false)).multilineTextAlignment(.center) }
            HStack(spacing: 12) {
                Button(stan.t("nastepny")) { stan.nastepnyPoziom() }.buttonStyle(.kreska)
                Button { stan.nakladka = .menu; stan.gra.pauza = true } label: {
                    HStack(spacing: 6) { IkonaDziecka(id: "menu").frame(width: 24, height: 24); Text(stan.t("menu")) }
                }
                .buttonStyle(.kreska(Kolory.zielony, maly: true))
            }
        }
        .foregroundStyle(Kolory.tekst)
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

/// „Kolory: jak w urządzeniu / jasne / ciemne” — przełącza po kolei, jak w grze.
struct PrzelacznikMotywu: View {
    @Environment(StanGry.self) private var stan
    var body: some View {
        let napis = ["system": "motywSystem", "jasny": "motywJasny", "ciemny": "motywCiemny"][stan.motyw.rawValue] ?? "motywSystem"
        Button(stan.t(napis)) {
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
        Picker(stan.t("jezyk"), selection: $stan.jezyk) {
            ForEach(Teksty.jezyki, id: \.self) { Text(Teksty.nazwa($0)).tag($0) }
        }
        .pickerStyle(.menu)
        .tint(Kolory.tekst)
        .font(.kreda(17))
        .padding(.horizontal, 14).frame(minHeight: 44)
        .kreska(Kolory.karta)
        .accessibilityLabel(stan.t("jezyk"))
    }
}
