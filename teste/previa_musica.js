// Previa das musicas em WAV: simula no PC o tocador do jogo (eventos por quadro de 60 Hz)
// e o DSP do SNES de forma aproximada (amostras BRR decodificadas, afinacao, ADSR, volume).
// Uso: node teste/previa_musica.js   -> teste/musica_<nome>.wav
'use strict';
const fs = require('fs'), path = require('path');
const A = require('../gerador/audio');
const I = require('../gerador/instrumentos');

const RATE = 32000, SPF = RATE / 60;
const amostras = A.amostrasUsadas().map((s) => ({ pcm: I.brrDecode(s.brr), loop: s.loop != null ? s.loop * 16 : null }));
const pitch = A.pitchTable();
const AR = [4100, 2600, 1500, 1000, 640, 380, 260, 160, 96, 64, 40, 24, 16, 10, 6, 0];
const DR = [1200, 740, 440, 290, 180, 110, 74, 37];
const SR = [Infinity, 38000, 28000, 24000, 19000, 14000, 12000, 9400, 7100, 5900, 4700, 3500, 2900, 2400, 1800, 1500,
  1200, 880, 740, 590, 440, 370, 290, 220, 180, 150, 110, 92, 74, 55, 37, 18];

function render(song, segundos) {
  const N = Math.round(segundos * RATE), L = new Float32Array(N), R = new Float32Array(N);
  const vozes = song.tracks.map((t) => ({ t, ptr: 0, loop: 0, wait: 0, on: true, inst: 0, vl: 0, vr: 0,
    smp: null, pos: 0, step: 0, env: 0, fase: 'off', tr: 0 }));
  const setInst = (v, n) => { v.inst = A.INSTR[n]; v.tr = v.inst[3]; };
  const ler = (v) => {
    for (;;) {
      const c = v.t[v.ptr++];
      if (c === 0xF0) { setInst(v, v.t[v.ptr++]); continue; }
      if (c === 0xF1) { v.vl = v.vr = v.t[v.ptr++] / 128; continue; }
      if (c === 0xF2) { v.vl = v.t[v.ptr++] / 128; v.vr = v.t[v.ptr++] / 128; continue; }
      if (c === 0xFD) { v.loop = v.ptr; continue; }
      if (c === 0xFE) { v.ptr = v.loop; continue; }
      if (c === 0xFF) { v.on = false; v.fase = 'rel'; return; }
      v.wait = v.t[v.ptr++];
      if (c === 0) { v.fase = v.fase === 'off' ? 'off' : 'rel'; return; }
      const [smp, a1, a2] = v.inst;
      v.smp = amostras[smp]; v.pos = 0;
      const p = v.tr & 0x80 ? (v.tr & 1 ? 0x800 : 0x1000) : pitch[c + v.tr];
      v.step = p / 4096;
      v.ar = AR[a1 & 15]; v.dr = DR[(a1 >> 4) & 7]; v.sl = ((a2 >> 5) + 1) / 8; v.sr = SR[a2 & 31];
      v.env = 0; v.fase = 'atq';
      return;
    }
  };
  for (const v of vozes) v.loop = 0;
  let s = 0;
  while (s < N) {
    for (const v of vozes) { if (!v.on) continue; if (v.wait > 0 && --v.wait > 0) continue; ler(v); }
    const fim = Math.min(N, Math.round(s + SPF));
    for (; s < fim; s++) {
      let l = 0, r = 0;
      for (const v of vozes) {
        if (v.fase === 'off' || !v.smp) continue;
        // envelope
        const dt = 1000 / RATE;
        if (v.fase === 'atq') { v.env += v.ar ? dt / v.ar : 1; if (v.env >= 1) { v.env = 1; v.fase = 'dec'; } }
        else if (v.fase === 'dec') { v.env -= (1 - v.sl) * dt / v.dr * 3; if (v.env <= v.sl) { v.env = v.sl; v.fase = 'sus'; } }
        else if (v.fase === 'sus') { if (v.sr !== Infinity) v.env *= Math.exp(-dt / v.sr * 5); }
        else if (v.fase === 'rel') { v.env -= dt / 8; if (v.env <= 0) { v.env = 0; v.fase = 'off'; continue; } }
        // amostra com interpolacao linear
        const pcm = v.smp.pcm, i = Math.floor(v.pos), f = v.pos - i;
        const a = pcm[i] || 0, b = pcm[i + 1 < pcm.length ? i + 1 : (v.smp.loop ?? i)] || 0;
        const x = (a + (b - a) * f) * v.env;
        l += x * v.vl; r += x * v.vr;
        v.pos += v.step;
        if (v.pos >= pcm.length) { if (v.smp.loop != null) v.pos = v.smp.loop + (v.pos - pcm.length); else { v.fase = 'off'; } }
      }
      L[s] = l * 0.9; R[s] = r * 0.9;
    }
  }
  return [L, R];
}

function wav([L, R]) {
  const n = L.length, b = Buffer.alloc(44 + n * 4);
  b.write('RIFF', 0); b.writeUInt32LE(36 + n * 4, 4); b.write('WAVEfmt ', 8); b.writeUInt32LE(16, 16);
  b.writeUInt16LE(1, 20); b.writeUInt16LE(2, 22); b.writeUInt32LE(RATE, 24); b.writeUInt32LE(RATE * 4, 28);
  b.writeUInt16LE(4, 32); b.writeUInt16LE(16, 34); b.write('data', 36); b.writeUInt32LE(n * 4, 40);
  let pico = 0;
  for (let i = 0; i < n; i++) pico = Math.max(pico, Math.abs(L[i]), Math.abs(R[i]));
  for (let i = 0; i < n; i++) {
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i])) * 30000), 44 + i * 4);
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i])) * 30000), 46 + i * 4);
  }
  return { b, pico };
}

const { songs } = A.musicData();
const dur = { titulo: 45, menu: 32, vitoria: 4, derrota: 4 };
for (const s of songs) {
  const { b, pico } = wav(render(s, dur[s.name] || 10));
  const out = path.join(__dirname, `musica_${s.name}.wav`);
  fs.writeFileSync(out, b);
  console.log(`${out}  pico ${pico.toFixed(2)}${pico > 1 ? ' (ESTOURA)' : ''}`);
}
