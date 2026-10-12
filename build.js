// Build da ROM "Super Tecnico 98" (SNES, LoROM 1 MB, 64 KB de SRAM)
// Uso: node build.js        (le elenco.json; cria o padrao se nao existir)
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const F = require('./gerador/fonte');
const AU = require('./gerador/audio');
const A = require('./gerador/arte');
const R = require('./gerador/regras');
const { T } = require('./gerador/textos');
const { palBytes, sceneToBG } = require('./gerador/gfx');

const ROOT = __dirname, GEN = path.join(ROOT, 'gen');
fs.mkdirSync(GEN, { recursive: true });
const w = (name, buf) => fs.writeFileSync(path.join(GEN, name), buf);
const hex2 = (n) => '$' + (n & 255).toString(16).toUpperCase().padStart(2, '0');
const hex4 = (n) => '$' + (n & 0xFFFF).toString(16).toUpperCase().padStart(4, '0');
const byteLines = (arr) => { const out = []; for (let i = 0; i < arr.length; i += 16) out.push('  .byte ' + arr.slice(i, i + 16).map(hex2).join(',')); return out.join('\n'); };
const wordLines = (arr) => { const out = []; for (let i = 0; i < arr.length; i += 8) out.push('  .word ' + arr.slice(i, i + 8).map(hex4).join(',')); return out.join('\n'); };
const erro = (m) => { console.error('ERRO NO ELENCO: ' + m); process.exit(1); };

// ------------------------------------------------------------ elenco
const elencoPath = path.join(ROOT, 'elenco.json');
if (!fs.existsSync(elencoPath)) {
  fs.writeFileSync(elencoPath, JSON.stringify(require('./gerador/elenco').gerar(), null, 1));
  console.log('elenco.json padrao criado.');
}
const E = JSON.parse(fs.readFileSync(elencoPath, 'utf8'));
if (!Array.isArray(E.clubes) || E.clubes.length !== 64) erro('precisa ter exatamente 64 clubes (tem ' + (E.clubes || []).length + ')');
const POSN = { G: 0, D: 1, M: 2, A: 3 };
const fixed = (s, n, onde) => {
  s = String(s || '').toUpperCase().trim();
  if (s.length > n) erro(`"${s}" tem mais de ${n} letras (${onde})`);
  try { return F.compile(s.padEnd(n)).slice(0, n); } catch (e) { erro(e.message + ` (${onde})`); }
};
const nomes = [], nomeIdx = new Map();
const nomeId = (s, onde) => {
  const k = String(s).toUpperCase().trim();
  if (!nomeIdx.has(k)) { nomeIdx.set(k, nomes.length); nomes.push(fixed(k, 12, onde)); }
  return nomeIdx.get(k);
};
const porDiv = [[], [], [], []];
const teamName = [], teamAbbr = [], teamFame = [], teamCap = [], initPlayers = [];
E.clubes.forEach((c, t) => {
  const onde = `clube ${t + 1} ${c.nome}`;
  const d = 'ABCD'.indexOf(String(c.divisao).toUpperCase());
  if (d < 0) erro(`divisao invalida (${onde})`);
  porDiv[d].push(t);
  teamName.push(...fixed(c.nome, 12, onde));
  teamAbbr.push(...fixed(c.sigla, 3, onde));
  teamFame.push(Math.max(1, Math.min(10, c.fama | 0)));
  teamCap.push(Math.max(1000, Math.min(65000, c.capacidade | 0)));
  const js = c.jogadores || [];
  if (js.length < 16 || js.length > 26) erro(`cada clube precisa de 16 a 26 jogadores (${onde} tem ${js.length})`);
  if (!js.some((j) => j.pos === 'G')) erro(`sem goleiro (${onde})`);
  for (let s = 0; s < 26; s++) {
    const j = js[s];
    if (!j) { initPlayers.push(0, 0, 0, 0, 0); continue; }
    const p = POSN[String(j.pos).toUpperCase()];
    if (p === undefined) erro(`posicao invalida "${j.pos}" (${onde}, ${j.nome})`);
    const id = nomeId(j.nome, onde);
    initPlayers.push(p, Math.max(1, Math.min(50, j.forca | 0)), Math.max(15, Math.min(45, j.idade | 0)), id & 255, id >> 8);
  }
});
porDiv.forEach((l, d) => { if (l.length !== 16) erro(`a serie ${'ABCD'[d]} precisa de 16 clubes (tem ${l.length})`); });
const POOL_START = nomes.length;
for (const n of (E.nomesBase || [])) { if (nomes.length >= 2700) break; nomeId(n, 'nomesBase'); }
let POOL_N = nomes.length - POOL_START;
if (POOL_N < 50) { // poucos nomes novos: garotos usam todos os nomes
  POOL_N = nomes.length;
}
const poolStart = POOL_N === nomes.length ? 0 : POOL_START;
if (nomes.length > 2730) erro('nomes demais (max 2730)');
w('nomes.bin', Buffer.from(nomes.flat()));
console.log(`elenco: 64 clubes, ${nomes.length} nomes (${POOL_N} para a base)`);

