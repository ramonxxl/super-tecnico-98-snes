// Instrumentos sintetizados (originais) convertidos em amostras BRR do SNES.
// Amostras afinadas tem periodo de 32 pontos (ou multiplo) para usar a mesma
// tabela de afinacao; bateria toca em altura fixa (32 kHz ou 16 kHz).
'use strict';

let seed = 1998;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF; return seed / 0x80000000; };
const TAU = 2 * Math.PI;

// ---------------------------------------------------------------- BRR
const pred = (f, p1, p2) => {
  if (f === 1) return p1 + ((-p1) >> 4);
  if (f === 2) return 2 * p1 + ((-3 * p1) >> 5) - p2 + (p2 >> 4);
  if (f === 3) return 2 * p1 + ((-13 * p1) >> 6) - p2 + ((3 * p2) >> 4);
  return 0;
};
const dec1 = (n, sh, f, p1, p2) => {
  let v = (n << sh) >> 1;
  v += pred(f, p1, p2);
  v = Math.max(-32768, Math.min(32767, v));
  return ((v & 0x7FFF) ^ 0x4000) - 0x4000;
};
// pcm: -1..1, tamanho multiplo de 16. loopBloco: bloco onde o loop comeca (ou null)
function brrEncode(pcm, loopBloco) {
  const alvo = pcm.map((v) => Math.max(-16000, Math.min(16000, Math.round(v * 15500))));
  const out = [];
  let p1 = 0, p2 = 0;
  const nb = alvo.length / 16;
  for (let b = 0; b < nb; b++) {
    const blk = alvo.slice(b * 16, b * 16 + 16);
    let best = null;
    const filtros = (b === 0 || b === loopBloco) ? [0] : [0, 1, 2, 3];
    for (const f of filtros) for (let sh = 0; sh <= 12; sh++) {
      let q1 = p1, q2 = p2, err = 0; const nib = [];
      for (const x of blk) {
        const pr = pred(f, q1, q2), passo = sh === 0 ? 0.5 : (1 << (sh - 1));
        let n = Math.max(-8, Math.min(7, Math.round((x - pr) / passo)));
        let y = dec1(n, sh, f, q1, q2);
        for (const m of [n - 1, n + 1]) {
          if (m < -8 || m > 7) continue;
          const z = dec1(m, sh, f, q1, q2);
          if (Math.abs(z - x) < Math.abs(y - x)) { n = m; y = z; }
        }
        err += (y - x) * (y - x); nib.push(n); q2 = q1; q1 = y;
        if (err > (best ? best.err : Infinity)) break;
      }
      if (nib.length === 16 && (!best || err < best.err)) best = { err, f, sh, nib, q1, q2 };
    }
    const fim = b === nb - 1;
    out.push((best.sh << 4) | (best.f << 2) | (fim ? (loopBloco != null ? 3 : 1) : 0));
    for (let i = 0; i < 16; i += 2) out.push(((best.nib[i] & 15) << 4) | (best.nib[i + 1] & 15));
    p1 = best.q1; p2 = best.q2;
  }
  return out;
}
function brrDecode(d) {
  const out = []; let p1 = 0, p2 = 0;
  for (let i = 0; i < d.length; i += 9) {
    const h = d[i], sh = h >> 4, f = (h >> 2) & 3;
    for (let k = 0; k < 16; k++) {
      const byte = d[i + 1 + (k >> 1)];
      let n = k & 1 ? byte & 15 : byte >> 4; if (n > 7) n -= 16;
      const v = dec1(n, sh, f, p1, p2);
      out.push(v / 16384); p2 = p1; p1 = v;
    }
  }
  return out;
}

// ---------------------------------------------------------------- utilitarios
const norm = (a, pico = 0.95) => { let m = 0; for (const v of a) m = Math.max(m, Math.abs(v)); return a.map((v) => v / m * pico); };
const pad16 = (a) => { while (a.length % 16) a.push(0); return a; };
// soma de harmonicos: amp(k) para k=1..kmax, fase 0, periodo P pontos
function harm(P, kmax, amp, i, ph = 0) { let v = 0; for (let k = 1; k <= kmax; k++) { const a = amp(k); if (a) v += a * Math.sin(TAU * k * (i + ph) / P); } return v; }
// harmonicos de uma forma de onda qualquer (1 ciclo de 1024 pontos) -> lista de [k, amp, fase]
function analisa(fn, kmax) {
  const N = 1024, x = Array.from({ length: N }, (_, i) => fn(i / N));
  const hs = [];
  for (let k = 1; k <= kmax; k++) {
    let re = 0, im = 0;
    for (let i = 0; i < N; i++) { re += x[i] * Math.cos(TAU * k * i / N); im += x[i] * Math.sin(TAU * k * i / N); }
    hs.push([k, Math.hypot(re, im) * 2 / N, Math.atan2(re, im)]);
  }
  return hs;
}
const sintetiza = (hs, P, i, peso = () => 1) => hs.reduce((s, [k, a, ph]) => s + a * peso(k) * Math.sin(TAU * k * i / P + ph), 0);

