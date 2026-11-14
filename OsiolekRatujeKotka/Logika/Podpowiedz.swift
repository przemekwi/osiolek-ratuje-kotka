import Foundation

/// Stan podpowiedzi stopniowanej (`PODP` z gry webowej).
struct StanPodp {
    var t = 0.0             // czas gry na poziomie (liczy się tylko w trakcie gry)
    var gotowa = 0.0        // chwila, od której podpowiedź jest dostępna
    var od = 0.0            // początek odliczania (do paska na przycisku)
    var stopien = 0
    var maks = 0
    var najblizej = Int.max
    var postep = 0.0        // chwila ostatniego zbliżenia do celu
    var cel = -1
    var odl: [Int] = []
    var oczekiwany = 0.0    // czas, w którym dziecko zwykle przechodzi poziom
}

/// Łapka podpowiedzi na polu i, obrócona w stronę kolejnego kroku.
struct LapkaPodp: Equatable { var i: Int; var kat: Double }

enum WynikPodp: Equatable { case zaWczesnie(Int), pokazana }

/// Podpowiedź stopniowana, przeniesiona 1:1 z gry.
/// Najpierw własna próba: podpowiedź odblokowuje się po 10 s (małe plansze) albo 15 s gry. Pokazuje tylko kawałek drogi:
/// stopień 1 — jedna łapka, 2 — do najbliższego rozwidlenia i krok za nim (najwyżej 5), 3 — do drugiego rozwidlenia
/// (najwyżej 8); nigdy do samego celu. Wyższy stopień tylko wtedy, gdy od poprzedniej dziecko nie zbliżyło się do celu.
/// Przerwa: 25 s, gdy idzie dobrze, 10 s, gdy dłużej niż zwykle; po 20 s bez postępu podpowiedź jest gotowa od razu.
extension Rozgrywka {
    func podpStart() {
        let pola = ((lab.TW - 1) / 2) * ((lab.TH - 1) / 2), droga = Double(lab.bfs(lab.domI, bezKrzaka: true)[lab.kotekI])
        podp = StanPodp()
        podp.gotowa = pola <= 12 ? 10 : 15
        podp.oczekiwany = 2.5 * droga * (1 + SCIANA) / 3.2 * (lab.trybGry == .plan ? 1 : 2)
    }

    var celPodp: Int {
        if faza == .szukaj && !lab.przeszkoda.otwarta { return lab.przeszkoda.klucz }
        return lab.trybGry == .plan || faza == .szukaj ? lab.kotekI : lab.domI
    }

    var polePodp: Int { osiol.cel >= 0 ? osiol.cel : osiol.pole }

    /// Ile sekund do podpowiedzi (0 — gotowa) i jaka część odliczania minęła (pasek na przycisku).
    var podpZostalo: Int { max(0, Int((podp.gotowa - podp.t).rounded(.up))) }
    var podpPostep: Double { max(0, min(1, (podp.t - podp.od) / max(1, podp.gotowa - podp.od))) }

    func liczPodp(_ dt: Double) {
        guard wGrze else { return }
        podp.t += dt
        if podp.cel != celPodp { podp.cel = celPodp; podp.odl = lab.bfs(podp.cel); podp.najblizej = Int.max; podp.stopien = 0 }
        let d = podp.odl[polePodp]
        if d >= 0 && d < podp.najblizej {
            if podp.najblizej != Int.max { podp.stopien = 0 }
            podp.najblizej = d; podp.postep = podp.t
        }
        if podp.t - podp.postep >= 20 && podp.gotowa > podp.t { podp.gotowa = podp.t }
    }

    /// Łapki zostają kilka sekund (5–9 s): dziecko ma zapamiętać kierunek i iść samo.
    var czasPodpowiedzi: Double { min(9, 5 + Double(droga?.count ?? 0) * 0.4) }

    @discardableResult
    func pokazDroge() -> WynikPodp? {
        guard wGrze else { return nil }
        if podp.t < podp.gotowa { return .zaWczesnie(podpZostalo) }
        let start = polePodp, d = lab.bfs(celPodp)
        var pelna = [start]
        var cur = start
        while d[cur] > 0 && pelna.count < lab.TW * lab.TH {
            let nast = lab.krokBlizej(cur, d)
            if nast == cur { break }
            cur = nast
            if lab.jestPolem(cur) { pelna.append(cur) }
        }
        let stopien = min(3, podp.stopien + 1)
        var rozwidlenia: [Int] = []
        if pelna.count > 2 { for i in 1..<(pelna.count - 1) where lab.otwarte(pelna[i]) >= 3 { rozwidlenia.append(i) } }
        var ile = stopien == 1 ? 1 : rozwidlenia.count >= stopien - 1 ? rozwidlenia[stopien - 2] + 1 : 3
        ile = max(1, min(ile, stopien == 2 ? 5 : 8, pelna.count - 2))
        var lapki: [LapkaPodp] = []
        for n in 0..<ile where n + 1 < pelna.count {
            let a = pelna[n], b = pelna[n + 1]
            lapki.append(LapkaPodp(i: b, kat: atan2(Double(lab.iy(b) - lab.iy(a)), Double(lab.ix(b) - lab.ix(a))) + .pi / 2))
        }
        droga = lapki
        drogaZostalo = czasPodpowiedzi
        podpowiedzi += 1
        podp.stopien = stopien; podp.maks = max(podp.maks, stopien)
        podp.od = podp.t; podp.postep = podp.t
        podp.gotowa = podp.t + (podp.t > podp.oczekiwany ? 10 : 25)
        return .pokazana
    }
}
