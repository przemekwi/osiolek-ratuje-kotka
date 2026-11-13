import SwiftUI

/// Osiołek ratuje kotka w labiryncie — natywna wersja gry z gry.wilde.pl. Działa w pełni offline:
/// bez sieci, reklam, analityki i logowania.
@main
struct OsiolekApp: App {
    @State private var stan = StanGry()
    @Environment(\.scenePhase) private var faza

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch stan.ekran {
                case .start: StartView()
                case .szafa: SzafaView()
                case .gra: GraView()
                }
                // Przerwa zasłania wszystko, dopóki rodzic nie odblokuje gry.
                if stan.przerwaTrwa { PrzerwaView() }
            }
            .environment(stan)
            .preferredColorScheme(stan.schematKolorow)
            .environment(\.locale, Locale(identifier: stan.jezyk))
            .persistentSystemOverlays(.hidden)
            .statusBarHidden(stan.ekran == .gra)
            .onChange(of: faza) { _, f in
                // Po zejściu do tła gra staje (nic nie dzieje się za plecami dziecka).
                if f != .active && stan.ekran == .gra && stan.nakladka == nil { stan.pauza(cicho: true) }
                if f == .active { if !stan.przerwaTrwa { Syntezator.wspolny.wznow() } } else if f == .background { Syntezator.wspolny.wstrzymaj() }
                // Zapis przy każdym zejściu z ekranu: po powrocie dziecko jest w tym samym miejscu labiryntu.
                if f != .active { stan.zapisz() }
            }
        }
    }
}
