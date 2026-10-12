# Trailer (MP4 1920x1080) do Super Tecnico 98 com cenas reais do jogo, a musica do jogo e narracao.
# Antes: gravar quadros (teste/grava.lua -> trailer/quadros), node teste/previa_musica.js, python gerador/capa.py e cartucho.py
# Uso: python gerador/trailer.py
import os, math, subprocess, wave, asyncio
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import imageio_ffmpeg

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TR = os.path.join(ROOT, 'trailer'); Q = os.path.join(TR, 'quadros'); AU = os.path.join(TR, 'audio')
os.makedirs(AU, exist_ok=True)
FF = imageio_ffmpeg.get_ffmpeg_exe()
W, H, FPS, RATE = 1920, 1080, 30, 32000
F = 'C:/Windows/Fonts/'
VERDE, VERDE2, AMARELO, BRANCO, ESCURO = (11, 61, 30), (30, 140, 60), (248, 208, 32), (255, 255, 255), (10, 14, 10)
def fonte(n, t): return ImageFont.truetype(F + n, t)

# ------------------------------------------------------------------ narracao
VOZ = 'pt-BR-AntonioNeural'
FALAS = [
    ('v1', 'Todo grande técnico começa de baixo.'),
    ('v2', 'Super Técnico 98! Um gerenciador de futebol de verdade, para o seu Super Nintendo!'),
    ('v3', 'Sessenta e quatro clubes do futebol brasileiro, da Série D até a Série A.'),
    ('v4', 'Acompanhe a rodada ao vivo, minuto a minuto: gols, pênaltis, cartões e substituições!'),
    ('v5', 'Escale o time, cuide da moral e escolha o treino.'),
    ('v6', 'Negocie como no velho Elifoot: proposta, contraproposta... e o craque é seu!'),
    ('v7', 'Dispute a Copa do Brasil, amplie o estádio e não deixe o caixa no vermelho.'),
    ('v9', 'Cumpra a meta da diretoria, ganhe reputação e receba convites de clubes maiores!'),
    ('v8', 'Super Técnico 98. O técnico é você!'),
]
def gera_vozes():
    import edge_tts
    async def main():
        for nome, texto in FALAS:
            arq = os.path.join(AU, nome + '.mp3')
            if not os.path.exists(arq):
                await edge_tts.Communicate(texto, VOZ, rate='+6%').save(arq)
    asyncio.run(main())

def dur_mp3(arq):
    p = subprocess.run([FF, '-i', arq], capture_output=True, text=True)
    for ln in p.stderr.splitlines():
        if 'Duration' in ln:
            h, m, s = ln.split('Duration:')[1].split(',')[0].strip().split(':'); return int(h) * 3600 + int(m) * 60 + float(s)
    return 3.0

# ------------------------------------------------------------------ quadros gravados (indice: n tela minuto brilho)
def indice(nome):
    out = []
    for ln in open(os.path.join(Q, nome + '.txt')):
        n, sc, mi, br = map(int, ln.split()); out.append((n, sc, mi, br))
    return out
IA, IB = indice('a'), indice('b')
def sel(idx, nome, telas, ini=0, maxn=None, pula=14):
    # pula o comeco de cada trecho (ainda mostra a tela anterior durante a transicao)
    fs, ant, k = [], None, 0
    for (n, sc, mi, br) in idx:
        if sc != ant: ant, k = sc, 0
        k += 1
        if sc in telas and br >= 15 and k > pula:
            fs.append(os.path.join(Q, f'{nome}_{n:05d}.png'))
    fs = fs[ini:]
    return fs[:maxn] if maxn else fs
CLIPES = {
    'titulo': sel(IA, 'a', {1}),
    'escolha': sel(IA, 'a', {4}),
    'jogo': sel(IA, 'a', {6}, 60),
    'elenco': sel(IA, 'a', {11}) + sel(IA, 'a', {21}),
    'negocia': sel(IB, 'b', {20}),
    'copa': sel(IA, 'a', {22}) + sel(IA, 'a', {15}),
    'carreira': sel(IA, 'a', {12}) + sel(IA, 'a', {23}),
}

# ------------------------------------------------------------------ elementos visuais
def fundo(t, escuro=False):
    im = Image.new('RGB', (W, H), VERDE if not escuro else (6, 20, 10))
    d = ImageDraw.Draw(im)
    cx, cy, a0 = W // 2, H // 2, t * 0.15
    cor = VERDE2 if not escuro else (14, 44, 22)
    for k in range(24):
        a = a0 + 2 * math.pi * k / 24; b = a + math.pi / 24
        d.polygon([(cx, cy), (cx + 2400 * math.cos(a), cy + 2400 * math.sin(a)), (cx + 2400 * math.cos(b), cy + 2400 * math.sin(b))], fill=cor)
    return im
