import AVFoundation

/// Dźwięk i muzyka syntezowane na bieżąco, bez plików — jak Web Audio w grze webowej (`ton`, `sfx`, `MUZ`).
/// Tony to proste fale (sinus, trójkąt) z obwiednią: narastanie 15 ms, potem wykładnicze wygaszanie.
final class Syntezator {
    static let wspolny = Syntezator()

    private struct Ton {
        var f: Double
        var start: Int64      // numer próbki początku
        var dl: Double        // czas trwania (s)
        var glos: Double
        var trojkat: Bool
        var muzyka: Bool
        var faza = 0.0
    }

    private let silnik = AVAudioEngine()
    private var zrodlo: AVAudioSourceNode?
    private let zamek = NSLock()
    private var tony: [Ton] = []
    private var probka: Int64 = 0
    private var fs = 44_100.0
    // Dwa filtry dolnoprzepustowe po kolei (ok. 1800 Hz) łagodzą wysokie tony muzyki, żeby nie przebodźcowywała.
    private var filtr1 = 0.0, filtr2 = 0.0
    private var uruchomiony = false
    private var zegarMuzyki: Timer?

    var dzwieki = true
    var muzyka = true { didSet { if !muzyka { zamek.lock(); tony.removeAll { $0.muzyka }; zamek.unlock() } } }
    /// W trybie dla dziecka muzyka gra o połowę ciszej.
    var glosMuzyki = 0.5
    private var kroki = 0

    private init() {}

