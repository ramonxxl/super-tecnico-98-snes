// Fundos gerados por codigo: tela de titulo (estadio a noite) e fundo dos menus
'use strict';
const { Img } = require('./gfx');
const F = require('./fonte');

// ---------------------------------------------------------------- titulo
const PAL_TITLE = [null,
  '#081028', // 1 ceu escuro
  '#102048', // 2 ceu
  '#183068', // 3 ceu claro
  '#F8F0C0', // 4 refletor
  '#303848', // 5 arquibancada
  '#C83030', // 6 torcida vermelha
  '#F8F8F8', // 7 branco
  '#F8D020', // 8 amarelo
  '#3070D0', // 9 torcida azul
  '#106020', // 10 gramado escuro
  '#188030', // 11 gramado claro
  '#E8E8E8', // 12 linhas
  '#101010', // 13 contorno
  '#F89818', // 14 laranja (titulo)
  '#202838', // 15 estrutura
];

function bigText(img, text, x0, y0, scale, fill, shade, outline) {
  const G = F.GLYPHS;
  let x = x0;
  for (const ch of text) {
    const g = G[ch] || G[' '];
    for (let y = 0; y < 7; y++) for (let xx = 0; xx < 5; xx++) if (g[y][xx] === '#') {
      img.rect(x + xx * scale, y0 + y * scale, scale, scale, y >= 5 ? shade : fill);
    }
    x += 6 * scale;
  }
}
function textWidth(text, scale) { return text.length * 6 * scale - scale; }

function titleScene() {
  const img = new Img(256, 224, 1);
  // ceu em faixas
  for (let y = 0; y < 72; y++) img.hline(0, y, 256, y < 24 ? 1 : y < 50 ? 2 : 3);
  // estrelas
  let s = 7;
  const r = () => { s = (s * 1103515245 + 12345) & 0x7FFFFFFF; return s / 0x80000000; };
  for (let i = 0; i < 40; i++) img.set(Math.floor(r() * 256), Math.floor(r() * 40), 7);
  // torres de refletor
  for (const tx of [18, 230]) {
    img.rect(tx, 14, 8, 64, 15);
    img.rect(tx - 10, 6, 28, 12, 15);
    for (let i = 0; i < 4; i++) img.rect(tx - 8 + i * 7, 8, 5, 8, 4);
  }
  // arquibancada com torcida
  for (let y = 72; y < 122; y++) img.hline(0, y, 256, 5);
  for (let y = 74; y < 120; y += 4) for (let x = (y % 8 ? 2 : 0); x < 256; x += 4) {
    const v = r();
    img.rect(x, y, 2, 2, v < 0.3 ? 6 : v < 0.55 ? 9 : v < 0.75 ? 7 : v < 0.85 ? 8 : 5);
  }
  img.hline(0, 121, 256, 15); img.hline(0, 122, 256, 13);
  // gramado em faixas
  for (let y = 123; y < 224; y++) for (let x = 0; x < 256; x++) img.set(x, y, (Math.floor(x / 32) % 2) ? 10 : 11);
  // linhas do campo (circulo central em perspectiva)
  img.hline(0, 130, 256, 12);
  for (let a = 0; a < 360; a += 1) {
    const x = 128 + Math.cos(a * Math.PI / 180) * 60, y = 172 + Math.sin(a * Math.PI / 180) * 26;
    img.set(Math.round(x), Math.round(y), 12);
  }
  img.vline(128, 130, 94, 12);
  // bola
  img.ell(122, 166, 133, 177, 7);
  img.art(['..##..', '.#..#.', '#....#', '.#..#.', '..##..'], 125, 169, { '#': 13 });
  // titulo grande
  const t1 = 'SUPER', t2 = 'TÉCNICO 98';
  const w1 = textWidth(t1, 4), w2 = textWidth(t2, 3);
  const tmp = new Img(256, 224, 0);
  bigText(tmp, t1, Math.floor((256 - w1) / 2), 20, 4, 8, 14);
  bigText(tmp, t2, Math.floor((256 - w2) / 2), 54, 3, 7, 12);
  // contorno
  const o = new Img(256, 224, 0); o.p.set(tmp.p); o.outline(13); o.outline(13);
  for (let i = 0; i < o.p.length; i++) if (o.p[i]) img.p[i] = o.p[i];
  for (let i = 0; i < tmp.p.length; i++) if (tmp.p[i]) img.p[i] = tmp.p[i];
  // faixa escura atras dos textos do menu
  for (let y = 132; y < 190; y++) for (let x = 40; x < 216; x++) if ((x + y) % 2 === 0 || y === 132 || y === 189) img.set(x, y, 13);
  return img;
}