const clubes = ['; gerado por build.js - nao editar'];
clubes.push('TeamName:\n' + byteLines(teamName));
clubes.push('TeamAbbr:\n' + byteLines(teamAbbr));
clubes.push('TeamFame:\n' + byteLines(teamFame));
clubes.push('TeamCap:\n' + wordLines(teamCap));
clubes.push('InitDiv:\n' + byteLines(porDiv.flat()));
clubes.push('InitPlayers:\n' + byteLines(initPlayers));
w('clubes.inc', clubes.join('\n') + '\n');

// ------------------------------------------------------------ fundos
for (const [name, img, pal] of [['title', A.deslocada(A.titleScene()), A.PAL_TITLE], ['menu', A.menuScene(), A.PAL_MENU]]) {
  const bg = sceneToBG(img, 2, null);
  w(`${name}_tiles.bin`, bg.tiles); w(`${name}_map.bin`, bg.map); w(`${name}_pal.bin`, palBytes(pal));
  console.log(`fundo ${name}: ${bg.count} tiles`);
}

// ------------------------------------------------------------ escudo (sprites) e cores dos clubes
{
  const { enc4, tilePixels, bgr555 } = require('./gerador/gfx');
  w('shield.bin', A.shieldTiles(enc4, tilePixels));
  const cores = [];
  E.clubes.forEach((c, t) => {
    const cs = (c.cores || ['#F8F8F8', '#101010']).map((h) => /^#[0-9a-f]{6}$/i.test(h) ? h : '#F8F8F8');
    cores.push(bgr555(cs[0]), bgr555(cs[1] || cs[0]));
  });
  clubes.push('TeamCol:\n' + wordLines(cores));
  w('clubes.inc', clubes.join('\n') + '\n');
  // escudinhos 8x8 (7 variantes: cada uma usa um par de cores proprio da paleta; contorno = cor 15)
  const FORMA = ['OOOOOOOO', 'OaaabbbO', 'OaaabbbO', 'OaaabbbO', 'OaaabbbO', '.OaabbO.', '..OabO..', '...OO...'];
  const crest = Buffer.alloc(7 * 32);
  for (let v = 0; v < 7; v++) for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) {
    const ch = FORMA[y][x];
    const c = ch === 'O' ? 15 : ch === 'a' ? 1 + 2 * v : ch === 'b' ? 2 + 2 * v : 0;
    for (let p = 0; p < 4; p++) if (c & (1 << p)) crest[v * 32 + (p < 2 ? 0 : 16) + y * 2 + (p & 1)] |= 0x80 >> x;
  }
  w('crest.bin', crest);
}

