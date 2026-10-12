// Utilitarios de imagem / conversao para formatos do SNES
'use strict';
const zlib = require('zlib');

function hex(c) { return [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)]; }
function bgr555(c) { const [r, g, b] = hex(c); return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10); }
function palBytes(colors) {
  const out = Buffer.alloc(32);
  for (let i = 0; i < 16; i++) out.writeUInt16LE(colors[i] ? bgr555(colors[i]) : 0, i * 2);
  return out;
}

class Img {
  constructor(w, h, fill = 0) { this.w = w; this.h = h; this.p = new Uint8Array(w * h).fill(fill); }
  set(x, y, c) { x |= 0; y |= 0; if (x >= 0 && y >= 0 && x < this.w && y < this.h) this.p[y * this.w + x] = c; }
  get(x, y) { return (x >= 0 && y >= 0 && x < this.w && y < this.h) ? this.p[y * this.w + x] : 0; }
  rect(x, y, w, h, c) { for (let j = y; j < y + h; j++) for (let i = x; i < x + w; i++) this.set(i, j, c); }
  hline(x, y, w, c) { this.rect(x, y, w, 1, c); }
  vline(x, y, h, c) { this.rect(x, y, 1, h, c); }
  frame(x, y, w, h, c) { this.hline(x, y, w, c); this.hline(x, y + h - 1, w, c); this.vline(x, y, h, c); this.vline(x + w - 1, y, h, c); }
  // elipse preenchida dentro do retangulo [x0..x1]x[y0..y1]
  ell(x0, y0, x1, y1, c, pred) {
    const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2, rx = (x1 - x0) / 2 + 0.5, ry = (y1 - y0) / 2 + 0.5;
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
      const dx = (x - cx) / rx, dy = (y - cy) / ry;
      if (dx * dx + dy * dy <= 1.0 && (!pred || pred(x, y))) this.set(x, y, c);
    }
  }
  // desenha arte em texto; map: char -> cor (char ausente / '.' = ignorar)
  art(rows, x, y, map) {
    rows.forEach((r, j) => { for (let i = 0; i < r.length; i++) { const ch = r[i]; if (ch in map) this.set(x + i, y + j, map[ch]); } });
  }
  // contorno: pixels vazios vizinhos (4-viz) de pixels preenchidos viram c
  outline(c, region) {
    const src = this.p.slice();
    const g = (x, y) => (x >= 0 && y >= 0 && x < this.w && y < this.h) ? src[y * this.w + x] : 0;
    for (let y = 0; y < this.h; y++) for (let x = 0; x < this.w; x++) {
      if (region && !region(x, y)) continue;
      if (src[y * this.w + x] === 0 && (g(x - 1, y) || g(x + 1, y) || g(x, y - 1) || g(x, y + 1))) this.p[y * this.w + x] = c;
    }
  }
  // sombreia a borda direita de uma cor
  shadeRight(col, shade, depth = 2) {
    const src = this.p.slice();
    for (let y = 0; y < this.h; y++) for (let x = 0; x < this.w; x++) {
      if (src[y * this.w + x] !== col) continue;
      for (let d = 1; d <= depth; d++) { const xx = x + d; if (xx >= this.w || src[y * this.w + xx] !== col) { this.p[y * this.w + x] = shade; break; } }
    }
  }
  sub(x, y, w, h) { const o = new Img(w, h); for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) o.p[j * w + i] = this.get(x + i, y + j); return o; }
  paste(src, x, y) { for (let j = 0; j < src.h; j++) for (let i = 0; i < src.w; i++) { const c = src.p[j * src.w + i]; if (c) this.set(x + i, y + j, c); } }
}