def tela_jogo(arq, escala=4):
    g = Image.open(arq).convert('RGB').resize((256 * escala, 224 * escala), Image.NEAREST)
    b = 10
    q = Image.new('RGB', (g.width + 2 * b, g.height + 2 * b), AMARELO); q.paste(g, (b, b))
    q2 = Image.new('RGB', (q.width + 8, q.height + 8), ESCURO); q2.paste(q, (4, 4))
    return q2
def sombra(base, im, xy, r=18):
    s = Image.new('RGBA', (im.width + 80, im.height + 80), (0, 0, 0, 0))
    ImageDraw.Draw(s).rectangle([40, 40, 40 + im.width, 40 + im.height], fill=(0, 0, 0, 140))
    s = s.filter(ImageFilter.GaussianBlur(r))
    base.paste(s, (xy[0] - 26, xy[1] - 22), s)
    base.paste(im, xy)
def texto_capa(d, xy, txt, tam, cor=AMARELO, borda=10, centro=False):
    f = fonte('impact.ttf', tam)
    x, y = xy
    if centro: x = W / 2 - d.textlength(txt, font=f) / 2
    for k in range(8, 0, -1):
        d.text((x + k * 0.6, y + k), txt, font=f, fill=(150, 20, 10), stroke_width=borda, stroke_fill=ESCURO)
    d.text((x, y), txt, font=f, fill=cor, stroke_width=borda, stroke_fill=ESCURO)
def entra(t, dur=0.35):
    x = max(0.0, min(1.0, t / dur)); return 1 - (1 - x) ** 3