// ---------------------------------------------------------------- instrumentos afinados
// metais de sintetizador: dois serrotes levemente desafinados, brilho que abre no ataque
function metais() {
  const ATQ = 1024, LOOP = 2048, P = 32;
  const a = [];
  for (let i = 0; i < ATQ + LOOP; i++) {
    const t = Math.min(1, i / 700);
    const kc = 2 + 5 * t;                               // corte do "filtro"
    const amp = (k) => (1 / k) / (1 + Math.pow(k / kc, 2));
    const v1 = harm(P, 15, amp, i);
    const v2 = harm(LOOP / 65, 15, amp, i);             // 65 ciclos no loop = coro
    a.push(v1 + 0.55 * v2);
  }
  return { pcm: norm(a, 0.8), loop: ATQ / 16 };
}
// baixo eletrico (periodo 64): beliscada brilhante que escurece
function baixo() {
  const ATQ = 1536, LOOP = 1024, P = 64;
  const a = [];
  for (let i = 0; i < ATQ + LOOP; i++) {
    const t = Math.min(1, i / ATQ);
    const brilho = 1 - 0.75 * t;
    a.push(harm(P, 24, (k) => Math.pow(k, -1.6) * Math.pow(brilho, k - 1) * (k === 2 ? 1.3 : 1), i));
  }
  return { pcm: norm(a, 0.9), loop: ATQ / 16 };
}
// guitarra: acorde de quinta (fundamental + quinta + oitava) com distorcao, periodo 128
function guitarra() {
  const P = 128, ATQ = 512, LOOP = 1024;
  const onda = (x) => {
    const s = (f) => { const p = (x * f) % 1; return 2 * p - 1; };      // serrote
    const v = s(2) + 0.8 * s(3) + 0.5 * s(4);                            // 2:3:4 = fundamental, quinta, oitava
    return Math.tanh(2.2 * v);
  };
  const hs = analisa(onda, 60).filter(([k]) => k * 32000 / P < 15000);
  const a = [];
  for (let i = 0; i < ATQ + LOOP; i++) {
    const palheta = i < 48 ? (rnd() * 2 - 1) * (1 - i / 48) * 0.6 : 0;
    a.push(sintetiza(hs, P, i, (k) => 1 / (1 + Math.pow(k / 40, 2))) + palheta);
  }
  return { pcm: norm(a, 0.85), loop: ATQ / 16 };
}
// piano eletrico (FM): sino suave
function epiano() {
  const P = 32, ATQ = 2048, LOOP = 1024;
  const a = [];
  for (let i = 0; i < ATQ + LOOP; i++) {
    const idx = 0.35 + 1.6 * Math.exp(-Math.min(i, ATQ) / 500);
    const x = TAU * i / P;
    a.push(Math.sin(x + idx * Math.sin(x)) + 0.15 * Math.sin(2 * x));
  }
  // o indice de modulacao fica constante no loop (periodico)
  return { pcm: norm(a, 0.8), loop: ATQ / 16 };
}

// ---------------------------------------------------------------- bateria (altura fixa)
function bumbo() {     // 16 kHz
  const R = 16000, n = 3520, a = [];
  let fase = 0;
  for (let i = 0; i < n; i++) {
    const t = i / R, f = 48 + 110 * Math.exp(-t / 0.035);
    fase += TAU * f / R;
    const click = i < 40 ? (rnd() * 2 - 1) * (1 - i / 40) * 0.5 : 0;
    a.push(Math.sin(fase) * Math.exp(-t / 0.12) + click);
  }
  return { pcm: pad16(norm(a, 0.95)), loop: null };
}
function caixa() {     // 16 kHz
  const R = 16000, n = 2880, a = [];
  let lp = 0, hp = 0, prev = 0;
  for (let i = 0; i < n; i++) {
    const t = i / R;
    const r = rnd() * 2 - 1;
    lp += 0.55 * (r - lp);                    // tira o chiado de cima
    hp = lp - prev; prev = lp;                // tira o grave
    const corpo = Math.sin(TAU * 185 * t) * Math.exp(-t / 0.045) * 0.9;
    a.push(corpo + hp * 1.6 * Math.exp(-t / 0.075));
  }
  return { pcm: pad16(norm(a, 0.9)), loop: null };
}
function chimbal() {   // 32 kHz
  const R = 32000, n = 1600, a = [];
  let prev = 0, lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / R, r = rnd() * 2 - 1;
    lp += 0.7 * (r - lp);
    const hp = lp - prev; prev = lp;
    a.push(hp * Math.exp(-t / 0.018));
  }
  return { pcm: pad16(norm(a, 0.7)), loop: null };
}
function tom() {       // 16 kHz
  const R = 16000, n = 4000, a = [];
  let fase = 0;
  for (let i = 0; i < n; i++) {
    const t = i / R, f = 95 + 70 * Math.exp(-t / 0.08);
    fase += TAU * f / R;
    a.push(Math.sin(fase) * Math.exp(-t / 0.18));
  }
  return { pcm: pad16(norm(a, 0.9)), loop: null };
}


