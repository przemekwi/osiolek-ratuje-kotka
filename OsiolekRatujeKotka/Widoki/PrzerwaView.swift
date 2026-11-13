import SwiftUI

/// „Czas na przerwę!” nad całą aplikacją (jak `#przerwa` w grze). Grę odblokowuje rodzic: wpisuje cyframi liczbę
/// zapisaną słowami, a potem wybiera, czy dziecko gra dalej i jak długo.
struct PrzerwaView: View {
    @Environment(StanGry.self) private var stan
    @State private var odpowiedz = ""
    @State private var blad = false
    @State private var wyborPrzedluzenia = false
    @FocusState private var pole: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.44).ignoresSafeArea()
            ScrollView {
                Panel {
                    Text(stan.t("przerwaH")).font(.kreda(28)).foregroundStyle(Kolory.tekst).accessibilityAddTraits(.isHeader)
                    Canvas { g, size in
                        let c = Plotno(g), w = size.width, h = size.height
                        wpisz(c, SCENA_RAMKA, w * 0.46, 0, w * 0.54, h) { c2, s in rysujScene(c2, s) }
                        rysujOsiolka(c, 0, h * 0.18, w * 0.26, h * 0.82, stan.koszulka)
                        rysujKotka(c, w * 0.22, h * 0.6, w * 0.24, h * 0.4)
                    }
                    .frame(maxWidth: 420).frame(height: 180)
                    .accessibilityHidden(true)
                    Text(stan.t("przerwaTekst")).font(.kreda(18, gruby: false)).multilineTextAlignment(.center)
                    if wyborPrzedluzenia { przedluzenie } else { pytanie }
                }
                .foregroundStyle(Kolory.tekst)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center)
        }
    }

    /// Pytanie dla rodzica: liczba słowami, odpowiedź cyframi.
    private var pytanie: some View {
        VStack(spacing: 8) {
            Text(stan.t("rodzicH")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            Text(stan.pytanieRodzica).font(.kreda(18))
            TextField("", text: $odpowiedz)
                .keyboardType(.numberPad)
                .font(.kreda(24))
                .multilineTextAlignment(.center)
                .frame(width: 120)
                .padding(6)
                .kreska(Kolory.karta)
                .focused($pole)
                .onSubmit(sprawdz)
                .accessibilityLabel(stan.pytanieRodzica)
            Button(stan.t("odblokuj"), action: sprawdz).buttonStyle(.kreska(Kolory.zielony, maly: true))
            if blad { Text(stan.t("rodzicBlad")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche) }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }

    private func sprawdz() {
        if stan.odblokuj(odpowiedz) {
            blad = false; pole = false; wyborPrzedluzenia = true
        } else {
            blad = true
        }
        odpowiedz = ""
    }

    /// Rodzic decyduje: koniec grania albo przedłużenie (w trybie dla dziecka każde kolejne krótsze).
    private var przedluzenie: some View {
        VStack(spacing: 8) {
            Text(stan.t("przedluzTekst", ["m": max(1, Int((stan.limit.razem / 60).rounded()))]))
                .font(.kreda(18)).multilineTextAlignment(.center)
            Text(stan.t("przedluzKrotsze")).font(.kreda(15, gruby: false)).foregroundStyle(Kolory.ciche).multilineTextAlignment(.center)
            if stan.limit.pokazDobro {
                Text(stan.t("przedluzDobro")).font(.kreda(18)).multilineTextAlignment(.center)
            }
            Button(stan.t("przedluzKoniec")) {
                stan.koniecGrania()
                wyborPrzedluzenia = false
            }
            .buttonStyle(.kreska(Kolory.zielony, maly: true))
            Rzad {
                ForEach(stan.limit.opcjePrzedluzenia, id: \.self) { m in
                    Button(stan.t("przedluzMin", ["m": m])) {
                        stan.przedluz(m)
                        wyborPrzedluzenia = false
                    }
                    .buttonStyle(.kreska(Kolory.zolty, maly: true))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .kreska(Color.clear)
    }
}