// ---------------------------------------------------------------- menus
// tema moderno: azul-marinho. A imagem tem 232 linhas porque o BG1 fica 4 px acima do texto
// (assim um botao de 16 px fica centrado na linha de texto de 8 px).
const PAL_MENU = [null,
  '#0A1230', // 1 fundo
  '#0D1738', // 2 fundo (listra)
  '#141F48', // 3 barras de topo e rodape
  '#2F6BFF', // 4 linha azul vibrante
  '#1A2A5E', // 5 linha discreta
  '#101B40', // 6 detalhe
];
const DESLOC = 4;
function menuScene() {
  const img = new Img(256, 232, 1);
  // listras diagonais bem sutis
  for (let y = 0; y < 232; y++) for (let x = 0; x < 256; x++) img.set(x, y, ((x + y) >> 4) % 2 ? 1 : 2);
  // barra de topo (linhas de texto 0..2) e rodape (linhas 24..27), ja com o deslocamento
  img.rect(0, 0, 256, 24 + DESLOC, 3); img.hline(0, 24 + DESLOC, 256, 4); img.hline(0, 25 + DESLOC, 256, 5);
  img.rect(0, 192 + DESLOC, 256, 40, 3); img.hline(0, 191 + DESLOC, 256, 5);
  return img;
}
// desloca uma cena de 224 linhas para a imagem de 232 (repete a primeira e a ultima linha)
function deslocada(src) {
  const img = new Img(256, 232, 1);
  for (let y = 0; y < 232; y++) for (let x = 0; x < 256; x++) img.set(x, y, src.get(x, Math.max(0, Math.min(223, y - DESLOC))));
  return img;
}

// ---------------------------------------------------------------- escudo 32x32 (sprite)
// cores: 1 contorno, 2 cor principal, 3 cor secundaria, 4 brilho
function shield() {
  const img = new Img(32, 32, 0);
  for (let y = 1; y < 31; y++) {
    // laterais retas ate y=18, depois afunila ate a ponta
    let half = y < 18 ? 13 : Math.max(1, Math.round(13 - (y - 18) * 1.05));
    if (y < 4) half = 13 - (4 - y);
    for (let x = 16 - half; x < 16 + half; x++) img.set(x, y, (x >= 12 && x < 20) ? 3 : 2);
  }
  // faixa superior
  for (let y = 4; y < 9; y++) for (let x = 0; x < 32; x++) if (img.get(x, y)) img.set(x, y, 3);
  img.outline(1);
  // brilho
  for (let y = 10; y < 16; y++) img.set(6, y, 4);
  return img;
}
// folha de sprites 128x32 (16 tiles por linha) com o escudo em 4 sprites 16x16
function shieldTiles(enc4, tilePixels) {
  const sheet = new Img(128, 32, 0);
  sheet.paste(shield(), 0, 0);
  // reorganiza: sprite 16x16 n usa tiles n, n+1, n+16, n+17
  const out = [];
  for (let ty = 0; ty < 4; ty++) for (let tx = 0; tx < 16; tx++) out.push(enc4(tilePixels(sheet, tx, ty)));
  return Buffer.concat(out);
}

module.exports = { titleScene, menuScene, deslocada, shieldTiles, PAL_TITLE, PAL_MENU };
