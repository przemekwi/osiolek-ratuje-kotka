import SwiftUI

/// Kolory interfejsu z arkusza gry webowej (zmienne --tlo, --karta, --tusz…): stonowane, bez czystej bieli i czerni.
enum Kolory {
    private static func para(_ jasny: String, _ ciemny: String) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: ciemny)) : UIColor(Color(hex: jasny)) })
    }
    static let tlo = para("#f7f2e8", "#1b2030")
    static let karta = para("#fffcf5", "#262c3e")
    static let tusz = para("#3d4370", "#c4cae4")
    static let tekst = para("#363b6b", "#e6e8f2")
    static let ciche = para("#62668a", "#aeb3cf")
    static let zolty = para("#f2d58f", "#cfae62")
    static let niebieski = para("#b7d4e6", "#7d9bb3")
    static let rozowy = para("#ebc3d3", "#b88aa0")
    static let zielony = para("#c6ddb8", "#86a678")
    static let napisPrzycisku = para("#2a2e52", "#171b29")
    static let cien = para("#3d437026", "#00000055")
    static let zaznaczenie = para("#a3436a", "#e7a3bf")
}

/// Font jak w grze („Comic Sans MS”, „Chalkboard SE”…): na iPhonie i iPadzie to systemowy Chalkboard SE.
extension Font {
    static func kreda(_ rozmiar: CGFloat, gruby: Bool = true) -> Font {
        .custom(gruby ? "ChalkboardSE-Bold" : "ChalkboardSE-Regular", size: rozmiar)
    }
}

/// Obramowanie „kreska”: jak linia długopisem na kartce, z nierównymi zaokrągleniami
/// (CSS: border-radius: 255px 18px 225px 18px / 18px 225px 18px 255px).
struct KsztaltKreski: Shape {
    func path(in r: CGRect) -> Path {
        // Promienie [poziomy, pionowy] rogów: lewy górny, prawy górny, prawy dolny, lewy dolny.
        var lg: (CGFloat, CGFloat) = (255, 18), pg: (CGFloat, CGFloat) = (18, 225)
        var pd: (CGFloat, CGFloat) = (225, 18), ld: (CGFloat, CGFloat) = (18, 255)
        // Jak w CSS: gdy promienie się nie mieszczą, wszystkie maleją w tej samej proporcji.
        let f: CGFloat = min(1, r.width / (lg.0 + pg.0), r.width / (ld.0 + pd.0), r.height / (lg.1 + ld.1), r.height / (pg.1 + pd.1))
        lg = (lg.0 * f, lg.1 * f); pg = (pg.0 * f, pg.1 * f); pd = (pd.0 * f, pd.1 * f); ld = (ld.0 * f, ld.1 * f)
        let k: CGFloat = 0.5523
        var p = Path()
        p.move(to: CGPoint(x: r.minX + lg.0, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - pg.0, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + pg.1),
                   control1: CGPoint(x: r.maxX - pg.0 * (1 - k), y: r.minY), control2: CGPoint(x: r.maxX, y: r.minY + pg.1 * (1 - k)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - pd.1))
        p.addCurve(to: CGPoint(x: r.maxX - pd.0, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.maxY - pd.1 * (1 - k)), control2: CGPoint(x: r.maxX - pd.0 * (1 - k), y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + ld.0, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - ld.1),
                   control1: CGPoint(x: r.minX + ld.0 * (1 - k), y: r.maxY), control2: CGPoint(x: r.minX, y: r.maxY - ld.1 * (1 - k)))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + lg.1))
        p.addCurve(to: CGPoint(x: r.minX + lg.0, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + lg.1 * (1 - k)), control2: CGPoint(x: r.minX + lg.0 * (1 - k), y: r.minY))
        p.closeSubpath()
        return p
    }
}

extension View {
    /// Tło z obramowaniem „kreska” (3 pt, kolor tuszu).
    func kreska<S: ShapeStyle>(_ tlo: S) -> some View {
        background(KsztaltKreski().fill(tlo))
            .overlay(KsztaltKreski().stroke(Kolory.tusz, lineWidth: 3))
    }
}