// baixo slap (periodo 64): estalo forte e brilho que cai rapido
function slap() {
  const ATQ = 1024, LOOP = 1024, P = 64;
  const a = [];
  for (let i = 0; i < ATQ + LOOP; i++) {
    const t = Math.min(1, i / ATQ);
    const brilho = 0.9 * Math.exp(-4 * t) + 0.25;
    let v = harm(P, 28, (k) => Math.pow(k, -1.1) * Math.pow(brilho, (k - 1) * 0.6) * (k === 1 ? 1.4 : 1), i);
    if (i < 96) v += (rnd() * 2 - 1) * (1 - i / 96) * 0.8;          // estalo da corda
    a.push(Math.tanh(1.6 * v));
  }
  return { pcm: norm(a, 0.9), loop: ATQ / 16 };
}
// cordas de sintetizador: tres serrotes desafinados, abafados (loop de 2048 = coro)
function cordas() {
  const P = 32, LOOP = 2048;
  const amp = (k) => (1 / k) / (1 + Math.pow(k / 4, 2));
  const a = [];
  for (let i = 0; i < LOOP; i++) a.push(harm(P, 15, amp, i) + 0.7 * harm(LOOP / 65, 15, amp, i) + 0.7 * harm(LOOP / 63, 15, amp, i));
  return { pcm: norm(a, 0.8), loop: 0 };
}
// prato de ataque (16 kHz): ruido escuro com cauda longa
function prato() {
  const R = 16000, n = 9600, a = [];
  let lp = 0, prev = 0, lp2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / R, r = rnd() * 2 - 1;
    lp += 0.45 * (r - lp);
    const hp = lp - prev; prev = lp;
    lp2 += 0.6 * (hp - lp2);
    a.push(lp2 * (Math.exp(-t / 0.28) * 0.85 + 0.15 * Math.exp(-t / 0.04)));
  }
  return { pcm: pad16(norm(a, 0.6)), loop: null };
}

// ---------------------------------------------------------------- ondas simples (efeitos)
function ciclo(fn, amp = 0.75) { return { pcm: Array.from({ length: 32 }, (_, i) => fn((i + 0.5) / 32) * amp), loop: 0 }; }
const SIMPLES = {
  quadrada: ciclo((x) => (x < 0.5 ? 0.6 : -0.6)),
  triangulo: ciclo((x) => (x < 0.5 ? 4 * x - 1 : 3 - 4 * x)),
  pulso: ciclo((x) => (x < 0.25 ? 0.6 : -0.6)),
  seno: ciclo((x) => Math.sin(TAU * x)),
  serra: ciclo((x) => (Math.sin(TAU * x) + Math.sin(2 * TAU * x) / 2 + Math.sin(3 * TAU * x) / 3) / 1.5),
};

// lista final (a ordem define o numero da amostra)
function amostras() {
  const lista = [
    ['quadrada', SIMPLES.quadrada], ['triangulo', SIMPLES.triangulo], ['pulso', SIMPLES.pulso],
    ['seno', SIMPLES.seno], ['serra', SIMPLES.serra],
    ['metais', metais()], ['baixo', baixo()], ['guitarra', guitarra()], ['epiano', epiano()],
    ['bumbo', bumbo()], ['caixa', caixa()], ['chimbal', chimbal()], ['tom', tom()],
    ['slap', slap()], ['cordas', cordas()], ['prato', prato()],
  ];
  return lista.map(([nome, s]) => ({ nome, pcm: s.pcm, loop: s.loop, brr: brrEncode(s.pcm, s.loop) }));
}

module.exports = { amostras, brrEncode, brrDecode };