CAPA = Image.open(os.path.join(ROOT, 'cartucho', 'arte', 'capa.png')).convert('RGB')
ETIQ = Image.open(os.path.join(ROOT, 'cartucho', 'etiqueta_formato_classico.png')).convert('RGBA')
def cartucho(larg=900):
    h = int(larg * 0.72)
    c = Image.new('RGBA', (larg, h), (0, 0, 0, 0)); d = ImageDraw.Draw(c)
    d.rounded_rectangle([0, 0, larg - 1, h - 1], radius=40, fill=(150, 150, 156), outline=(70, 70, 76), width=6)
    for k in range(6):
        y = h - 70 + k * 10
        d.line([(60, y), (larg - 60, y)], fill=(110, 110, 116), width=4)
    e = ETIQ.copy(); e.thumbnail((int(larg * 0.84), int(h * 0.72)))
    c.alpha_composite(e, ((larg - e.width) // 2, 40))
    return c

# ------------------------------------------------------------------ cenas
def cena_jogo(clipe, legenda, sub=None):
    fs = CLIPES[clipe]
    def quadro(i, t):
        im = fundo(t)
        g = tela_jogo(fs[i % len(fs)], 4)
        sombra(im, g, (70, (H - g.height) // 2))
        d = ImageDraw.Draw(im)
        x0 = int(1150 + (1 - entra(t)) * 600)
        y = 320
        for ln in legenda.split('\n'):
            texto_capa(d, (x0, y), ln, 96); y += 120
        if sub:
            d.text((x0 + 6, y + 20), sub, font=fonte('seguibl.ttf', 38), fill=BRANCO, stroke_width=4, stroke_fill=ESCURO)
        return im
    return quadro
def cena_titulo():
    fs = CLIPES['titulo']
    def quadro(i, t):
        im = Image.new('RGB', (W, H), (4, 6, 16))
        g = Image.open(fs[min(i, len(fs) - 1)]).convert('RGB').resize((1152, 1008), Image.NEAREST)
        im.paste(g, ((W - 1152) // 2, 36))
        return im
    return quadro
def cena_capa():
    def quadro(i, t):
        im = fundo(t)
        k = entra(t, 0.6)
        alt = int(980 * (1.25 - 0.25 * k))
        cap = CAPA.resize((int(CAPA.width * alt / CAPA.height), alt), Image.LANCZOS)
        q = Image.new('RGB', (cap.width + 16, cap.height + 16), AMARELO); q.paste(cap, (8, 8))
        sombra(im, q, ((W - q.width) // 2, (H - q.height) // 2))
        if t > 1.2:
            d = ImageDraw.Draw(im)
            f = fonte('seguibl.ttf', 46); txt = 'NOVO JOGO PARA SUPER NINTENDO'
            tw = d.textlength(txt, font=f)
            d.rounded_rectangle([(W - tw) / 2 - 30, H - 120, (W + tw) / 2 + 30, H - 40], radius=20, fill=(200, 30, 20), outline=ESCURO, width=6)
            d.text(((W - tw) / 2, H - 112), txt, font=f, fill=BRANCO)
        return im
    return quadro
def cena_final():
    cart = cartucho(760)
    def quadro(i, t):
        im = fundo(t)
        d = ImageDraw.Draw(im)
        cap = CAPA.resize((int(CAPA.width * 620 / CAPA.height), 620), Image.LANCZOS)
        q = Image.new('RGB', (cap.width + 14, cap.height + 14), AMARELO); q.paste(cap, (7, 7))
        sombra(im, q, (110, 90))
        im.paste(cart, (W - cart.width - 90, 150 + int(math.sin(t * 2.2) * 14)), cart)
        if t > 0.3:
            texto_capa(d, (0, 790), 'O TÉCNICO É VOCÊ!', int(130 * (0.6 + 0.4 * entra(t - 0.3, 0.5))), centro=True)
        return im
    return quadro

ROTEIRO = [
    ('v1', cena_titulo(), 0.6),
    ('v2', cena_capa(), 0.8),
    ('v3', cena_jogo('escolha', '64 CLUBES\n4 SÉRIES', 'da Série D até o título'), 0.5),
    ('v4', cena_jogo('jogo', 'JOGOS AO VIVO!', 'gols, pênaltis e cartões'), 0.6),
    ('v5', cena_jogo('elenco', 'ESCALE E\nTREINE!', 'táticas, moral e treino'), 0.5),
    ('v6', cena_jogo('negocia', 'NEGOCIE\nCOMO NO\nELIFOOT!', 'proposta e contraproposta'), 0.5),
    ('v7', cena_jogo('copa', 'COPA DO\nBRASIL!', 'estádio, banco e caixa'), 0.5),
    ('v9', cena_jogo('carreira', 'FAÇA SUA\nCARREIRA!', 'metas, reputação e prêmios'), 0.5),
    ('v8', cena_final(), 2.5),
]

def mp3_np(arq):
    raw = subprocess.run([FF, '-i', arq, '-f', 's16le', '-ac', '1', '-ar', str(RATE), '-'], capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768
def wav_np(arq):
    with wave.open(arq) as w:
        a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768
        if w.getnchannels() == 2: a = a.reshape(-1, 2).mean(axis=1)
        return a

def main():
    gera_vozes()
    cenas = [(v, fn, dur_mp3(os.path.join(AU, v + '.mp3')) + extra) for v, fn, extra in ROTEIRO]
    total = sum(c[2] for c in cenas)
    # ----- audio: tema do jogo (abaixa durante a fala) e vinheta de vitoria no fim
    a = np.zeros(int(total * RATE) + RATE)
    mus = wav_np(os.path.join(ROOT, 'teste', 'musica_titulo.wav'))
    fim = wav_np(os.path.join(ROOT, 'teste', 'musica_vitoria.wav'))
    t_final = total - cenas[-1][2]
    n1 = int(t_final * RATE)
    seg = np.tile(mus, 3)[:n1]
    vol = np.full(n1, 0.55)
    tt = 0.0
    vozes = []
    for v, fn, d in cenas:
        x = mp3_np(os.path.join(AU, v + '.mp3'))
        i0 = int((tt + 0.25) * RATE)
        vozes.append((i0, x))
        if i0 < n1: vol[i0:min(n1, i0 + len(x))] = 0.28
        tt += d
    # suaviza o ducking
    k = np.ones(int(0.15 * RATE)) / int(0.15 * RATE)
    vol = np.convolve(vol, k, mode='same')
    a[:n1] += seg * vol
    a[n1:n1 + len(fim)] += fim[: len(a) - n1] * 0.6
    for i0, x in vozes: a[i0:i0 + len(x)] += x[: len(a) - i0] * 1.1
    a = a[: int(total * RATE)]
    a = a / max(1.0, np.max(np.abs(a)) / 0.95)
    wav_out = os.path.join(TR, 'audio_mix.wav')
    with wave.open(wav_out, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes((a * 32767).astype(np.int16).tobytes())
    # ----- video
    mp4 = os.path.join(TR, 'trailer_super_tecnico_98.mp4')
    cmd = [FF, '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-',
           '-i', wav_out, '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-preset', 'medium',
           '-c:a', 'aac', '-b:a', '192k', '-shortest', mp4]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
    for v, fn, d in cenas:
        nf = int(d * FPS)
        for i in range(nf):
            t = i / FPS
            im = fn(i, t)
            kk = min(1.0, t / 0.18, (d - t) / 0.18)
            if kk < 1: im = Image.blend(Image.new('RGB', (W, H), (0, 0, 0)), im, max(0.0, kk))
            p.stdin.write(im.tobytes())
    p.stdin.close(); p.wait()
    print('trailer:', mp4, f'{total:.1f}s')

if __name__ == '__main__':
    main()
