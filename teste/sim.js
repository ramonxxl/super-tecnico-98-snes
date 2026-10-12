// Simulador de calibracao: mesmas contas inteiras do assembly, temporadas inteiras.
// Uso: node teste/sim.js [temporadas]
'use strict';
const R = require('../gerador/regras');
const E = require('../elenco.json');
let rng = 0xACE1;
function rand16() { rng = (rng >>> 1) ^ ((rng & 1) ? 0xB400 : 0); return rng; }
const randBelow = (n) => { rand16(); rand16(); return ((rng & 0xFF) * n) >> 8; };
const rand4096 = () => { rand16(); return rng & 4095; };

function escalar(time) {
  const disp = time.jogadores.filter((j) => j.fora === 0);
  const por = (p) => disp.filter((j) => j.pos === p).sort((a, b) => b.forca - a.forca);
  const tit = [...por('G').slice(0, 1), ...por('D').slice(0, 4), ...por('M').slice(0, 4), ...por('A').slice(0, 2)];
  return tit;
}
function forcas(tit, estilo = 1) {
  let atk = 0, mid = 0, def = 0, gk = 0;
  for (const j of tit) { if (j.pos === 'A') atk += j.forca; else if (j.pos === 'M') mid += j.forca; else if (j.pos === 'D') def += j.forca; else gk = j.forca; }
  if (!gk) gk = 3;
  let A = atk + (mid >> 1), D = def + (mid >> 1) + gk * 2;
  if (estilo === 2) { A += A >> 2; D -= D >> 3; } else if (estilo === 0) { A -= A >> 2; D += D >> 2; }
  return { A, D };
}
function q(Fa, Fd, casa) {
  let r = Math.floor(Fa.A * 128 / Math.max(1, Fd.D)); if (r > 255) r = 255;
  let v = R.QGOL[r]; if (casa) v += v >> 2; else v -= v >> 3; return v;
}
function jogo(h, a) {
  const th = escalar(h), ta = escalar(a);
  const fh = forcas(th), fa = forcas(ta);
  const qh = q(fh, fa, true), qa = q(fa, fh, false);
  let gh = 0, ga = 0;
  for (let m = 0; m < 90; m++) { if (rand4096() < qh) gh++; if (rand4096() < qa) ga++; }
  return [gh, ga];
}

function temporada(divs) {
  const fix = R.tabelaJogos();
  const st = { gols: 0, jogos: 0, casa: 0, emp: 0, fora: 0, zebras: 0 };
  for (const d of divs) {
    for (const t of d) { t.pts = 0; t.sg = 0; t.gp = 0; }
    for (let r = 0; r < 30; r++) for (const [x, y] of fix[r % 15]) {
      const [hi, ai] = r >= 15 ? [y, x] : [x, y];
      const h = d[hi], a = d[ai];
      const [gh, ga] = jogo(h, a);
      st.gols += gh + ga; st.jogos++;
      h.gp += gh; a.gp += ga; h.sg += gh - ga; a.sg += ga - gh;
      if (gh > ga) { h.pts += 3; st.casa++; } else if (gh < ga) { a.pts += 3; st.fora++; } else { h.pts++; a.pts++; st.emp++; }
      if ((gh > ga && h.media + 4 < a.media) || (ga > gh && a.media + 4 < h.media)) st.zebras++;
    }
    d.sort((a, b) => b.pts - a.pts || b.sg - a.sg || b.gp - a.gp);
  }
  return st;
}

const N = +process.argv[2] || 20;
const divs = [0, 1, 2, 3].map((k) => E.clubes.slice(k * 16, k * 16 + 16).map((c) => ({
  nome: c.nome, media: c.jogadores.reduce((s, j) => s + j.forca, 0) / 22,
  jogadores: c.jogadores.map((j) => ({ ...j, fora: 0 })) })));
let tot = { gols: 0, jogos: 0, casa: 0, emp: 0, fora: 0, zebras: 0 };
const campeoes = {};
for (let s = 0; s < N; s++) {
  const st = temporada(divs);
  for (const k in tot) tot[k] += st[k];
  divs.forEach((d, i) => { const k = 'ABCD'[i] + ':' + d[0].nome; campeoes[k] = (campeoes[k] || 0) + 1; });
}
console.log(`media de gols ${(tot.gols / tot.jogos).toFixed(2)}  casa ${(100 * tot.casa / tot.jogos).toFixed(0)}%  empate ${(100 * tot.emp / tot.jogos).toFixed(0)}%  fora ${(100 * tot.fora / tot.jogos).toFixed(0)}%  zebras ${(100 * tot.zebras / tot.jogos).toFixed(1)}%`);
console.log('campeoes:', Object.entries(campeoes).sort((a, b) => b[1] - a[1]).slice(0, 12).map(([k, v]) => `${k} ${v}`).join(', '));
const ult = divs.map((d) => d.map((t) => `${t.nome} ${t.pts}`).join(' | '));
console.log('ultima tabela A:', ult[0]);

// financas de um time medio em cada divisao (por temporada, R$ mil)
for (let d = 0; d < 4; d++) {
  const c = E.clubes[d * 16 + 8];
  const sal = c.jogadores.reduce((s, j) => s + R.SALARIO[j.forca], 0);
  const pub = Math.min(c.capacidade, Math.floor(R.DIV.publico[d] * c.fama / 5));
  const bil = Math.floor(pub * R.DIV.ingresso[d] / 1000);
  const rec = 30 * R.DIV.cotaTV[d] + 15 * bil, desp = 30 * sal;
  const valorTime = c.jogadores.reduce((s, j) => s + R.VALOR[j.forca], 0);
  console.log(`div ${'ABCD'[d]} ${c.nome}: salarios/rod ${sal}  publico ${pub}  bilheteria ${bil}  receita ${rec}  despesa ${desp}  saldo ${rec - desp}  caixa inicial ${R.DIV.caixa[d]}  valor elenco ${valorTime}  craque ${R.VALOR[Math.max(...c.jogadores.map((j) => j.forca))]}`);
}