// ------------------------------------------------------------ fonte e paletas de texto
w('font.bin', F.fontTiles());
// paletas de texto: [transparente, corpo, contorno/sombra, brilho do topo da letra]
const TEXTPAL = [
  ['#000000', '#E4E9F4', '#04060E', '#FFFFFF'],   // 0 branco
  ['#000000', '#F8C820', '#04060E', '#FFF088'],   // 1 amarelo (destaque / alerta)
  ['#000000', '#48D070', '#04060E', '#A8F8B8'],   // 2 verde (positivo)
  ['#000000', '#F05848', '#04060E', '#FFA898'],   // 3 vermelho (perigo)
  ['#000000', '#93A0BC', '#04060E', '#C4CEE0'],   // 4 cinza-claro (texto secundario)
  ['#000000', '#F89030', '#04060E', '#FFC880'],   // 5 laranja (alerta)
  ['#000000', '#58A8F8', '#04060E', '#B0D8FF'],   // 6 azul
  ['#000000', '#E4E9F4', '#04060E', '#F4F6FA'],   // 7 placar grande (bloco = cor 3)
];
w('text_pal.bin', Buffer.concat(TEXTPAL.map((p) => palBytes(p).slice(0, 8))));

// ------------------------------------------------------------ interface: botoes, faixa, icones
const UI = require('./gerador/ui');
w('ui_tiles.bin', UI.tiles());
w('ui_pal.bin', UI.paletas());
try { execFileSync('python', [path.join('gerador', 'icones.py')], { cwd: ROOT, stdio: 'inherit' }); }
catch (e) { if (!fs.existsSync(path.join(GEN, 'icon_tiles.bin'))) throw e; console.warn('Python indisponivel: reutilizando os icones ja gerados.'); }

// ------------------------------------------------------------ audio
const spc = AU.spcBlob();
w('spc.bin', spc);
const music = AU.musicData();

// ------------------------------------------------------------ includes
const C = F.CODE;
const inc = ['; gerado por build.js - nao editar'];
inc.push(`FONT_0 = ${hex2(C['0'])}`, `FONT_1 = ${hex2(C['1'])}`, `FONT_SPACE = ${hex2(C[' '])}`, `FONT_ARROW = ${hex2(C['▶'])}`,
  `FONT_COLON = ${hex2(C[':'])}`, `FONT_MINUS = ${hex2(C['-'])}`, `FONT_APOS = ${hex2(C["'"])}`, `FONT_X = ${hex2(C['X'])}`,
  `FONT_LPAR = ${hex2(C['('])}`, `FONT_BOX = ${hex2(F.FONT_BOX)}`, `FONT_BTA = ${hex2(F.FONT_BTN.A)}`, `FONT_BTB = ${hex2(F.FONT_BTN.B)}`, `FONT_SQ = ${hex2(C['■'])}`, `FONT_UP = ${hex2(C['↑'])}`, `FONT_DN = ${hex2(C['↓'])}`, `FONT_PCT = ${hex2(C['%'])}`, `FONT_RPAR = ${hex2(C[')'])}`, `FONT_STAR = ${hex2(C['★'])}`, `FONT_ORD = ${hex2(C['º'])}`);
