import SwiftUI

/// Osiołek ratuje kotka w labiryncie — natywna wersja gry z gry.wilde.pl. Działa w pełni offline:
/// bez sieci, reklam, analityki i logowania.
@main
struct OsiolekApp: App {
    @State private var stan = StanGry()
    @Environment(\.scenePhase) private var faza

    var body: some Scene {
        WindowGroup {
            Group {
                switch stan.ekran {
                case .start, .szafa: StartView()
                case .gra: GraView()
                }
            }
            .environment(stan)
            .preferredColorScheme(stan.schematKolorow)
            .environment(\.locale, Locale(identifier: stan.jezyk))
            .persistentSystemOverlays(.hidden)
            .statusBarHidden(stan.ekran == .gra)
            .onChange(of: faza) { _, f in
                // Po zejściu do tła gra staje (nic nie dzieje się za plecami dziecka).
                if f != .active && stan.ekran == .gra && stan.nakladka == nil { stan.pauza() }
            }
        }
    }
}
