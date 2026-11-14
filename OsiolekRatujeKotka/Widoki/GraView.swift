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
                // Układ paska zależy tylko od szerokości ekranu, nie od długości napisów (inaczej odliczanie
                // podpowiedzi przełączało pasek na dwa wiersze i plansza zmieniała rozmiar).
                PasekGry(jedenWiersz: geo.size.width >= 680)
                if bok {
                    HStack(spacing: 8) {
                        PlanszaView(ciemny: schemat == .dark)
                        if !stan.strzalkiUkryte { Strzalki(kompakt: true).frame(maxWidth: 260).transition(.move(edge: .trailing).combined(with: .opacity)) }
                    }
                } else {
                    PlanszaView(ciemny: schemat == .dark)
                    if !stan.strzalkiUkryte { Strzalki().transition(.move(edge: .bottom).combined(with: .opacity)) }
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
        // Wibracje (wyłączane w „Dla rodzica”): ściana — lekkie stuknięcie, przedmiot — miękkie,
        // kotek — sukces, nowa naklejka na „Brawo” — mocniejsze stuknięcie.
        .sensoryFeedback(trigger: stan.uderzenia) { _, _ in stan.wibracje ? .impact(weight: .light, intensity: 0.7) : nil }
        .sensoryFeedback(trigger: stan.zebrania) { _, _ in stan.wibracje ? .impact(flexibility: .soft, intensity: 0.8) : nil }
        .sensoryFeedback(trigger: stan.spotkania) { _, _ in stan.wibracje ? .success : nil }
        .sensoryFeedback(trigger: stan.naklejki) { _, _ in stan.wibracje ? .impact(weight: .heavy) : nil }
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
    let jedenWiersz: Bool

    // Jak w grze w trybie dla dziecka: poziom i przedmioty w pierwszym wierszu, zadanie pod spodem
    // w kolorze wyróżnienia; bez zegara (tryb dla dziecka ukrywa czas).
    var body: some View {
        // Szeroki ekran: napisy i przyciski w jednym wierszu; wąski (telefon pionowo): przyciski pod napisami, jak w grze.
        Group {
            if jedenWiersz {
                HStack(alignment: .center, spacing: 14) {
                    napisy
                    Spacer(minLength: 4)
                    przyciski
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    napisy
                    HStack(spacing: 8) { przyciski }.frame(maxWidth: .infinity)
                }
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
        // Na pasku tylko to, czego dziecko potrzebuje w trakcie labiryntu; album i strzałki są w menu.
        PrzyciskPodpowiedzi()
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
    /// Kierunek trzymany palcem (podświetla przycisk).
    @State private var wcisniety: Kierunek?
    /// Prostokąty przycisków w układzie krzyżaka (do zamiany punktu dotyku na kierunek).
    @State private var ramki: [Kierunek: CGRect] = [:]
    private let przestrzen = "krzyzak"

    var body: some View {
        VStack(spacing: 6) {
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    przycisk(.gora, "gora")
                    Color.clear.frame(width: 1, height: 1)
                }
                GridRow {
                    przycisk(.lewo, "lewo")
                    przycisk(.dol, "dol")
                    przycisk(.prawo, "prawo")
                }
            }
            .coordinateSpace(.named(przestrzen))
            // Dotyk przez UIKit (touchesBegan/Moved/Ended): bez opóźnienia rozpoznawania gestu SwiftUI;
            // przesunięcie palca na inną strzałkę od razu zmienia kierunek, jak krzyżak w padzie.
            .overlay { DotykKrzyzaka(ramki: ramki, zmiana: zmienKierunek).accessibilityHidden(true) }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stan.t("strzalki"))
            Text(stan.t("sterDotyk"))
                .font(.kreda(kompakt ? 12 : 14, gruby: false))
                .foregroundStyle(Kolory.ciche)
                .multilineTextAlignment(.center)
        }
        .onDisappear { zmienKierunek(nil) }
    }

    private func zmienKierunek(_ k: Kierunek?) {
        guard k != wcisniety else { return }
        wcisniety = k
        if let k, stan.nakladka == nil { stan.gra.trzymaj("przycisk", k.rawValue) } else { stan.gra.pusc("przycisk") }
    }

    private func przycisk(_ k: Kierunek, _ klucz: String) -> some View {
        let napis = stan.t(klucz), w = wcisniety == k
        return VStack(spacing: 0) {
            IkonaDziecka(id: "strzalka", kierunek: k).frame(width: kompakt ? 22 : 28, height: kompakt ? 22 : 28)
            Text(napis).font(.kreda(kompakt ? 12 : 14))
        }
        .foregroundStyle(Kolory.napisPrzycisku)
        .frame(width: kompakt ? 74 : 90, height: kompakt ? 50 : 62)
        .kreska(Kolory.niebieski)
        .background(KsztaltKreski().fill(Kolory.cien).offset(x: w ? 0 : 2, y: w ? 0 : 3))
        .offset(y: w ? 2 : 0)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(przestrzen)) } action: { ramki[k] = $0 }
        .accessibilityElement()
        .accessibilityLabel(napis)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            // VoiceOver: jedno stuknięcie to jeden krok.
            stan.gra.trzymaj("przycisk:\(k)", k.rawValue)
            stan.gra.pusc("przycisk:\(k)")
        }
    }
}

/// Przezroczysta warstwa nad strzałkami, która od razu przekazuje dotyk (wiele palców: liczy się ostatni).
struct DotykKrzyzaka: UIViewRepresentable {
    let ramki: [Kierunek: CGRect]
    let zmiana: (Kierunek?) -> Void

    func makeUIView(context: Context) -> Widok {
        let v = Widok()
        v.isMultipleTouchEnabled = true
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ v: Widok, context: Context) {
        v.ramki = ramki
        v.zmiana = zmiana
    }

    final class Widok: UIView {
        var ramki: [Kierunek: CGRect] = [:]
        var zmiana: ((Kierunek?) -> Void)?
        private var palce: [(UITouch, Kierunek?)] = []

        private func kierunek(_ p: CGPoint) -> Kierunek? {
            // Lekki zapas wokół przycisków: mały palec nie musi trafić idealnie.
            ramki.first { $0.value.insetBy(dx: -6, dy: -6).contains(p) }?.key
        }

        private func odswiez() { zmiana?(palce.last(where: { $0.1 != nil })?.1) }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for t in touches { palce.append((t, kierunek(t.location(in: self)))) }
            odswiez()
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            for t in touches { if let i = palce.firstIndex(where: { $0.0 === t }) { palce[i].1 = kierunek(t.location(in: self)) } }
            odswiez()
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            palce.removeAll { p in touches.contains { $0 === p.0 } }
            odswiez()
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { touchesEnded(touches, with: event) }
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
                // Stała szerokość: niewidoczny najdłuższy napis rezerwuje miejsce, więc odliczanie nie zmienia rozmiaru przycisku.
                ZStack {
                    Text(stan.t("podpZa", ["s": 25])).monospacedDigit().napisPaska().hidden()
                    Text(stan.t("podpowiedz")).napisPaska().hidden()
                    Text(laduje ? stan.t("podpZa", ["s": stan.podpZa]) : stan.t("podpowiedz"))
                        .monospacedDigit()
                        .napisPaska()
                }
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
