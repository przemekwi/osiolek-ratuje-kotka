import SwiftUI
import UIKit

enum Klawisz: Equatable {
    case kierunek(Kierunek)
    case pauza
}

/// Klawisze z klawiatury sprzętowej przez zdarzenia UIKit (`pressesBegan`/`pressesEnded`).
/// Zwykły widok jako pierwszy odbiorca nie przyjmuje tekstu, więc iOS nie pokazuje klawiatury ekranowej
/// (SwiftUI `.focusable` + `.onKeyPress` ją pokazywał).
struct KlawiaturaSprzetowa: UIViewRepresentable {
    let naKlawisz: (Klawisz, Bool) -> Void

    func makeUIView(context: Context) -> Odbiornik {
        let v = Odbiornik()
        v.naKlawisz = naKlawisz
        return v
    }

    func updateUIView(_ v: Odbiornik, context: Context) {
        v.naKlawisz = naKlawisz
        if v.window != nil && !v.isFirstResponder { v.becomeFirstResponder() }
    }

    final class Odbiornik: UIView {
        var naKlawisz: ((Klawisz, Bool) -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { becomeFirstResponder() }
        }

        private func klawisz(_ p: UIPress) -> Klawisz? {
            guard let k = p.key else { return nil }
            switch k.keyCode {
            case .keyboardRightArrow, .keyboardD: return .kierunek(.prawo)
            case .keyboardLeftArrow, .keyboardA: return .kierunek(.lewo)
            case .keyboardDownArrow, .keyboardS: return .kierunek(.dol)
            case .keyboardUpArrow, .keyboardW: return .kierunek(.gora)
            case .keyboardEscape, .keyboardP: return .pauza
            default: return nil
            }
        }

        private func obsluz(_ presses: Set<UIPress>, wcisniety: Bool) -> Bool {
            var obsluzone = false
            for p in presses {
                if let k = klawisz(p) { naKlawisz?(k, wcisniety); obsluzone = true }
            }
            return obsluzone
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if !obsluz(presses, wcisniety: true) { super.pressesBegan(presses, with: event) }
        }
        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if !obsluz(presses, wcisniety: false) { super.pressesEnded(presses, with: event) }
        }
        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            if !obsluz(presses, wcisniety: false) { super.pressesCancelled(presses, with: event) }
        }
    }
}
