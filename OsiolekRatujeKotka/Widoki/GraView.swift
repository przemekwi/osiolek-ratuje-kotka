import SwiftUI
import UIKit

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
                        Strzalki(kompakt: true).frame(maxWidth: 260)
                    }
                } else {
                    PlanszaView(ciemny: schemat == .dark)
                    Strzalki()
                }
            }
        }
        .padding(8)
        .background(Kolory.tlo.ignoresSafeArea())
        .overlay(alignment: .top) { DymekOstrzezenia() }
        // Gesty systemowe przy krawędziach (np. przesunięcie do ekranu głównego) wymagają drugiego przeciągnięcia,
        // dzięki czemu dotyk strzałek przy dolnej krawędzi trafia do gry od razu, bez czekania systemu.
        .defersSystemGestures(on: .all)
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
        // Szeroki ekran: napisy i przyciski w jednym wierszu; wąski (telefon pionowo): przyciski pod napisami, jak w grze.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 14) {
                napisy
                Spacer(minLength: 4)
                przyciski
            }
            VStack(alignment: .leading, spacing: 6) {
                napisy
                HStack(spacing: 8) { przyciski }.frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: 1200)
    }

    private var napisy: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 16) {
                Text(stan.t("poziom", ["n": stan.poziom])).font(.kreda(21)).lineLimit(1).fixedSize()
                if stan.gra.sercaN > 0 { Zbierane() }
            }
            .frame(height: 30, alignment: .leading)
            .foregroundStyle(Kolory.tekst)
            // Zadanie zawsze w jednym wierszu o stałej wysokości (jak w grze): zmiana „Znajdź kotka” na „Wróć z kotkiem
            // do domku” nie zmienia wysokości paska, więc plansza nie przelicza rozmiaru w trakcie poziomu.
            Text(stan.napisZadania)
                .font(.kreda(19))
                .foregroundStyle(Kolory.zaznaczenie)
                .lineLimit(1).minimumScaleFactor(0.75).truncationMode(.tail)
                .frame(height: 26, alignment: .leading)
        }
    }

    @ViewBuilder private var przyciski: some View {
        PrzyciskPodpowiedzi()
        Button { stan.pokazAlbum() } label: {
            HStack(spacing: 4) { IkonaDziecka(id: "album").frame(width: 24, height: 24); Text(stan.napisAlbumu).monospacedDigit().napisPaska() }
        }
        .buttonStyle(.kreska(Kolory.rozowy, maly: true))
        Button { stan.pauza() } label: {
            HStack(spacing: 4) { IkonaDziecka(id: "menu").frame(width: 24, height: 24); Text(stan.t("menu")).napisPaska() }
        }
        .buttonStyle(.kreska(Kolory.zolty, maly: true))
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
    /// Niski ekran poziomo: mniejsze przyciski (jak w grze), żeby plansza dostała więcej miejsca.
    var kompakt = false

    var body: some View {
        VStack(spacing: 6) {
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    PrzyciskStrzalki(kierunek: .gora, napis: stan.t("gora"), kompakt: kompakt)
                    Color.clear.frame(width: 1, height: 1)
                }
                GridRow {
                    PrzyciskStrzalki(kierunek: .lewo, napis: stan.t("lewo"), kompakt: kompakt)
                    PrzyciskStrzalki(kierunek: .dol, napis: stan.t("dol"), kompakt: kompakt)
                    PrzyciskStrzalki(kierunek: .prawo, napis: stan.t("prawo"), kompakt: kompakt)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stan.t("strzalki"))
            Text(stan.t("sterDotyk"))
                .font(.kreda(kompakt ? 12 : 14, gruby: false))
                .foregroundStyle(Kolory.ciche)
                .multilineTextAlignment(.center)
        }
    }
}

struct PrzyciskStrzalki: View {
    @Environment(StanGry.self) private var stan
    let kierunek: Kierunek
    let napis: String
    var kompakt = false
    @State private var wcisniety = false

    var body: some View {
        VStack(spacing: 0) {
            IkonaDziecka(id: "strzalka", kierunek: kierunek).frame(width: kompakt ? 22 : 28, height: kompakt ? 22 : 28)
            Text(napis).font(.kreda(kompakt ? 12 : 14))
        }
        .foregroundStyle(Kolory.napisPrzycisku)
        .frame(width: kompakt ? 74 : 90, height: kompakt ? 50 : 62)
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

/// „Podpowiedź”: przez odliczanie przycisk wypełnia się jak pasek, a żarówka jest blada; gdy podpowiedź jest gotowa,
/// żarówka raz się rozjaśnia (jak `#podpowiedz.laduje` i `.blysk` w grze).
struct PrzyciskPodpowiedzi: View {
    @Environment(StanGry.self) private var stan
    @Environment(\.colorScheme) private var schemat
    @Environment(\.accessibilityReduceMotion) private var ograniczRuch

    var body: some View {
        let laduje = stan.podpZa > 0
        let p = stan.podpPasek
        // W motywie ciemnym niewypełniona część jest jasna, żeby napis był czytelny.
        let reszta = schemat == .dark ? Kolory.ciche : Kolory.karta
        let pasek = LinearGradient(stops: [.init(color: Kolory.zielony, location: 0), .init(color: Kolory.zielony, location: p),
                                           .init(color: reszta, location: p), .init(color: reszta, location: 1)],
                                   startPoint: .leading, endPoint: .trailing)
        Button { stan.pokazPodpowiedz() } label: {
            HStack(spacing: 6) {
                IkonaDziecka(id: "podpowiedz")
                    .frame(width: 26, height: 26)
                    .opacity(laduje ? 0.35 : 1)
                    .phaseAnimator([0.0, 0.5, 0.0], trigger: stan.podpGotowa) { v, b in v.brightness(ograniczRuch ? 0 : b) }
                Text(laduje ? stan.t("podpZa", ["s": stan.podpZa]) : stan.t("podpowiedz"))
                    .monospacedDigit()
                    .napisPaska()
            }
        }
        .buttonStyle(PrzyciskKreska(kolor: Kolory.zielony, maly: true, wypelnienie: laduje ? AnyShapeStyle(pasek) : nil))
        .accessibilityHint(laduje ? stan.t("podpZa", ["s": stan.podpZa]) : "")
    }
}

extension Text {
    /// Napis przycisku na pasku: jak w grze mniejszy na telefonie, a gdy brakuje miejsca — lekko ściśnięty.
    func napisPaska() -> some View { font(.kreda(15)).lineLimit(1).minimumScaleFactor(0.6) }
}

/// „Jeszcze chwilka, potem przerwa.” — łagodne ostrzeżenie 2 minuty przed końcem czasu, widoczne przez 6 sekund.
struct DymekOstrzezenia: View {
    @Environment(StanGry.self) private var stan
    @State private var widoczny = false

    var body: some View {
        Group {
            if widoczny {
                Text(stan.t("ostrzezenie"))
                    .font(.kreda(18))
                    .foregroundStyle(Kolory.napisPrzycisku)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .kreska(Kolory.zolty)
                    .padding(.top, 70)
                    .transition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: stan.ostrzezenia) {
            withAnimation(.easeInOut(duration: 0.3)) { widoczny = true }
            UIAccessibility.post(notification: .announcement, argument: stan.t("ostrzezenie"))
            Task {
                try? await Task.sleep(for: .seconds(6))
                withAnimation(.easeInOut(duration: 0.3)) { widoczny = false }
            }
        }
    }
}
