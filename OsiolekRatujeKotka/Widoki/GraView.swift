import SwiftUI

/// Ekran gry: pasek u góry, plansza i strzałki (pod planszą, a na niskim ekranie poziomo — obok niej).
struct GraView: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.colorScheme) private var schemat
    @Environment(\.accessibilityReduceMotion) private var ograniczRuch

    var body: some View {
        GeometryReader { geo in
            let bok = geo.size.width > geo.size.height && geo.size.height <= 700
            VStack(spacing: 8) {
                PasekGry()
                if bok {
                    HStack(spacing: 8) {
                        PlanszaView(ciemny: schemat == .dark)
                        Strzalki().frame(maxWidth: 320)
                    }
                } else {
                    PlanszaView(ciemny: schemat == .dark)
                    Strzalki()
                }
            }
        }
        .padding(8)
        .background(Kolory.tlo.ignoresSafeArea())
        .overlay { NakladkiGry() }
        .background(KlawiaturaSprzetowa { klawisz, wcisniety in obsluzKlawisz(klawisz, wcisniety) })
        .sensoryFeedback(.impact(weight: .light), trigger: stan.uderzenia)
        .sensoryFeedback(.success, trigger: stan.spotkania)
        .onAppear { stan.gra.ograniczonyRuch = ograniczRuch }
        .onChange(of: ograniczRuch) { _, n in stan.gra.ograniczonyRuch = n }
        .accessibilityElement(children: .contain)
    }

    /// Klawiatura sprzętowa (iPad, Mac z symulatorem): strzałki i W A S D prowadzą osiołka, P albo Esc — pauza.
    private func obsluzKlawisz(_ klawisz: Klawisz, _ wcisniety: Bool) {
        let gra = stan.gra
        switch klawisz {
        case .pauza:
            guard wcisniety else { return }
            if stan.nakladka == .menu { stan.wznow() } else if gra.wGrze && stan.nakladka == nil { stan.pauza() }
        case .kierunek(let k):
            let zrodlo = "klawisz:\(k)"
            if wcisniety {
                if gra.wGrze && stan.nakladka == nil { gra.trzymaj(zrodlo, k.rawValue) }
            } else {
                gra.pusc(zrodlo)
            }
        }
    }
}

/// Pasek: poziom, zadanie, czas, przedmioty do zebrania i menu.
struct PasekGry: View {
    @Environment(StanGry.self) private var stan

    // Jak w grze w trybie dla dziecka: poziom i przedmioty w pierwszym wierszu, zadanie pod spodem
    // w kolorze wyróżnienia; bez zegara (tryb dla dziecka ukrywa czas).
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 16) {
                    Text(stan.t("poziom", ["n": stan.poziom])).font(.kreda(21))
                    if stan.gra.sercaN > 0 { Zbierane() }
                }
                .foregroundStyle(Kolory.tekst)
                Text(stan.napisZadania)
                    .font(.kreda(19))
                    .foregroundStyle(Kolory.zaznaczenie)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            Button { stan.pauza() } label: {
                HStack(spacing: 6) {
                    IkonaDziecka(id: "menu").frame(width: 26, height: 26)
                    Text(stan.t("menu"))
                }
            }
            .buttonStyle(.kreska(Kolory.zolty, maly: true))
        }
        .frame(maxWidth: 1200)
    }
}

