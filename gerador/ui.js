// Pecas da interface (tiles 4bpp do BG1) e paletas dos estilos de botao.
// O BG1 fica 4 px acima do texto: um botao de 2 tiles de altura (16 px) fica centrado
// na linha de texto; a faixa de selecao usa metades de tile para alinhar com a linha.
'use strict';
const { enc4, bgr555 } = require('./gfx');

// indices de cor: 1 borda, 2 brilho, 3 corpo claro, 4 corpo, 5 corpo escuro, 6 sombra
// botao: 16 px de altura (linha 0 e 15 transparentes), cantos arredondados
function linhaBotao(y) {
  if (y === 0 || y === 15) return null;
  if (y === 1 || y === 14) return 1;
  if (y === 2) return 2;
  if (y === 13) return 6;
  return y < 6 ? 3 : y < 10 ? 4 : 5;
}
// recuo da borda esquerda em cada linha (canto arredondado, raio 3) - x0 e margem transparente
const RECUO = [9, 4, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 4, 9];
function botao(metade, canto) {      // metade 0 = de cima, 1 = de baixo
  const px = new Array(64).fill(0);
  for (let ty = 0; ty < 8; ty++) {
    const y = metade * 8 + ty, c = linhaBotao(y);
    if (c === null) continue;
    for (let x = 0; x < 8; x++) {
      if (canto) {
        const r = RECUO[y];
        if (x < r) continue;
        px[ty * 8 + x] = (x === r || (x === r + 1 && (y === 1 || y === 14) && false)) ? 1 : c;
        // borda lateral
        if (x === r) px[ty * 8 + x] = 1;
      } else px[ty * 8 + x] = c;
    }
  }
  return px;
}
// painel (meio): lateral e miolo
function painel(lado) {
  const px = new Array(64).fill(5);
  if (lado) for (let y = 0; y < 8; y++) { px[y * 8] = 0; px[y * 8 + 1] = 1; }
  return px;
}
// faixa de selecao: 8 px de altura, dividida em duas metades de tile
function linhaFaixa(y) { return y === 0 || y === 7 ? 1 : y === 1 ? 2 : y === 6 ? 6 : y < 4 ? 3 : 4; }
function faixa(metade, canto) {      // metade 0 = parte de cima da faixa (fica na metade de BAIXO do tile)
  const px = new Array(64).fill(0);
  for (let k = 0; k < 4; k++) {
    const y = metade * 4 + k, ty = metade === 0 ? 4 + k : k, c = linhaFaixa(y);
    const r = canto ? [3, 2, 1, 1, 1, 1, 2, 3][y] : 0;
    for (let x = r; x < 8; x++) px[ty * 8 + x] = (canto && x === r) ? 1 : c;
  }
  return px;
}

const TILES = [
  botao(0, true), botao(0, false), botao(1, true), botao(1, false),   // 0 TL, 1 T, 2 BL, 3 B
  painel(true), painel(false),                                        // 4 L, 5 M
  faixa(0, true), faixa(0, false), faixa(1, true), faixa(1, false),   // 6 LB, 7 MB, 8 LT, 9 MT
];
function tiles() { return Buffer.concat(TILES.map(enc4)); }

// estilos (paletas 3..7 do BG1)
const ESTILOS = {
  normal:   ['#050A1C', '#5A6FA8', '#2E3E6E', '#26335C', '#1D284B', '#121A34'],
  primario: ['#041036', '#9CC0FF', '#3F7CFF', '#2E66EE', '#2350C8', '#173894'],
  sel:      ['#F8D020', '#FFFFFF', '#6AB4FF', '#3F8CFF', '#2C6EE0', '#1C4CAC'],
  ok:       ['#04200E', '#A8F4B8', '#36C262', '#28A852', '#1D8A42', '#136630'],
  perigo:   ['#2A0606', '#FFB0A8', '#F05C4C', '#D84232', '#B43024', '#882018'],
};
function paletas() {
  const out = Buffer.alloc(5 * 32);
  Object.values(ESTILOS).forEach((cores, p) => cores.forEach((c, i) => out.writeUInt16LE(bgr555(c), p * 32 + (i + 1) * 2)));
  return out;
}
// pulso do botao selecionado: 8 passos das cores 3, 4 e 5 (corpo)
function pulso() {
  const mix = (a, b, t) => '#' + [1, 3, 5].map((i) => Math.round(parseInt(a.slice(i, i + 2), 16) * (1 - t) + parseInt(b.slice(i, i + 2), 16) * t).toString(16).padStart(2, '0')).join('');
  const claro = ['#8CC8FF', '#5AA4FF', '#3F84F0'], base = ESTILOS.sel.slice(2, 5);
  const out = [];
  for (let k = 0; k < 8; k++) {
    const t = (1 - Math.cos(k / 8 * 2 * Math.PI)) / 2;
    for (let i = 0; i < 3; i++) out.push(bgr555(mix(base[i], claro[i], t)));
  }
  return out;
}

module.exports = { tiles, paletas, pulso, N_TILES: TILES.length, ESTILOS: Object.keys(ESTILOS) };