// ---------- tiles ----------
function tilePixels(img, tx, ty) { const a = new Array(64); for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) a[y * 8 + x] = img.get(tx * 8 + x, ty * 8 + y); return a; }
function enc4(px) {
  const b = Buffer.alloc(32);
  for (let y = 0; y < 8; y++) {
    let p0 = 0, p1 = 0, p2 = 0, p3 = 0;
    for (let x = 0; x < 8; x++) {
      const c = px[y * 8 + x], bit = 7 - x;
      p0 |= (c & 1) << bit; p1 |= ((c >> 1) & 1) << bit; p2 |= ((c >> 2) & 1) << bit; p3 |= ((c >> 3) & 1) << bit;
    }
    b[y * 2] = p0; b[y * 2 + 1] = p1; b[16 + y * 2] = p2; b[16 + y * 2 + 1] = p3;
  }
  return b;
}
function enc2(px) {
  const b = Buffer.alloc(16);
  for (let y = 0; y < 8; y++) {
    let p0 = 0, p1 = 0;
    for (let x = 0; x < 8; x++) { const c = px[y * 8 + x], bit = 7 - x; p0 |= (c & 1) << bit; p1 |= ((c >> 1) & 1) << bit; }
    b[y * 2] = p0; b[y * 2 + 1] = p1;
  }
  return b;
}
function flipH(px) { const o = new Array(64); for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) o[y * 8 + x] = px[y * 8 + 7 - x]; return o; }
function flipV(px) { const o = new Array(64); for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) o[y * 8 + x] = px[(7 - y) * 8 + x]; return o; }

// Converte cena 256x224 em tiles 4bpp + mapa 32x32 (com deduplicacao e flips)
function sceneToBG(img, palIdx, prioFn) {
  const tiles = [], dict = new Map(), map = Buffer.alloc(2048);
  const add = (px) => {
    const k = px.join(',');
    if (dict.has(k)) return dict.get(k);
    const id = tiles.length; tiles.push(enc4(px));
    dict.set(k, { id, f: 0 });
    const h = flipH(px).join(','), v = flipV(px).join(','), hv = flipV(flipH(px)).join(',');
    if (!dict.has(h)) dict.set(h, { id, f: 1 });
    if (!dict.has(v)) dict.set(v, { id, f: 2 });
    if (!dict.has(hv)) dict.set(hv, { id, f: 3 });
    return { id, f: 0 };
  };
  add(new Array(64).fill(0)); // tile 0 vazio
  for (let ty = 0; ty < img.h / 8; ty++) for (let tx = 0; tx < 32; tx++) {
    const t = add(tilePixels(img, tx, ty));
    let e = t.id | (palIdx << 10) | ((t.f & 1) << 14) | ((t.f & 2) << 14);
    if (prioFn && prioFn(tx, ty)) e |= 0x2000;
    map.writeUInt16LE(e, (ty * 32 + tx) * 2);
  }
  if (tiles.length > 1024) throw new Error('cena com tiles demais: ' + tiles.length);
  return { tiles: Buffer.concat(tiles), map, count: tiles.length };
}

// ---------- PNG (preview) ----------
const crcT = (() => { const t = []; for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
function crc32(buf) { let c = 0xffffffff; for (const b of buf) c = crcT[(c ^ b) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
function chunk(type, data) { const l = Buffer.alloc(4); l.writeUInt32BE(data.length); const td = Buffer.concat([Buffer.from(type), data]); const c = Buffer.alloc(4); c.writeUInt32BE(crc32(td)); return Buffer.concat([l, td, c]); }
function png(img, palettes, scale = 2) {
  // palettes: array de arrays de cores hex; img.p guarda (pal<<4)|cor
  const W = img.w * scale, H = img.h * scale, raw = Buffer.alloc((W * 3 + 1) * H);
  for (let y = 0; y < H; y++) {
    raw[y * (W * 3 + 1)] = 0;
    for (let x = 0; x < W; x++) {
      const v = img.p[((y / scale) | 0) * img.w + ((x / scale) | 0)];
      const pal = palettes[v >> 4] || palettes[0], c = (v & 15) ? pal[v & 15] : '#ff00ff';
      const [r, g, b] = hex(c || '#ff00ff'); const o = y * (W * 3 + 1) + 1 + x * 3; raw[o] = r; raw[o + 1] = g; raw[o + 2] = b;
    }
  }
  const ih = Buffer.alloc(13); ih.writeUInt32BE(W, 0); ih.writeUInt32BE(H, 4); ih[8] = 8; ih[9] = 2;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ih), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

module.exports = { Img, bgr555, palBytes, enc4, enc2, tilePixels, sceneToBG, png, hex };