for (const ch of 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') inc.push(`FONT_L${ch} = ${hex2(C[ch])}`);
inc.push(`SPC_SIZE = ${spc.length}`);
inc.push(`NAME_POOL_START = ${poolStart}`, `NAME_POOL_N = ${POOL_N}`);
music.songs.forEach((s, i) => inc.push(`SONG_${s.name.toUpperCase()} = ${i}`));
music.sfx.forEach((s, i) => inc.push(`SFX_${s.name.toUpperCase()} = ${i}`));
w('assets.inc', inc.join('\n') + '\n');

const data = ['; gerado por build.js - nao editar'];
// os textos ficam num banco proprio (gen/textos.inc); PrintStr le desse banco
const textos = ['; gerado por build.js - nao editar'];
for (const [k, v] of Object.entries(T)) textos.push(`TXT_${k}:\n${byteLines(F.compile(v))}`);
w('textos.inc', textos.join('\n') + '\n');
// as trilhas ficam em outro banco (gen/musica.inc); as tabelas guardam so o endereco de 16 bits
const mus = ['; gerado por build.js - nao editar'];
music.songs.forEach((s) => s.tracks.forEach((t, c) => mus.push(`MUS_${s.name}_${c}:\n${byteLines(t)}`)));
data.push('SongTable:');
music.songs.forEach((s) => data.push(`  .word ${s.tracks.map((_, c) => `.loword(MUS_${s.name}_${c})`).join(', ')}`));
music.sfx.forEach((s) => mus.push(`SFXD_${s.name}:\n${byteLines(s.data)}`));
data.push('SfxTable:');
music.sfx.forEach((s) => data.push(`  .word .loword(SFXD_${s.name})`));
w('musica.inc', mus.join(String.fromCharCode(10)) + String.fromCharCode(10));
data.push('PitchTable:\n' + wordLines(AU.pitchTable()));
data.push('InstTable:');
AU.INSTR.forEach((i) => data.push(`  .byte ${i.map(hex2).join(',')}`));
// regras
data.push('ValueTab:\n' + wordLines(R.VALOR));
data.push('SalTab:\n' + wordLines(R.SALARIO));
data.push('QTab:\n' + byteLines(R.QGOL));
data.push('FixTab:\n' + byteLines(R.tabelaJogos().flat(2)));
data.push('DivTV:\n' + wordLines(R.DIV.cotaTV));
data.push('DivPub:\n' + wordLines(R.DIV.publico));
data.push('DivTicket:\n' + byteLines(R.DIV.ingresso));
data.push('DivCash:\n' + R.DIV.caixa.map((v) => `  .dword ${v}`).join('\n'));
data.push('DivBase:\n' + byteLines(R.DIV.base));
data.push('DivPrize:\n' + wordLines(R.DIV.premio));
data.push('CalTab:\n' + byteLines(R.CALENDARIO));
data.push('PulseTab:\n' + wordLines(UI.pulso()));
data.push('CupPrize:\n' + wordLines(R.PREMIO_COPA));
data.push('DivLoan:\n' + wordLines(R.EMPRESTIMO));
data.push('TeamBase:\n' + wordLines(Array.from({ length: 64 }, (_, t) => t * 26)));
data.push('PosChar:\n' + byteLines(['G', 'D', 'M', 'A'].map((c) => C[c])));
data.push('NameGrid:\n' + byteLines([...'ABCDEFGHIJKLMNOPQRSTUVWXYZ .←■'].map((c) => C[c])));
w('data.inc', data.join('\n') + '\n');

// ------------------------------------------------------------ montagem
const SRC = ['main.s', 'audio.s', 'util.s', 'mundo.s', 'partida.s', 'telas.s', 'menus.s', 'save.s'].map((f) => 'src/' + f);
try {
  execFileSync('python', [path.join('gerador', 'checa_largura.py'), ...SRC], { cwd: ROOT, stdio: 'inherit' });
} catch (e) { console.error('(verificador de largura indisponivel ou com avisos)'); }
const CC = path.join(ROOT, 'tools', 'cc65', 'bin');
const out = path.join(ROOT, 'SuperTecnico98.sfc');
try {
  execFileSync(path.join(CC, 'ca65'), ['--cpu', '65816', '-g', '-I', '.', '-o', 'gen/main.o', '-l', 'gen/main.lst', 'src/main.s'], { cwd: ROOT, stdio: 'inherit' });
  execFileSync(path.join(CC, 'ld65'), ['-C', 'src/snes.cfg', '-o', out, '-m', 'gen/map.txt', '-Ln', 'gen/labels.txt', 'gen/main.o'], { cwd: ROOT, stdio: 'inherit' });
} catch (e) { console.error('FALHA NA MONTAGEM'); process.exit(1); }

// checksum
const rom = fs.readFileSync(out);
rom.writeUInt16LE(0xFFFF, 0x7FDC); rom.writeUInt16LE(0x0000, 0x7FDE);
let sum = 0; for (const b of rom) sum = (sum + b) & 0xFFFF;
rom.writeUInt16LE(sum ^ 0xFFFF, 0x7FDC); rom.writeUInt16LE(sum, 0x7FDE);
fs.writeFileSync(out, rom);
console.log(`ROM gerada: ${out} (${rom.length} bytes, checksum ${hex4(sum)})`);
