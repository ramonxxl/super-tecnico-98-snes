// Audio: driver SPC700 minimo (proxy de escrita no DSP), samples BRR e musicas
'use strict';

// ---------- driver SPC700 em $0200 (codigo de maquina montado a mao)
// loop: espera porta0 mudar; DSP[porta1] = porta2; ecoa porta0
const DRIVER = [
  0xE4, 0xF4,       // 0200 mov a,$F4
  0xC4, 0x00,       // 0202 mov $00,a
  0xE4, 0xF4,       // 0204 loop: mov a,$F4
  0x64, 0x00,       // 0206 cmp a,$00
  0xF0, 0xFA,       // 0208 beq loop
  0xC4, 0x00,       // 020A mov $00,a
  0xE4, 0xF5,       // 020C mov a,$F5
  0xC4, 0xF2,       // 020E mov $F2,a
  0xE4, 0xF6,       // 0210 mov a,$F6
  0xC4, 0xF3,       // 0212 mov $F3,a
  0xE4, 0x00,       // 0214 mov a,$00
  0xC4, 0xF4,       // 0216 mov $F4,a
  0x2F, 0xEA,       // 0218 bra loop
];


// ---------- tabela de afinacao: periodo de 32 pontos. nota 1 = C2
function pitchTable() {
  const t = [0];
  for (let n = 1; n <= 72; n++) {
    const midi = n + 35, f = 440 * Math.pow(2, (midi - 69) / 12);
    t.push(Math.min(0x3FFF, Math.round(f * 32 / 32000 * 4096)));
  }
  return t;
}
const NOTE_IDX = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
function noteNum(tok) {
  const m = /^([A-G])([#b]?)(\d)$/.exec(tok);
  if (!m) throw new Error('nota invalida ' + tok);
  let midi = (parseInt(m[3]) + 1) * 12 + NOTE_IDX[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0);
  const n = midi - 35; if (n < 1 || n > 72) throw new Error('nota fora da faixa ' + tok);
  return n;
}

const I = require('./instrumentos');

// ---------- bloco enviado ao SPC: driver em $0200, diretorio em $0300, amostras depois
let AMOSTRAS = null;
function spcBlob() {
  if (!AMOSTRAS) AMOSTRAS = I.amostras();
  const base = 0x0200, dirAddr = 0x0300;
  const blob = new Array(dirAddr - base).fill(0);
  DRIVER.forEach((b, i) => { blob[i] = b; });
  const dir = [], data = [];
  let addr = dirAddr + AMOSTRAS.length * 4;
  for (const s of AMOSTRAS) {
    const loop = s.loop != null ? addr + s.loop * 9 : addr;
    dir.push(addr & 255, addr >> 8, loop & 255, loop >> 8);
    data.push(...s.brr); addr += s.brr.length;
  }
  if (addr > 0xCF00) throw new Error('amostras nao cabem na memoria de som');
  blob.push(...dir, ...data);
  // a sequencia do IPL termina com (tamanho+1)&255 != 0
  while (((blob.length + 1) & 255) === 0) blob.push(0);
  return Buffer.from(blob);
}

// ---------- instrumentos: [amostra, ADSR1, ADSR2, transposicao] ($80 = altura fixa 32 kHz, $81 = 16 kHz)
const S = { quadrada: 0, triangulo: 1, pulso: 2, seno: 3, serra: 4, metais: 5, baixo: 6, guitarra: 7, epiano: 8, bumbo: 9, caixa: 10, chimbal: 11, tom: 12, slap: 13, cordas: 14, prato: 15 };
const INSTR = [
  [S.metais, 0xCE, 0xCB, 0],     // 0 metais (melodia)
  [S.baixo, 0xFF, 0xAD, 12],     // 1 baixo eletrico
  [S.guitarra, 0xFE, 0xCE, 24],  // 2 guitarra (acorde de quinta)
  [S.quadrada, 0xFF, 0xF0, 0],   // 3 efeitos: quadrada
  [S.pulso, 0xFF, 0xF0, 0],      // 4 efeitos: pulso
  [S.triangulo, 0xFE, 0x76, 0],  // 5 efeitos: triangulo curto
  [S.seno, 0xFF, 0x36, 0],       // 6 marimba
  [S.seno, 0xFF, 0xF0, 0],       // 7 apito
  [S.serra, 0xDA, 0xAE, 0],      // 8 cordas
  [S.bumbo, 0xFF, 0xE0, 0x81],   // 9 bumbo
  [S.caixa, 0xFF, 0xE0, 0x81],   // 10 caixa
  [S.chimbal, 0xFF, 0xE0, 0x80], // 11 chimbal
  [S.tom, 0xFF, 0xE0, 0x81],     // 12 tom
  [S.epiano, 0xFF, 0xAF, 0],     // 13 piano eletrico
  [S.seno, 0xDB, 0xAA, 0],       // 14 flauta
  [S.baixo, 0xFF, 0x8E, 12],     // 15 baixo macio
  [S.slap, 0xFF, 0x8C, 12],      // 16 baixo slap
  [S.cordas, 0x89, 0xE0, 0],     // 17 cordas (entrada lenta)
  [S.prato, 0xFF, 0xE0, 0x81],   // 18 prato de ataque
];
const BATERIA = { K: 9, S: 10, H: 11, T: 12, C: 18 };

// formato do canal: [nota(0=pausa) dur] | F0 inst | F1 vol | F2 esq dir | FD marca | FE repete | FF fim
// fichas: C#5:2 nota | R:4 pausa | K S H T bateria | @n instrumento | v30 volume | p40,20 estereo | [ marca
function compileTrack(src, tempo, { inst = 0, vol = 0x40, pan = null, loop = true } = {}) {
  const out = [0xF0, inst];
  if (pan) out.push(0xF2, pan[0], pan[1]); else out.push(0xF1, vol);
  let atual = inst;
  for (const tok of src.trim().split(/\s+/)) {
    if (tok === '|') continue;
    if (tok === '[') { out.push(0xFD); atual = -1; continue; }
    if (tok.startsWith('@')) { atual = parseInt(tok.slice(1)); out.push(0xF0, atual); continue; }
    if (/^v[0-9A-Fa-f]+$/.test(tok)) { out.push(0xF1, parseInt(tok.slice(1), 16)); continue; }
    if (tok.startsWith('p')) { const [l, r] = tok.slice(1).split(',').map((x) => parseInt(x, 16)); out.push(0xF2, l, r); continue; }
    const [n, d] = tok.split(':');
    let frames = Math.round(parseFloat(d) * tempo);
    let note;
    if (n === 'R') note = 0;
    else if (n in BATERIA) { if (atual !== BATERIA[n]) { atual = BATERIA[n]; out.push(0xF0, atual); } note = 1; }
    else note = noteNum(n);
    let first = true;
    while (frames > 0) { const f = Math.min(frames, 250); out.push(first ? note : 0, f); frames -= f; first = false; }
  }
  out.push(loop ? 0xFE : 0xFF);
  return out;
}

// ---------- ajudantes de arranjo (compasso = 16 semicolcheias)
const rep = (s, n) => Array(n).fill(s).join(' | ');
const RAIZ = { D: 'D', Bm: 'B', G: 'G', A: 'A', Em: 'E', 'F#m': 'F#', E: 'E', C: 'C' };
const oit = (r) => (['C', 'D', 'E', 'F#'].includes(r) ? 2 : 2);
// baixo slap: semicolcheias com estalo de oitava
const baixoSlap = (c) => { const r = RAIZ[c]; const a = `${r}2`, b = `${r}3`; return `${a}:2 ${a}:1 ${b}:1 R:1 ${a}:1 ${b}:2 ${a}:1 ${a}:1 ${b}:2 ${a}:1 ${a}:1 ${b}:2`; };
// guitarra: acordes de quinta curtos no contratempo
const guitStab = (c) => { const r = RAIZ[c] + (['D', 'E', 'F#'].includes(RAIZ[c]) ? '3' : '2'); return `R:2 ${r}:1 R:1 R:2 ${r}:2 R:2 ${r}:1 R:1 ${r}:2 R:2`; };
// cordas: nota longa do acorde
const CORDA = { D: 'F#4', Bm: 'D4', G: 'B4', A: 'C#5', Em: 'G4', 'F#m': 'A4' };
const BATIDA = 'K:2 R:2 S:2 R:1 K:1 R:1 K:1 K:2 S:2 R:1 S:1';
const VIRADA = 'K:2 S:1 S:1 S:2 S:1 S:1 T:2 T:1 T:1 S:1 S:1 S:1 S:1';
const CHIMBAL = 'H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1';
const CHIMBAL_PRATO = 'C:2 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1 H:1';

const SONGS = {
  // abertura: rock de futebol rapido (introducao toca uma vez; depois repete estrofe + refrao)
  // trilhas na ordem das vozes: 0 melodia, 1 baixo, 2 guitarra, 5 cordas, 6 bateria, 7 chimbal/prato
  titulo: (() => {
    const prog = ['D', 'Bm', 'G', 'A', 'D', 'Bm', 'Em', 'A', 'G', 'A', 'F#m', 'Bm', 'G', 'A', 'D', 'D'];
    const lead = `D5:2 R:2 D5:2 R:2 D5:2 R:1 D5:1 R:2 C#5:2 | B4:2 R:2 B4:2 R:2 A4:4 R:4 | [
      A4:2 D5:2 F#5:4 E5:2 D5:2 E5:4 | F#5:6 E5:2 D5:4 B4:4 | G4:2 B4:2 D5:4 E5:2 D5:2 B4:4 | A4:8 R:4 A4:2 C#5:2 |
      D5:2 F#5:2 A5:4 G5:2 F#5:2 E5:4 | F#5:6 D5:2 B4:4 D5:4 | E5:2 G5:2 B5:4 A5:2 G5:2 E5:4 | A5:12 R:4 |
      B5:4 A5:2 G5:2 D5:4 G5:4 | A5:4 G5:2 F#5:2 E5:8 | F#5:4 E5:2 D5:2 C#5:4 A4:4 | B4:2 D5:2 F#5:4 B5:8 |
      B5:4 A5:2 G5:2 D6:4 B5:4 | C#6:4 B5:2 A5:2 E5:4 C#6:4 | D6:12 R:2 A5:2 | D6:4 R:12`;
    const intro = (n) => `${n.d}:2 R:2 ${n.d}:2 R:2 ${n.d}:2 R:1 ${n.d}:1 R:2 ${n.c}:2 | ${n.b}:2 R:2 ${n.b}:2 R:2 ${n.a}:4 R:4`;
    const bass = intro({ d: 'D2', c: 'C#3', b: 'B2', a: 'A2' }) + ' | [ ' + prog.map(baixoSlap).join(' | ');
    const gtr = intro({ d: 'D3', c: 'C#3', b: 'B2', a: 'A2' }) + ' | [ ' + prog.map(guitStab).join(' | ');
    const pad = 'R:16 | R:16 | [ ' + prog.map((c) => `${CORDA[c]}:16`).join(' | ');
    const drums = `S:2 S:2 S:2 S:2 S:1 S:1 S:1 S:1 T:2 T:2 | K:2 R:2 K:2 R:2 T:2 T:2 S:1 S:1 S:2 | [ ` +
      prog.map((_, i) => (i === 7 || i === 15) ? VIRADA : BATIDA).join(' | ');
    const hats = `R:16 | R:16 | [ ` + prog.map((_, i) => (i % 4 === 0) ? CHIMBAL_PRATO : CHIMBAL).join(' | ');
    return { tempo: 5, loop: true, ch: [
      [0, 0x2A, lead, [0x2A, 0x26]],
      [16, 0x3A, bass],
      [2, 0x18, gtr, [0x22, 0x0E]],
      [17, 0x14, pad, [0x10, 0x18]],
      [9, 0x3A, drums],
      [11, 0x12, hats, [0x0C, 0x16]],
    ] };
  })(),
  // menus: groove mais calmo, piano eletrico, cordas e chimbal em semicolcheias
  menu: (() => {
    const acordes = [['B3', 'D4', 'F#4'], ['A3', 'C#4', 'E4'], ['G3', 'B3', 'D4'], ['G3', 'C#4', 'E4'],
      ['B3', 'D4', 'F#4'], ['A3', 'C#4', 'E4'], ['G3', 'C#4', 'E4'], ['F#3', 'A3', 'D4']];
    const piano = acordes.map(([x, y, z]) => `${x}:2 ${y}:2 R:2 ${z}:4 ${y}:2 R:4`).join(' | ');
    const pad = ['D5', 'C#5', 'B4', 'A4', 'D5', 'C#5', 'B4', 'A4'].map((n) => `${n}:16`).join(' | ');
    const raiz = [['G2', 'D3'], ['F#2', 'C#3'], ['E2', 'B2'], ['A2', 'E2'], ['G2', 'D3'], ['F#2', 'C#3'], ['E2', 'A2'], ['D2', 'A2']];
    const bass = raiz.map(([r, q], i) => i === 6 ? 'E2:4 B2:4 A2:4 E2:4' : `${r}:3 ${r}:1 R:2 ${q}:2 R:2 ${r}:2 ${q}:2 ${r}:2`).join(' | ');
    const lead = `R:4 F#5:2 G5:2 A5:6 F#5:2 | E5:8 R:4 C#5:2 E5:2 | D5:4 E5:2 F#5:2 G5:4 B5:4 | A5:12 R:4 |
      R:4 F#5:2 G5:2 A5:4 D6:4 | C#6:8 B5:2 A5:2 F#5:4 | G5:4 F#5:2 E5:2 G5:4 C#5:4 | D5:12 R:4`;
    return { tempo: 6, loop: true, ch: [
      [14, 0x20, lead, [0x22, 0x1C]],
      [16, 0x2C, bass],
      [13, 0x1E, piano, [0x12, 0x22]],
      [17, 0x10, pad, [0x0E, 0x12]],
      [9, 0x2C, rep('K:3 K:1 S:4 R:2 K:2 S:4', 8)],
      [11, 0x0E, rep('H:2 H:1 H:1 H:2 H:1 H:1 H:2 H:1 H:1 H:2 H:2', 8), [0x08, 0x12]],
    ] };
  })(),
  vitoria: { tempo: 5, loop: false, ch: [
    [0, 0x30, `D5:2 D5:2 D5:2 G5:6 R:2 F#5:2 G5:2 A5:2 B5:12`],
    [16, 0x3C, `G2:2 G2:2 G2:2 B2:6 R:2 D3:2 D3:2 D3:2 G2:12`],
    [2, 0x20, `G2:2 G2:2 G2:2 G2:6 R:2 D3:2 D3:2 D3:2 G2:12`],
    [17, 0x14, `B4:20 D5:12`],
    [9, 0x38, `S:2 S:2 S:2 K:6 R:2 S:2 S:2 S:2 K:12`],
    [11, 0x14, `C:20 C:12`],
  ] },
  derrota: { tempo: 8, loop: false, ch: [
    [14, 0x2C, `G4:3 F#4:3 F4:3 E4:9`],
    [15, 0x38, `C3:3 B2:3 Bb2:3 A2:9`],
    [13, 0x18, `E4:3 D#4:3 D4:3 C#4:9`],
    [17, 0x10, `C4:18`],
    [9, 0x00, `R:18`],
    [11, 0x00, `R:18`],
  ] },
};

// efeitos: duracoes em quadros (tempo 1)
const SFX = {
  cursor: [6, 0x20, `E6:3`],
  ok: [6, 0x2C, `C6:3 G6:7`],
  erro: [5, 0x34, `C3:5 R:2 C3:8`],
  apito: [7, 0x24, `B6:4 R:1 B6:3 R:1 B6:16`],
  fim: [7, 0x24, `B6:8 R:4 B6:8 R:4 B6:30`],
  gol: [6, 0x3C, `C5:4 E5:4 G5:4 C6:6 R:2 G5:3 C6:16`],
  golcontra: [5, 0x34, `E4:6 C4:14`],
  moeda: [6, 0x30, `B5:3 E6:10`],
};

function musicData() {
  const songs = Object.entries(SONGS).map(([name, s]) => ({
    name, tracks: s.ch.map(([inst, vol, src, pan]) => compileTrack(src, s.tempo, { inst, vol, pan, loop: s.loop })),
  }));
  const sfx = Object.keys(SFX).map((name) => { const [inst, vol, src] = SFX[name]; return { name, data: compileTrack(src, 1, { inst, vol, loop: false }) }; });
  return { songs, sfx };
}

module.exports = { spcBlob, pitchTable, musicData, INSTR, amostrasUsadas: () => { if (!AMOSTRAS) spcBlob(); return AMOSTRAS; } };