/// Przedmioty do zebrania na pasku: niepokolorowane, a zebrany się koloruje (dziecko widzi, ile zostało, bez liczenia).
struct Zbierane: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.colorScheme) private var schemat

    var body: some View {
        let gra = stan.gra, p = gra.przedmiot
        HStack(spacing: 2) {
            ForEach(0..<gra.sercaN, id: \.self) { i in
                let zebrany = i < stan.zebrane
                let jasnaKreska = !zebrany && schemat == .dark
                Canvas { g, size in
                    let c = Plotno(g)
                    let rysuj: (Plotno) -> Void = { cc in
                        wpisz(cc, ramkaPrzedmiotu(p), 1, 1, size.width - 2, size.height - 2) { c2, s in rysujPrzedmiot(c2, s, p, kolor: zebrany) }
                    }
                    // Kontur długopisem ginie na ciemnym tle: niepokolorowany obrazek dostaje jasną kreskę (--tusz motywu ciemnego).
                    if jasnaKreska { c.warstwa(filtry: [jednolity(Color(hex: "#c4cae4"))], rysuj) } else { rysuj(c) }
                }
                .frame(width: 26, height: 26)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(stan.t("zebraneStan", ["co": Teksty.surowy(stan.jezyk, "przedmioty")[p.rawValue][0].napis,
                                                     "n": stan.zebrane, "m": gra.sercaN]))
    }
}

/// Plansza: tło (ściany, podłoże, domek) rysowane raz na poziom i ruchoma warstwa rysowana co klatkę.
struct PlanszaView: View {
    @Environment(StanGry.self) private var stan
    let ciemny: Bool

    var body: some View {
        GeometryReader { geo in
            let gra = stan.gra
            ZStack {
                Color.clear
                    .onAppear { stan.ustawRamke(geo.size) }
                    .onChange(of: geo.size) { _, n in stan.ustawRamke(n) }
                if stan.wersja > 0 && !gra.lab.G.isEmpty {
                    let S = Geometria(TW: gra.lab.TW, TH: gra.lab.TH, szer: geo.size.width, wys: geo.size.height)
                    ZStack(alignment: .topLeading) {
                        TloPlanszy(lab: gra.lab, S: S, ciemny: ciemny, wersja: stan.wersja).equatable()
                        TimelineView(.animation(paused: stan.nakladka != nil)) { tl in
                            Canvas { g, _ in
                                rysujPlansze(Plotno(g), gra, S, Paleta(ciemna: ciemny),
                                             t: tl.date.timeIntervalSinceReferenceDate, koszulka: stan.koszulka)
                            }
                        }
                    }
                    .frame(width: S.W, height: S.H)
                    .background(Kolory.cien.offset(x: 4, y: 5))
                    .contentShape(Rectangle())
                    .gesture(palec(S))
                    .accessibilityElement()
                    .accessibilityLabel(stan.t("plansza"))
                    .accessibilityValue(stan.komunikat)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Palec na planszy prowadzi osiołka w stronę palca, dopóki dotyka ekranu.
    private func palec(_ S: Geometria) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in
                let gra = stan.gra
                gra.geo = S
                let pierwszy = gra.palec == nil
                gra.palec = (v.location.x, v.location.y)
                if pierwszy && stan.nakladka == nil { gra.trzymaj("palec", 0) }
            }
            .onEnded { _ in
                stan.gra.palec = nil
                stan.gra.pusc("palec")
            }
    }
}

/// Tło planszy jako osobny widok: przelicza się tylko przy nowym poziomie, zmianie rozmiaru albo motywu.
struct TloPlanszy: View, Equatable {
    let lab: Labirynt
    let S: Geometria
    let ciemny: Bool
    let wersja: Int

    static func == (a: TloPlanszy, b: TloPlanszy) -> Bool { a.wersja == b.wersja && a.S == b.S && a.ciemny == b.ciemny }

    var body: some View {
        Canvas { g, _ in rysujTlo(Plotno(g), lab, S, Paleta(ciemna: ciemny)) }
            .frame(width: S.W, height: S.H)
            .accessibilityHidden(true)
    }
}

/// Strzałki: osiołek idzie, dopóki dziecko trzyma przycisk.
struct Strzalki: View {
    @Environment(StanGry.self) private var stan

    var body: some View {
        VStack(spacing: 6) {
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    PrzyciskStrzalki(kierunek: .gora, napis: stan.t("gora"))
                    Color.clear.frame(width: 1, height: 1)
                }
                GridRow {
                    PrzyciskStrzalki(kierunek: .lewo, napis: stan.t("lewo"))
                    PrzyciskStrzalki(kierunek: .dol, napis: stan.t("dol"))
                    PrzyciskStrzalki(kierunek: .prawo, napis: stan.t("prawo"))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stan.t("strzalki"))
            Text(stan.t("sterDotyk"))
                .font(.kreda(14, gruby: false))
                .foregroundStyle(Kolory.ciche)
                .multilineTextAlignment(.center)
        }
    }
}

struct PrzyciskStrzalki: View {
    @Environment(StanGry.self) private var stan
    let kierunek: Kierunek
    let napis: String
    @State private var wcisniety = false

    var body: some View {
        VStack(spacing: 0) {
            IkonaDziecka(id: "strzalka", kierunek: kierunek).frame(width: 28, height: 28)
            Text(napis).font(.kreda(14))
        }
        .foregroundStyle(Kolory.napisPrzycisku)
        .frame(width: 90, height: 62)
        .kreska(Kolory.niebieski)
        .background(KsztaltKreski().fill(Kolory.cien).offset(x: wcisniety ? 0 : 2, y: wcisniety ? 0 : 3))
        .offset(y: wcisniety ? 2 : 0)
        .contentShape(KsztaltKreski())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !wcisniety else { return }
                    wcisniety = true
                    if stan.nakladka == nil { stan.gra.trzymaj("przycisk:\(kierunek)", kierunek.rawValue) }
                }
                .onEnded { _ in
                    wcisniety = false
                    stan.gra.pusc("przycisk:\(kierunek)")
                }
        )
        .accessibilityElement()
        .accessibilityLabel(napis)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // VoiceOver: jedno stuknięcie to jeden krok.
            stan.gra.trzymaj("przycisk:\(kierunek)", kierunek.rawValue)
            stan.gra.pusc("przycisk:\(kierunek)")
        }
    }
}
