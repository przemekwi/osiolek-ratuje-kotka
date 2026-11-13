// Ikona aplikacji (1024×1024) z rysunków dziecka: osiołek i kotek narysowani tymi samymi funkcjami co w grze.
// Użycie: node narzedzia/ikona.mjs ../gry/src/assets/gry/osiolek-ratuje-kotka-w-labiryncie/osiolek.html
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
// Playwright z instalacji globalnej (require szuka też w NODE_PATH).
const { chromium } = createRequire(import.meta.url)('playwright');

const html = fs.readFileSync(process.argv[2], 'utf8');
const js = html.slice(html.lastIndexOf('<script>') + 8, html.lastIndexOf('</script>'));

function wytnij(poczatek) {
  const start = js.search(new RegExp(`(^|\\n)\\s*${poczatek.replace(/[()]/g, '\\$&')}`));
  if (start < 0) throw new Error('Brak: ' + poczatek);
  let i = js.indexOf(poczatek, start), glebokosc = 0, napis = null, byl = !poczatek.startsWith('function');
  for (; i < js.length; i++) {
    const z = js[i];
    if (napis) { if (z === '\\') i++; else if (z === napis) napis = null; continue; }
    if (z === "'" || z === '"' || z === '`') { napis = z; continue; }
    if ('{[('.includes(z)) { glebokosc++; byl = true; }
    else if ('}])'.includes(z)) { glebokosc--; if (glebokosc === 0 && byl && poczatek.startsWith('function') && z === '}') return js.slice(js.indexOf(poczatek, start), i + 1); }
    else if ((z === ';' || z === '\n') && glebokosc === 0 && byl) return js.slice(js.indexOf(poczatek, start), i + 1);
  }
  throw new Error('Niedomknięte: ' + poczatek);
}

const kod = ['const TAU=Math.PI*2;', 'let minKreska=2;',
  ...['const px=', 'const TUSZ=', 'const K=', 'const OSIOLEK=', 'const KOTEK=', 'const OBWODKA='].map(wytnij),
  ...['function sciezka(', 'function owal(', 'function ksztalt(', 'function linia(', 'function piorko(', 'function wpisz(',
    'function osiolekKodem(', 'function kotekKodem('].map(wytnij)].join('\n');

const strona = `<!doctype html><canvas id="c" width="1024" height="1024"></canvas><script>${kod}
const cv=document.getElementById('c'), c=cv.getContext('2d');
c.fillStyle='#f7f2e8'; c.fillRect(0,0,1024,1024);
// Miękka zieleń podłoża labiryntu pod postaciami.
c.fillStyle='#e8f0dc'; c.beginPath(); c.ellipse(512,900,470,150,0,0,TAU); c.fill();
// Żółta obwódka osiołka jak w grze: sylwetka przesunięta dookoła.
function zObwodka(rysuj,kolor,r){
  const a=document.createElement('canvas'); a.width=a.height=1024; rysuj(a.getContext('2d'));
  if(kolor){ const s=document.createElement('canvas'); s.width=s.height=1024; const sc=s.getContext('2d'); sc.drawImage(a,0,0);
    sc.globalCompositeOperation='source-in'; sc.fillStyle=kolor; sc.fillRect(0,0,1024,1024);
    for(let k=0;k<12;k++) c.drawImage(s,Math.cos(k*Math.PI/6)*r,Math.sin(k*Math.PI/6)*r); }
  c.drawImage(a,0,0);
}
zObwodka(cc=>wpisz(cc,OSIOLEK.ramka,70,90,560,840,(c2,s)=>osiolekKodem(c2,s,null)),OBWODKA.osiolek,16);
zObwodka(cc=>wpisz(cc,KOTEK.ramka,520,560,440,360,kotekKodem),null,0);
</script>`;

const przegladarka = await chromium.launch();
const p = await przegladarka.newPage({ viewport: { width: 1024, height: 1024 }, deviceScaleFactor: 1 });
p.on('pageerror', e => console.error('Błąd strony:', e.message));
await p.setContent(strona);
const dane = await p.evaluate(() => document.getElementById('c').toDataURL('image/png'));
await przegladarka.close();
const cel = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'OsiolekRatujeKotka', 'Zasoby', 'Assets.xcassets', 'AppIcon.appiconset');
fs.mkdirSync(cel, { recursive: true });
fs.writeFileSync(path.join(cel, 'ikona-1024.png'), Buffer.from(dane.split(',')[1], 'base64'));
console.log('Zapisano', path.join(cel, 'ikona-1024.png'));
