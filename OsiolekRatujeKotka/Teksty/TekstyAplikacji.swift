import Foundation

/// Teksty elementów, których gra webowa nie ma (limit dzienny, ustawienia dla rodzica, bramka z działaniem).
/// Polski jest źródłowy; pozostałe języki to tłumaczenia w słownictwie gry (osiołek, kotek, przerwa).
enum TekstyAplikacji {
    static let teksty: [String: [String: String]] = [
        "rodzicMnozenie": [
            "pl": "Dla rodzica: wpisz wynik mnożenia.",
            "en": "For parents: type the answer to this multiplication.",
            "fr": "Pour les parents : saisissez le résultat de la multiplication.",
            "es": "Para padres y madres: escribe el resultado de la multiplicación.",
            "de": "Für Eltern: Geben Sie das Ergebnis der Multiplikation ein.",
            "it": "Per i genitori: scrivi il risultato della moltiplicazione.",
            "zh-Hans": "给家长：请输入乘法的答案。",
            "zh-Hant": "給家長：請輸入乘法的答案。",
        ],
        "cofnijCyfre": [
            "pl": "Usuń cyfrę", "en": "Delete digit", "fr": "Effacer le chiffre", "es": "Borrar cifra",
            "de": "Ziffer löschen", "it": "Cancella cifra", "zh-Hans": "删除数字", "zh-Hant": "刪除數字",
        ],
        "ileTo": [
            "pl": "Ile to: {s}?", "en": "What is {s}?", "fr": "Combien font {s} ?", "es": "¿Cuánto es {s}?",
            "de": "Wie viel ist {s}?", "it": "Quanto fa {s}?", "zh-Hans": "{s}等于多少？", "zh-Hant": "{s}等於多少？",
        ],
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
            "pl": "Czas na całym urządzeniu ograniczysz w Ustawieniach: Czas przed ekranem.",
            "en": "To limit time on the whole device, use Settings: Screen Time.",
            "fr": "Pour limiter le temps sur tout l’appareil, utilisez Réglages : Temps d’écran.",
            "es": "Para limitar el tiempo en todo el dispositivo, usa Ajustes: Tiempo de uso.",
            "de": "Die Zeit am ganzen Gerät begrenzen Sie unter Einstellungen: Bildschirmzeit.",
            "it": "Per limitare il tempo su tutto il dispositivo usa Impostazioni: Tempo di utilizzo.",
            "zh-Hans": "要限制整台设备的使用时间，请使用“设置”中的“屏幕使用时间”。",
            "zh-Hant": "要限制整台裝置的使用時間，請使用「設定」中的「螢幕使用時間」。",
        ],
        "przewodnikH": [
            "pl": "Dziecko nie wyjdzie z gry", "en": "Keep your child in the game", "fr": "L’enfant reste dans le jeu",
            "es": "Que el niño no salga del juego", "de": "Das Kind bleibt im Spiel", "it": "Il bambino resta nel gioco",
            "zh-Hans": "让孩子留在游戏里", "zh-Hant": "讓孩子留在遊戲裡",
        ],
        "przewodnikKroki": [
            "pl": "Włącz Dostęp z przewodnikiem: Ustawienia → Dostępność → Dostęp z przewodnikiem. Potem w grze naciśnij trzy razy boczny przycisk (albo przycisk Home) i stuknij „Start”. Tak samo zakończysz go kodem.",
            "en": "Turn on Guided Access: Settings → Accessibility → Guided Access. Then, in the game, press the side button (or the Home button) three times and tap “Start”. End it the same way with your passcode.",
            "fr": "Activez Accès guidé : Réglages → Accessibilité → Accès guidé. Puis, dans le jeu, appuyez trois fois sur le bouton latéral (ou le bouton principal) et touchez « Démarrer ». Terminez-le de la même façon avec votre code.",
            "es": "Activa Acceso guiado: Ajustes → Accesibilidad → Acceso guiado. Luego, en el juego, pulsa tres veces el botón lateral (o el botón de inicio) y toca «Iniciar». Termínalo igual, con tu código.",
            "de": "Aktivieren Sie Geführter Zugriff: Einstellungen → Bedienungshilfen → Geführter Zugriff. Drücken Sie dann im Spiel dreimal die Seitentaste (oder die Home-Taste) und tippen Sie auf „Starten“. Beenden ebenso, mit Ihrem Code.",
            "it": "Attiva Accesso Guidato: Impostazioni → Accessibilità → Accesso Guidato. Poi nel gioco premi tre volte il tasto laterale (o il tasto Home) e tocca «Avvia». Si termina allo stesso modo, con il codice.",
            "zh-Hans": "打开“引导式访问”：设置 → 辅助功能 → 引导式访问。然后在游戏中连按三次侧边按钮（或主屏幕按钮），轻点“开始”。用同样方式输入密码即可结束。",
            "zh-Hant": "打開「引導使用模式」：設定 → 輔助使用 → 引導使用模式。然後在遊戲中連按三次側邊按鈕（或主畫面按鈕），點一下「開始」。用同樣方式輸入密碼即可結束。",
        ],
        "wibracjeWl": [
            "pl": "Wibracje: włączone", "en": "Vibration: on", "fr": "Vibrations : activées", "es": "Vibración: activada",
            "de": "Vibration: an", "it": "Vibrazione: attiva", "zh-Hans": "振动：开", "zh-Hant": "震動：開",
        ],
        "wibracjeWyl": [
            "pl": "Wibracje: wyłączone", "en": "Vibration: off", "fr": "Vibrations : désactivées", "es": "Vibración: desactivada",
            "de": "Vibration: aus", "it": "Vibrazione: disattiva", "zh-Hans": "振动：关", "zh-Hant": "震動：關",
        ],
        "rysunkiWsk": [
            "pl": "Stuknij rysunek: najpierw kartka, potem rysunek z gry rysuje się na nowo.",
            "en": "Tap a drawing: first the paper original, then the game drawing draws itself again.",
            "fr": "Touchez un dessin : d’abord l’original sur papier, puis le dessin du jeu se redessine.",
            "es": "Toca un dibujo: primero el original en papel y luego el dibujo del juego se vuelve a dibujar.",
            "de": "Tippe auf eine Zeichnung: zuerst das Original auf Papier, dann zeichnet sich das Spielbild neu.",
            "it": "Tocca un disegno: prima l’originale su carta, poi il disegno del gioco si ridisegna.",
            "zh-Hans": "点一下画：先看纸上的原画，再看游戏里的画重新画出来。",
            "zh-Hant": "點一下畫：先看紙上的原畫，再看遊戲裡的畫重新畫出來。",
        ],
        "autorzyGry": [
            "pl": "Przemysław Wilde i Córcia", "en": "Przemysław Wilde and his daughter", "fr": "Przemysław Wilde et sa fille",
            "es": "Przemysław Wilde y su hija", "de": "Przemysław Wilde und seine Tochter", "it": "Przemysław Wilde e sua figlia",
            "zh-Hans": "Przemysław Wilde 和女儿", "zh-Hant": "Przemysław Wilde 和女兒",
        ],
        "oOpis": [
            "pl": "To gra stworzona przez Ojca i córkę. Gra w pełni narysowana i zaprojektowana z dzieckiem i opowiadająca historię osiołka, który musi uratować kotka, pomagając znaleźć mu drogę do domku.",
            "en": "This game was made by a father and his daughter. It was fully drawn and designed together with the child, and it tells the story of a donkey who has to rescue a kitten by helping it find the way home.",
            "fr": "Ce jeu a été créé par un père et sa fille. Entièrement dessiné et conçu avec l’enfant, il raconte l’histoire d’un âne qui doit sauver un chaton en l’aidant à retrouver le chemin de la maison.",
            "es": "Este juego lo han creado un padre y su hija. Está dibujado y diseñado por completo con la niña y cuenta la historia de un burrito que debe rescatar a un gatito ayudándole a encontrar el camino a casa.",
            "de": "Dieses Spiel haben ein Vater und seine Tochter gemacht. Es wurde ganz mit dem Kind gezeichnet und gestaltet und erzählt von einem Esel, der ein Kätzchen retten muss, indem er ihm den Weg nach Hause zeigt.",
            "it": "Questo gioco è stato creato da un papà e sua figlia. È stato interamente disegnato e progettato con la bambina e racconta la storia di un asinello che deve salvare un gattino aiutandolo a trovare la strada di casa.",
            "zh-Hans": "这是一款由爸爸和女儿一起做的游戏。游戏完全由孩子参与绘画和设计，讲述了一只小驴子帮助小猫找到回家的路、把它救出来的故事。",
            "zh-Hant": "這是一款由爸爸和女兒一起做的遊戲。遊戲完全由孩子參與繪畫和設計，講述了一隻小驢子幫助小貓找到回家的路、把牠救出來的故事。",
        ],
        "stworzonePrzez": [
            "pl": "Stworzone przez:", "en": "Made by:", "fr": "Créé par :", "es": "Creado por:", "de": "Gemacht von:",
            "it": "Creato da:", "zh-Hans": "制作：", "zh-Hant": "製作：",
        ],
        "historiaGry": [
            "pl": "Historia gry:", "en": "The story of the game:", "fr": "L’histoire du jeu :", "es": "La historia del juego:",
            "de": "Die Geschichte des Spiels:", "it": "La storia del gioco:", "zh-Hans": "游戏的故事：", "zh-Hant": "遊戲的故事：",
        ],
        "przeczytajHistorie": [
            "pl": "Przeczytaj na blogu", "en": "Read on the blog", "fr": "Lire sur le blog", "es": "Leer en el blog",
            "de": "Im Blog lesen", "it": "Leggi sul blog", "zh-Hans": "在博客阅读", "zh-Hant": "在部落格閱讀",
        ],
        "inneGry": [
            "pl": "Inne gry:", "en": "Other games:", "fr": "Autres jeux :", "es": "Otros juegos:", "de": "Andere Spiele:",
            "it": "Altri giochi:", "zh-Hans": "其他游戏：", "zh-Hant": "其他遊戲：",
        ],
        "rysujPonownie": [
            "pl": "Stuknij, żeby narysować jeszcze raz.", "en": "Tap to draw it again.", "fr": "Touchez pour redessiner.",
            "es": "Toca para dibujarlo otra vez.", "de": "Tippe, um es noch einmal zu zeichnen.", "it": "Tocca per disegnarlo ancora.",
            "zh-Hans": "点一下再画一次。", "zh-Hant": "點一下再畫一次。",
        ],
        "dzwiekWl": [
            "pl": "Dźwięk: włączony", "en": "Sound: on", "fr": "Son : activé", "es": "Sonido: activado",
            "de": "Ton: an", "it": "Suono: attivo", "zh-Hans": "声音：开", "zh-Hant": "聲音：開",
        ],
        "dzwiekWyl": [
            "pl": "Dźwięk: wyłączony", "en": "Sound: off", "fr": "Son : désactivé", "es": "Sonido: desactivado",
            "de": "Ton: aus", "it": "Suono: disattivo", "zh-Hans": "声音：关", "zh-Hant": "聲音：關",
        ],
        "ustawieniaGry": [
            "pl": "Ustawienia gry", "en": "Game settings", "fr": "Réglages du jeu", "es": "Ajustes del juego",
            "de": "Spieleinstellungen", "it": "Impostazioni del gioco", "zh-Hans": "游戏设置", "zh-Hant": "遊戲設定",
        ],
        "nowaGraPotwierdz": [
            "pl": "Nowa gra zaczyna od poziomu 1 i usuwa album naklejek. Na pewno?",
            "en": "A new game starts from level 1 and clears the sticker album. Are you sure?",
            "fr": "Une nouvelle partie recommence au niveau 1 et vide l’album d’autocollants. Vous êtes sûr ?",
            "es": "Una partida nueva empieza en el nivel 1 y borra el álbum de pegatinas. ¿Seguro?",
            "de": "Ein neues Spiel beginnt bei Level 1 und leert das Stickeralbum. Sicher?",
            "it": "Una nuova partita ricomincia dal livello 1 e svuota l’album di adesivi. Sicuro?",
            "zh-Hans": "新游戏会从第1关开始，并清空贴纸相册。确定吗？",
            "zh-Hant": "新遊戲會從第1關開始，並清空貼紙相簿。確定嗎？",
        ],
        "nowaGraTak": [
            "pl": "Tak, nowa gra", "en": "Yes, new game", "fr": "Oui, nouvelle partie", "es": "Sí, partida nueva",
            "de": "Ja, neues Spiel", "it": "Sì, nuova partita", "zh-Hans": "是的，新游戏", "zh-Hant": "是的，新遊戲",
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
        "autorH": [
            "pl": "Autor", "en": "Author", "fr": "Auteur", "es": "Autor", "de": "Autor", "it": "Autore",
            "zh-Hans": "作者", "zh-Hant": "作者",
        ],
        "linkRodzic": [
            "pl": "Linki otwierają przeglądarkę. Najpierw zadanie dla rodzica.",
            "en": "The links open the web browser. First, a question for parents.",
            "fr": "Les liens ouvrent le navigateur. D’abord une question pour les parents.",
            "es": "Los enlaces abren el navegador. Primero, una pregunta para adultos.",
            "de": "Die Links öffnen den Browser. Zuerst eine Frage für Eltern.",
            "it": "I link aprono il browser. Prima una domanda per i genitori.",
            "zh-Hans": "链接会打开浏览器。请家长先回答一个问题。",
            "zh-Hant": "連結會打開瀏覽器。請家長先回答一個問題。",
        ],
        "rysunkiH": [
            "pl": "Rysunki dziecka w grze", "en": "The child’s drawings in the game", "fr": "Les dessins de l’enfant dans le jeu",
            "es": "Los dibujos de la niña en el juego", "de": "Die Zeichnungen des Kindes im Spiel", "it": "I disegni della bambina nel gioco",
            "zh-Hans": "游戏里孩子画的画", "zh-Hant": "遊戲裡孩子畫的畫",
        ],
    ]

    static func tekst(_ jezyk: String, _ klucz: String) -> String? {
        guard let t = teksty[klucz] else { return nil }
        return t[jezyk] ?? t["pl"]
    }
}
