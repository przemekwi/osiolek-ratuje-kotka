// Eksport danych z gry webowej (osiolek.html z repo „gry”) do zasobów aplikacji iOS.
// Teksty i punkty rysunków nie są przepisywane ręcznie: skrypt wycina stałe z pliku gry, wykonuje je w `vm`
// i zapisuje jako JSON, więc aplikacja ma dokładnie te same dane co gra na gry.wilde.pl.
// Użycie: node narzedzia/eksport-z-gry.mjs ../gry/src/assets/gry/osiolek-ratuje-kotka-w-labiryncie/osiolek.html
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const plik = process.argv[2];
if (!plik) { console.error('Podaj ścieżkę do osiolek.html'); process.exit(1); }
const html = fs.readFileSync(plik, 'utf8');
const js = html.slice(html.lastIndexOf('<script>') + 8, html.lastIndexOf('</script>'));

// Wycina deklarację `const NAZWA=...;` z pominięciem nawiasów w napisach.
function deklaracja(nazwa) {
  const start = js.search(new RegExp(`(^|\\n)\\s*const ${nazwa}=`));
  if (start < 0) throw new Error('Brak stałej ' + nazwa);
  const od = js.indexOf('=', js.indexOf('const ' + nazwa, start)) + 1;
  let glebokosc = 0, napis = null;
  for (let i = od; i < js.length; i++) {
    const z = js[i];
    if (napis) { if (z === '\\') i++; else if (z === napis) napis = null; continue; }
    if (z === "'" || z === '"' || z === '`') { napis = z; continue; }
    if (z === '{' || z === '[' || z === '(') glebokosc++;
    else if (z === '}' || z === ']' || z === ')') glebokosc--;
    else if ((z === ';' || z === '\n') && glebokosc === 0 && js.slice(od, i).trim()) return `const ${nazwa}=${js.slice(od, i)};`;
  }
  throw new Error('Niedomknięta stała ' + nazwa);
}

const RYSUNKI = ['TUSZ', 'K', 'PALETA', 'OSIOLEK', 'KOTEK', 'SCENA', 'DOMEK_RAMKA', 'LAPKA', 'KRZAK', 'SLONCE2', 'ZWIERZATKO',
  'ROBOT', 'DZIEWCZYNKA', 'JEDNOROZEC', 'GWIAZDKI', 'SERCE', 'TRAWA', 'SAMOCHOD', 'KON', 'GRZYBEK', 'PILKA', 'OLOWEK',
  'PRZEBRANE', 'FLAMASTER', 'ALBUM', 'IKONY', 'KOSZULKI', 'KOLORY', 'OBWODKA'];
const kod = ['const TAU=Math.PI*2;', deklaracja('px'), ...RYSUNKI.map(deklaracja), deklaracja('TEKSTY'), deklaracja('JEZYKI'),
  deklaracja('NAZWY_JEZYKOW'), `this.wynik={${[...RYSUNKI, 'TEKSTY', 'JEZYKI', 'NAZWY_JEZYKOW'].join(',')}};`].join('\n');
const kontekst = { Math };
vm.runInNewContext(kod, kontekst);
const w = kontekst.wynik;

// Teksty elementów, których aplikacja nie ma: gra w karty (osobna gra), PWA, pełny ekran, udostępnianie, linki, wyzwania.
const POMIN = /^(pary|zp|karta|podloga|instal|pochwal|zaproszeni|hak|wyzwani|pelnyEkran|profile|strona|opisGry|grajPary|rozdzialPary)/;
const teksty = {};
for (const j of w.JEZYKI) teksty[j] = Object.fromEntries(Object.entries(w.TEKSTY[j]).filter(([k]) => !POMIN.test(k)));

const rysunki = Object.fromEntries(RYSUNKI.map(n => [n, w[n]]));
const cel = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'OsiolekRatujeKotka', 'Zasoby');
fs.mkdirSync(cel, { recursive: true });
fs.writeFileSync(path.join(cel, 'Rysunki.json'), JSON.stringify(rysunki));
fs.writeFileSync(path.join(cel, 'Teksty.json'), JSON.stringify({ jezyki: w.JEZYKI, nazwy: w.NAZWY_JEZYKOW, teksty }));

const klucze = Object.keys(teksty.pl).length;
console.log(`Rysunki: ${RYSUNKI.length} stałych. Teksty: ${w.JEZYKI.length} języków, ${klucze} kluczy (pl).`);
for (const j of w.JEZYKI) { const brak = Object.keys(teksty.pl).filter(k => !(k in teksty[j])); if (brak.length) console.log(`  ${j}: brak ${brak.length} kluczy (zostanie polski): ${brak.slice(0, 8).join(', ')}`); }
