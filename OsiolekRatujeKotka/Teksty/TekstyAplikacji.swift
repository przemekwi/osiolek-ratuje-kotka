import Foundation

/// Teksty elementów, których gra webowa nie ma (limit dzienny, ustawienia dla rodzica, bramka z działaniem).
/// Polski jest źródłowy; pozostałe języki to tłumaczenia w słownictwie gry (osiołek, kotek, przerwa).
enum TekstyAplikacji {
    static let teksty: [String: [String: String]] = [
        "rodzicDzialanie": [
            "pl": "Dla rodzica: wpisz cyframi wynik działania zapisanego słowami.",
            "en": "For parents: type the answer to this sum in digits.",
            "fr": "Pour les parents : écrivez en chiffres le résultat de cette addition.",
            "es": "Para padres y madres: escribe en cifras el resultado de esta suma.",
            "de": "Für Eltern: Gib das Ergebnis dieser in Worten geschriebenen Rechnung als Ziffern ein.",
            "it": "Per i genitori: scrivi in cifre il risultato di questa somma scritta in lettere.",
            "zh-Hans": "给家长：请用阿拉伯数字输入这道用汉字写的加法的答案。",
            "zh-Hant": "給家長：請用阿拉伯數字輸入這道用國字寫的加法的答案。",
        ],
        "rodzicMnozenie": [
            "pl": "Dla rodzica: wybierz wynik mnożenia.",
            "en": "For parents: choose the answer to this multiplication.",
            "fr": "Pour les parents : choisissez le résultat de la multiplication.",
            "es": "Para padres y madres: elige el resultado de la multiplicación.",
            "de": "Für Eltern: Wählen Sie das Ergebnis der Multiplikation.",
            "it": "Per i genitori: scegli il risultato della moltiplicazione.",
            "zh-Hans": "给家长：请选出乘法的答案。",
            "zh-Hant": "給家長：請選出乘法的答案。",
        ],
        "ileTo": [
            "pl": "Ile to: {s}?", "en": "What is {s}?", "fr": "Combien font {s} ?", "es": "¿Cuánto es {s}?",
            "de": "Wie viel ist {s}?", "it": "Quanto fa {s}?", "zh-Hans": "{s}等于多少？", "zh-Hant": "{s}等於多少？",
        ],
        "plus": ["pl": "plus", "en": "plus", "fr": "plus", "es": "más", "de": "plus", "it": "più", "zh-Hans": "加", "zh-Hant": "加"],
        "ostrzezenie": [
            "pl": "Jeszcze chwilka, potem przerwa.",
            "en": "Just a little longer, then a break.",
            "fr": "Encore un petit moment, puis une pause.",
            "es": "Un ratito más y luego a descansar.",
            "de": "Noch ein kleines bisschen, dann Pause.",
            "it": "Ancora un pochino, poi pausa.",
            "zh-Hans": "再玩一小会儿，然后休息。",
            "zh-Hant": "再玩一小會兒，然後休息。",
        ],
        "dzienH": [
            "pl": "Na dziś koniec grania", "en": "No more playing today", "fr": "Fini de jouer pour aujourd’hui",
            "es": "Por hoy se acabó el juego", "de": "Für heute ist Schluss", "it": "Per oggi basta giocare",
            "zh-Hans": "今天就玩到这里", "zh-Hant": "今天就玩到這裡",
        ],
        "dzienTekst": [
            "pl": "Osiołek i kotek idą spać. Zagramy jutro!",
            "en": "The donkey and the kitten are going to sleep. Let’s play tomorrow!",
            "fr": "L’âne et le chaton vont dormir. On rejoue demain !",
            "es": "El burrito y el gatito se van a dormir. ¡Jugamos mañana!",
            "de": "Der Esel und das Kätzchen gehen schlafen. Morgen spielen wir weiter!",
            "it": "L’asinello e il gattino vanno a dormire. Giochiamo domani!",
            "zh-Hans": "小驴子和小猫要去睡觉了。明天再玩吧！",
            "zh-Hant": "小驢子和小貓要去睡覺了。明天再玩吧！",
        ],
        "dzienRodzic": [
            "pl": "Rodzic może zmienić limit dzienny w ustawieniach.",
            "en": "A parent can change the daily limit in the settings.",
            "fr": "Un parent peut modifier la limite quotidienne dans les réglages.",
            "es": "Un adulto puede cambiar el límite diario en los ajustes.",
            "de": "Eltern können das Tageslimit in den Einstellungen ändern.",
            "it": "Un genitore può cambiare il limite giornaliero nelle impostazioni.",
            "zh-Hans": "家长可以在设置中修改每日时长。",
            "zh-Hant": "家長可以在設定中修改每日時長。",
        ],
        "dlaRodzica": [
            "pl": "Dla rodzica", "en": "For parents", "fr": "Pour les parents", "es": "Para padres y madres",
            "de": "Für Eltern", "it": "Per i genitori", "zh-Hans": "给家长", "zh-Hant": "給家長",
        ],
        "ustawieniaH": [
            "pl": "Ustawienia dla rodzica", "en": "Settings for parents", "fr": "Réglages pour les parents",
            "es": "Ajustes para padres y madres", "de": "Einstellungen für Eltern", "it": "Impostazioni per i genitori",
            "zh-Hans": "家长设置", "zh-Hant": "家長設定",
        ],
        "limitSesji": [
            "pl": "Jedna sesja gry", "en": "One play session", "fr": "Une session de jeu", "es": "Una sesión de juego",
            "de": "Eine Spielrunde", "it": "Una sessione di gioco", "zh-Hans": "每次游戏", "zh-Hant": "每次遊戲",
        ],
        "limitDnia": [
            "pl": "Cały dzień", "en": "Whole day", "fr": "Toute la journée", "es": "Todo el día",
            "de": "Ganzer Tag", "it": "Tutto il giorno", "zh-Hans": "每天", "zh-Hant": "每天",
        ],
        "minut": [
            "pl": "{m} min", "en": "{m} min", "fr": "{m} min", "es": "{m} min",
            "de": "{m} Min.", "it": "{m} min", "zh-Hans": "{m}分钟", "zh-Hant": "{m}分鐘",
        ],
        "dzisGra": [
            "pl": "Dziś gra trwała {m} min z {d} min.",
            "en": "Played today: {m} min of {d} min.",
            "fr": "Aujourd’hui : {m} min sur {d} min.",
            "es": "Hoy: {m} min de {d} min.",
            "de": "Heute gespielt: {m} von {d} Min.",
            "it": "Oggi: {m} min su {d} min.",
            "zh-Hans": "今天已玩{m}分钟，共{d}分钟。",
            "zh-Hant": "今天已玩{m}分鐘，共{d}分鐘。",
        ],
        "przerwaPoSesji": [
            "pl": "Po każdej sesji przerwa co najmniej 30 minut. Limitu dziennego nie da się ustawić powyżej 60 minut.",
            "en": "After each session there is a break of at least 30 minutes. The daily limit cannot be set above 60 minutes.",
            "fr": "Après chaque session, une pause d’au moins 30 minutes. La limite quotidienne ne peut pas dépasser 60 minutes.",
            "es": "Después de cada sesión hay un descanso de al menos 30 minutos. El límite diario no puede superar los 60 minutos.",
            "de": "Nach jeder Runde gibt es mindestens 30 Minuten Pause. Das Tageslimit kann höchstens 60 Minuten betragen.",
            "it": "Dopo ogni sessione c’è una pausa di almeno 30 minuti. Il limite giornaliero non può superare i 60 minuti.",
            "zh-Hans": "每次游戏后至少休息30分钟。每日时长最多60分钟。",
            "zh-Hant": "每次遊戲後至少休息30分鐘。每日時長最多60分鐘。",
        ],
        "systemInfo": [
            "pl": "Całe urządzenie ograniczysz w Ustawieniach iPhone’a lub iPada: Czas przed ekranem oraz Dostęp z przewodnikiem (w sekcji Dostępność).",
            "en": "To limit the whole device, use Screen Time and Guided Access (in Accessibility) in the iPhone or iPad Settings.",
            "fr": "Pour limiter tout l’appareil, utilisez Temps d’écran et Accès guidé (dans Accessibilité) dans les Réglages de l’iPhone ou de l’iPad.",
            "es": "Para limitar todo el dispositivo, usa Tiempo de uso y Acceso guiado (en Accesibilidad) en los Ajustes del iPhone o iPad.",
            "de": "Das ganze Gerät begrenzen Sie in den Einstellungen des iPhone oder iPad mit Bildschirmzeit und Geführter Zugriff (unter Bedienungshilfen).",
            "it": "Per limitare tutto il dispositivo usa Tempo di utilizzo e Accesso Guidato (in Accessibilità) nelle Impostazioni di iPhone o iPad.",
            "zh-Hans": "要限制整台设备，请在 iPhone 或 iPad 的“设置”中使用“屏幕使用时间”和“引导式访问”（在“辅助功能”中）。",
            "zh-Hant": "要限制整台裝置，請在 iPhone 或 iPad 的「設定」中使用「螢幕使用時間」和「引導使用模式」（在「輔助使用」中）。",
        ],
        "przerwaMinela": [
            "pl": "Przerwa minęła. Można grać dalej!", "en": "The break is over. You can play again!",
            "fr": "La pause est finie. On peut rejouer !", "es": "El descanso ha terminado. ¡Se puede volver a jugar!",
            "de": "Die Pause ist vorbei. Es darf weitergespielt werden!", "it": "La pausa è finita. Si può giocare di nuovo!",
            "zh-Hans": "休息结束了，可以继续玩了！", "zh-Hant": "休息結束了，可以繼續玩了！",
        ],
        "przedluzZasady": [
            "pl": "Każde kolejne przedłużenie jest krótsze, najwyżej dwa dziennie.",
            "en": "Each extension is shorter than the last, at most two a day.",
            "fr": "Chaque prolongation est plus courte que la précédente, deux par jour au maximum.",
            "es": "Cada prórroga es más corta que la anterior, como máximo dos al día.",
            "de": "Jede Verlängerung ist kürzer als die vorige, höchstens zwei am Tag.",
            "it": "Ogni prolungamento è più breve del precedente, al massimo due al giorno.",
            "zh-Hans": "每次延长都比上一次短，每天最多两次。",
            "zh-Hant": "每次延長都比上一次短，每天最多兩次。",
        ],
        "przedluzBrak": [
            "pl": "Przedłużenia na dziś zostały wykorzystane.", "en": "No more extensions today.",
            "fr": "Plus de prolongations aujourd’hui.", "es": "Hoy ya no quedan prórrogas.",
            "de": "Für heute gibt es keine Verlängerung mehr.", "it": "Per oggi non ci sono altri prolungamenti.",
            "zh-Hans": "今天的延长次数已用完。", "zh-Hant": "今天的延長次數已用完。",
        ],
        "ukryjStrzalki": [
            "pl": "Ukryj strzałki", "en": "Hide arrows", "fr": "Masquer les flèches", "es": "Ocultar las flechas",
            "de": "Pfeile ausblenden", "it": "Nascondi le frecce", "zh-Hans": "隐藏方向键", "zh-Hant": "隱藏方向鍵",
        ],
        "pokazStrzalki": [
            "pl": "Pokaż strzałki", "en": "Show arrows", "fr": "Afficher les flèches", "es": "Mostrar las flechas",
            "de": "Pfeile einblenden", "it": "Mostra le frecce", "zh-Hans": "显示方向键", "zh-Hant": "顯示方向鍵",
        ],
        "ustawienia": [
            "pl": "Ustawienia", "en": "Settings", "fr": "Réglages", "es": "Ajustes",
            "de": "Einstellungen", "it": "Impostazioni", "zh-Hans": "设置", "zh-Hant": "設定",
        ],
    ]

    static func tekst(_ jezyk: String, _ klucz: String) -> String? {
        guard let t = teksty[klucz] else { return nil }
        return t[jezyk] ?? t["pl"]
    }
}