    private func uruchom() -> Bool {
        if uruchomiony { if !silnik.isRunning { try? silnik.start() }; return silnik.isRunning }
        // „Playback”, jak w grze: przełącznik wyciszenia w iPhonie nie wycisza gry.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        fs = silnik.outputNode.outputFormat(forBus: 0).sampleRate
        if fs <= 0 { fs = 44_100 }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: fs, channels: 1) else { return false }
        let wezel = AVAudioSourceNode(format: format) { [unowned self] _, _, ileKlatek, lista -> OSStatus in
            self.renderuj(Int(ileKlatek), UnsafeMutableAudioBufferListPointer(lista))
            return noErr
        }
        silnik.attach(wezel)
        silnik.connect(wezel, to: silnik.mainMixerNode, format: format)
        zrodlo = wezel
        do { try silnik.start() } catch { return false }
        uruchomiony = true
        return true
    }

    func wstrzymaj() { if uruchomiony { silnik.pause() } }
    func wznow() { if uruchomiony { try? silnik.start() } }

    private func renderuj(_ n: Int, _ bufory: UnsafeMutableAudioBufferListPointer) {
        zamek.lock()
        defer { zamek.unlock() }
        let a = 1 - exp(-2 * Double.pi * 1800 / fs)
        let gm = muzyka ? glosMuzyki : 0
        guard let dane = bufory.first?.mData?.assumingMemoryBound(to: Float.self) else { probka += Int64(n); return }
        for k in 0..<n {
            let t = probka + Int64(k)
            var efekty = 0.0, muz = 0.0
            for j in tony.indices {
                let ton = tony[j]
                let tau = Double(t - ton.start) / fs
                if tau < 0 || tau > ton.dl + 0.05 { continue }
                let obw: Double
                if tau < 0.015 { obw = ton.glos * tau / 0.015 }
                else if tau < ton.dl { obw = ton.glos * pow(0.0008 / ton.glos, (tau - 0.015) / max(0.001, ton.dl - 0.015)) }
                else { obw = 0.0008 }
                let ph = tony[j].faza
                let fala = ton.trojkat ? (ph < 0.5 ? 4 * ph - 1 : 3 - 4 * ph) : sin(2 * Double.pi * ph)
                var nph = ph + ton.f / fs
                if nph >= 1 { nph -= 1 }
                tony[j].faza = nph
                if ton.muzyka { muz += fala * obw } else { efekty += fala * obw }
            }
            filtr1 += a * (muz - filtr1)
            filtr2 += a * (filtr1 - filtr2)
            dane[k] = Float((dzwieki ? efekty : 0) + filtr2 * gm)
        }
        probka += Int64(n)
        tony.removeAll { Double(probka - $0.start) / fs > $0.dl + 0.05 }
        for b in bufory.dropFirst() { b.mData?.copyMemory(from: dane, byteCount: Int(b.mDataByteSize)) }
    }

    private var teraz: Double { zamek.lock(); defer { zamek.unlock() }; return Double(probka) / fs }

    private func dodaj(_ f: Double, _ t0: Double, _ dl: Double, trojkat: Bool, glos: Double, muzyka: Bool) {
        zamek.lock()
        tony.append(Ton(f: f, start: Int64(t0 * fs), dl: dl, glos: glos, trojkat: trojkat, muzyka: muzyka))
        zamek.unlock()
    }

    /// Nuty [(częstotliwość, przesunięcie s, długość s)], jak `dzwiek(nuty,typ,glosnosc)`.
    private func dzwiek(_ nuty: [(Double, Double, Double)], trojkat: Bool, glos: Double) {
        guard dzwieki, uruchom() else { return }
        let t0 = teraz + 0.03
        for (f, s, dl) in nuty { dodaj(f, t0 + s, dl, trojkat: trojkat, glos: glos, muzyka: false) }
    }

    // MARK: Efekty (`sfx` z gry)
    func krok() { dzwiek([(520 + Double(Int.random(in: 0..<60)), 0, 0.07)], trojkat: true, glos: 0.03) }
    /// Przy chodzeniu co drugi krok, żeby długie błądzenie nie było ciągiem identycznych kliknięć.
    func krokRuchu() { if kroki % 2 == 0 { krok() }; kroki += 1 }
    func bum() { dzwiek([(330, 0, 0.12), (262, 0.08, 0.14)], trojkat: false, glos: 0.07) }
    func klik() { dzwiek([(700, 0, 0.06)], trojkat: false, glos: 0.08) }
    func miau() { dzwiek([(659, 0, 0.12), (880, 0.1, 0.14), (587, 0.22, 0.3)], trojkat: false, glos: 0.08) }
    /// Kotek się cieszy: miauknięcie i krótka wznosząca melodyjka (cicho, bez nagłych głośnych dźwięków).
    func radosc() {
        miau()
        dzwiek([(523, 0.42, 0.12), (587, 0.56, 0.12), (659, 0.7, 0.14), (784, 0.86, 0.12), (880, 1.0, 0.3)], trojkat: true, glos: 0.06)
    }
    func serce() { dzwiek([(784, 0, 0.1), (988, 0.08, 0.2)], trojkat: true, glos: 0.07) }
    func brawo() { dzwiek([(392, 0, 0.18), (523, 0.14, 0.18), (659, 0.28, 0.18), (784, 0.42, 0.5)], trojkat: true, glos: 0.08) }

    // MARK: Muzyka (`MUZ` z gry)
    // Na każdy poziom nowa melodia z pentatoniki durowej nad jednym z czterech ciągów akordów, w losowej tonacji
    // i spokojnym tempie (80–96). Melodia gra 8 taktów, potem 8 taktów ciszy.
    private var melodia: [Int] = []
    private var bas: [Int] = []
    private var krokMuz = 0
    private var nastepna = 0.0
    private var tonacja = 0
    private var osemka = 60.0 / 88 / 2

    private func nuta(_ m: Int) -> Double { 440 * pow(2, Double(m + tonacja - 69) / 12) }

    func nowaMelodia() {
        let I = [60, 64, 67], IV = [65, 69, 72], V = [67, 71, 74], VI = [69, 72, 76]
        let CIAGI = [[I, V, VI, IV], [I, IV, V, I], [I, VI, IV, V], [I, IV, VI, V]]
        let akordy = CIAGI.randomElement()!, SKALA = [60, 62, 64, 67, 69, 72, 74, 76, 79]
        tonacja = [-3, 0, 2, 5].randomElement()!
        osemka = 60 / Double(80 + Int.random(in: 0..<17)) / 2
        var mel: [Int] = []
        var poz = 4
        for takt in 0..<8 {
            let ak = akordy[takt % 4]
            for k in 0..<8 {
                if k % 4 == 0 {
                    let cel = ak.map { $0 + ($0 < 64 ? 12 : 0) }.randomElement()!
                    poz = SKALA.indices.reduce(0) { abs(SKALA[$1] - cel) < abs(SKALA[$0] - cel) ? $1 : $0 }
                    mel.append(SKALA[poz]); continue
                }
                if Double.random(in: 0..<1) < 0.3 { mel.append(0); continue }
                poz = max(0, min(SKALA.count - 1, poz + [-2, -1, -1, 1, 1, 2].randomElement()!))
                mel.append(SKALA[poz])
            }
        }
        mel[mel.count - 1] = 0; mel[mel.count - 2] = 72
        melodia = mel; bas = akordy.map { $0[0] - 24 }; krokMuz = 0
    }

    func wlaczMuzyke() {
        guard muzyka, uruchom() else { return }
        if melodia.isEmpty { nowaMelodia() }
        if zegarMuzyki == nil {
            // Planowanie z wyprzedzeniem: rytm nie zależy od klatek ani od opóźnień zegara.
            zegarMuzyki = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.planujMuzyke() }
        }
    }

    private func planujMuzyke() {
        guard muzyka, uruchomiony, silnik.isRunning, !melodia.isEmpty else { return }
        let t = teraz
        if nastepna < t { nastepna = t + 0.05 }
        while nastepna < t + 0.35 {
            let k = krokMuz % melodia.count, n = melodia[k], cisza = (krokMuz / melodia.count) % 2 == 1
            if n != 0 && !cisza { dodaj(nuta(n - 12), nastepna, osemka * 1.6, trojkat: true, glos: 0.045, muzyka: true) }
            if k % 4 == 0 && !cisza {
                dodaj(nuta(bas[(k / 8) % 4] + (k % 8 != 0 ? 7 : 0)), nastepna, osemka * 3.5, trojkat: false, glos: 0.06, muzyka: true)
            }
            nastepna += osemka; krokMuz += 1
        }
    }
}