/// Przycisk gry: żółty (domyślnie), niebieski, różowy albo zielony; duży albo mały, z cieniem przesuwającym się przy wciśnięciu.
struct PrzyciskKreska: ButtonStyle {
    var kolor: Color = Kolory.zolty
    var maly = false
    /// Własne wypełnienie zamiast koloru (np. pasek odliczania podpowiedzi).
    var wypelnienie: AnyShapeStyle?

    func makeBody(configuration: Configuration) -> some View {
        let wcisniety = configuration.isPressed
        // Na tle karty napis w kolorze tekstu: w motywie ciemnym karta jest ciemna jak napis przycisku
        // (ten sam problem gra webowa rozwiązuje osobnym tłem podpowiedzi).
        return configuration.label
            .font(.kreda(maly ? 17 : 22))
            .foregroundStyle(kolor == Kolory.karta ? Kolory.tekst : Kolory.napisPrzycisku)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, maly ? 14 : 24)
            .padding(.vertical, maly ? 6 : 10)
            .frame(minHeight: maly ? 46 : 56)
            .kreska(wypelnienie ?? AnyShapeStyle(kolor))
            .background(KsztaltKreski().fill(Kolory.cien).offset(x: wcisniety ? 1 : 3, y: wcisniety ? 1 : 4))
            .offset(x: wcisniety ? 2 : 0, y: wcisniety ? 3 : 0)
            .contentShape(KsztaltKreski())
    }
}

extension ButtonStyle where Self == PrzyciskKreska {
    static var kreska: PrzyciskKreska { PrzyciskKreska() }
    static func kreska(_ kolor: Color, maly: Bool = false) -> PrzyciskKreska { PrzyciskKreska(kolor: kolor, maly: maly) }
}

/// Panel nakładki (menu, „Brawo”…): karta z obramowaniem „kreska” i cieniem.
struct Panel<Tresc: View>: View {
    /// 640 pt jak w grze; na telefonie poziomo szerzej (920 pt), bo treść stoi w dwóch kolumnach.
    var maksSzerokosc: CGFloat = 640
    @ViewBuilder var tresc: Tresc
    var body: some View {
        VStack(spacing: 12) { tresc }
            .padding(.horizontal, 20).padding(.vertical, maksSzerokosc > 640 ? 10 : 18)
            .frame(maxWidth: maksSzerokosc)
            .kreska(Kolory.karta)
            .background(KsztaltKreski().fill(Kolory.cien).offset(x: 4, y: 5))
            .padding(16)
    }
}

/// Ikona narysowana przez dziecko (strzałka, menu, album…) z danych IKONY.
struct IkonaDziecka: View {
    let id: String
    var kierunek: Kierunek?
    var kolor: Color = Kolory.napisPrzycisku

    var body: some View {
        Canvas { g, size in
            let c = Plotno(g)
            let D = RYS["IKONY"][id]
            wpisz(c, D["ramka"].liczby, size.width * 0.06, size.height * 0.06, size.width * 0.88, size.height * 0.88) { c2, s in
                piorko(c2, s, 1, 2.6)
                c2.strokeStyle = kolor
                if let kierunek {
                    let sr = D["srodek"].liczby, katy: [Kierunek: Double] = [.prawo: 0, .dol: .pi / 2, .lewo: .pi, .gora: -.pi / 2]
                    c2.translate(sr[0], sr[1]); c2.rotate((katy[kierunek] ?? 0) - D["kat"].liczba); c2.translate(-sr[0], -sr[1])
                }
                for k in D["ksztalty"].tablica { ksztalt(c2, k.punkty, nil) }
                for l in D["linie"].tablica { linia(c2, l.punkty) }
                for o in D["owale"].tablica { owal(c2, o.liczby, nil) }
            }
        }
        .accessibilityHidden(true)
    }
}
