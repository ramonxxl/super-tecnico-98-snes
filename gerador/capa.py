# Ilustracao de capa (etiqueta, manual e trailer) do Super Tecnico 98.
# Estadio a noite, jogador em pixel art chutando, escudos de clubes do jogo e titulo grande.
# Uso: python gerador/capa.py  -> cartucho/arte/capa.png
import os, math, json, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTE = os.path.join(ROOT, 'cartucho', 'arte'); os.makedirs(ARTE, exist_ok=True)
W, H = 1260, 1188
F = 'C:/Windows/Fonts/'
random.seed(98)
def fonte(n, t): return ImageFont.truetype(F + n, t)

def contorno(im, cor=(12, 16, 12, 255), r=6):
    a = im.split()[3].filter(ImageFilter.MaxFilter(r * 2 + 1))
    base = Image.new('RGBA', im.size, cor); base.putalpha(a)
    base.alpha_composite(im)
    return base

def pixel_art(linhas, cores, escala):
    h, w = len(linhas), max(len(l) for l in linhas)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y, l in enumerate(linhas):
        for x, c in enumerate(l):
            if c in cores: im.putpixel((x, y), cores[c])
    return im.resize((w * escala, h * escala), Image.NEAREST)

# ---------------------------------------------------------------- fundo: estadio a noite
capa = Image.new('RGBA', (W, H), (8, 14, 40, 255))
d = ImageDraw.Draw(capa)
for y in range(0, 520):
    k = y / 520
    d.line([(0, y), (W, y)], fill=(int(8 + 20 * k), int(14 + 34 * k), int(40 + 60 * k), 255))
# refletores com brilho
for cx in (120, W - 120):
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).ellipse([cx - 260, -140, cx + 260, 380], fill=170)
    glow = glow.filter(ImageFilter.GaussianBlur(80))
    capa.paste(Image.new('RGBA', (W, H), (255, 245, 200, 255)), (0, 0), glow)
    d.rectangle([cx - 14, 120, cx + 14, 560], fill=(40, 46, 60, 255))
    d.rectangle([cx - 90, 40, cx + 90, 120], fill=(40, 46, 60, 255))
    for k in range(4):
        for j in range(2):
            d.rectangle([cx - 80 + k * 42, 50 + j * 34, cx - 48 + k * 42, 76 + j * 34], fill=(255, 250, 220, 255))
# arquibancada com torcida colorida
d.rectangle([0, 470, W, 720], fill=(34, 38, 52, 255))
cores_torcida = [(220, 40, 40), (250, 210, 40), (40, 90, 220), (240, 240, 240), (30, 150, 70), (250, 130, 30)]
for y in range(480, 712, 14):
    for x in range(random.randint(0, 10), W, 14):
        c = random.choice(cores_torcida) if random.random() < 0.8 else (60, 64, 80)
        d.ellipse([x, y, x + 9, y + 9], fill=c + (255,))
# bandeiras
for x, c in ((260, (220, 40, 40)), (620, (250, 210, 40)), (980, (40, 90, 220))):
    d.line([(x, 520), (x, 400)], fill=(200, 200, 200, 255), width=6)
    d.polygon([(x, 400), (x + 110, 425), (x, 450)], fill=c + (255,))
d.rectangle([0, 712, W, 726], fill=(18, 20, 26, 255))
# gramado em perspectiva com faixas
for y in range(726, H):
    k = (y - 726) / (H - 726)
    faixa = int((y - 726) / (24 + 60 * k)) % 2
    c = (34, 132, 56) if faixa else (28, 112, 46)
    d.line([(0, y), (W, y)], fill=c + (255,))
d.line([(0, 760), (W, 760)], fill=(235, 240, 235, 255), width=6)
d.ellipse([W // 2 - 300, 840, W // 2 + 300, 1080], outline=(235, 240, 235, 255), width=6)

# ---------------------------------------------------------------- jogador em pixel art (chutando)
JOGADOR = [
    "..........KKKK..........",
    ".........KHHHHK.........",
    "........KHHHHHHK........",
    "........KSSSSSHK........",
    "........KSKSSSSK........",
    "........KSSSSSK.........",
    ".........KSSSK..........",
    "......KKKKYYKKKK........",
    ".....KYYYYYYYYYYK.......",
    "....KSYYYYGYYYYYYK......",
    "...KSSKYYYYYYYYYKSK.....",
    "..KSSK.KYYYYYYYYKSSK....",
    "..KSK..KYYYYYYYYK.KSK...",
    "..KK...KYYYYYYYYK..KSK..",
    ".......KGGGGGGGGK...KK..",
    ".......KBBBBBBBBK.......",
    ".......KBBBBBBBBBK......",
    ".......KBBBK.KBBBBK.....",
    "......KBBBK...KBBBBK....",
    "......KSSK.....KSSSSK...",
    ".....KSSK.......KWWWWKK.",
    ".....KWWK........KWWWWOK",
    "....KWWK..........KOOOOK",
    "....KWWK...........KKKK.",
    "...KOOOK................",
    "..KOOOOOK...............",
    "..KKKKKKK...............",
]
CORES = {'K': (14, 14, 18, 255), 'H': (40, 26, 16, 255), 'S': (196, 132, 92, 255), 'Y': (250, 212, 40, 255),
         'G': (30, 140, 60, 255), 'B': (40, 80, 200, 255), 'W': (245, 245, 245, 255), 'O': (20, 20, 20, 255)}
jog = contorno(pixel_art(JOGADOR, CORES, 15), r=7)
capa.alpha_composite(jog, (170, H - jog.height - 60))

# bola com rastro
BOLA = ["...KKKK...", ".KKWWWWKK.", ".KWWWWWWK.", "KWWKKKWWWK", "KWKKKKKWWK", "KWWKKKWWWK", "KWWWWWWKKK", ".KWWWWWKK.", ".KKWWWWKK.", "...KKKK..."]
bola = contorno(pixel_art(BOLA, {'K': (14, 14, 18, 255), 'W': (250, 250, 250, 255)}, 11), r=5)
bx, by = 560, 800
for k in range(4):
    d.line([(bx + 10 - k * 26, by + 150 + k * 40), (bx - 20 - k * 26, by + 190 + k * 40)], fill=(255, 255, 255, 150), width=9 - 2 * k)
capa.alpha_composite(bola, (bx, by))

# ---------------------------------------------------------------- escudos de clubes do jogo
el = json.load(open(os.path.join(ROOT, 'elenco.json'), encoding='utf-8'))
def escudo(c1, c2, esc=5):
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    for y in range(1, 31):
        half = 13 if y < 18 else max(1, round(13 - (y - 18) * 1.05))
        if y < 4: half = 13 - (4 - y)
        for x in range(16 - half, 16 + half):
            im.putpixel((x, y), c2 if (12 <= x < 20 or 4 <= y < 9) else c1)
    im = im.resize((32 * esc, 32 * esc), Image.NEAREST)
    return contorno(im, r=4)
hexrgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
for k, i in enumerate([0, 1, 3, 6, 9, 12]):
    c = el['clubes'][i]['cores']
    e = escudo(hexrgb(c[0]), hexrgb(c[1]), 4)
    capa.alpha_composite(e, (720 + (k % 3) * 170, 790 + (k // 3) * 170))

# ---------------------------------------------------------------- titulo
def titulo(txt, y, tam, cor=(255, 214, 40), cx=W // 2):
    f = fonte('impact.ttf', tam)
    w = d.textlength(txt, font=f)
    x = cx - w / 2
    for k in range(12, 0, -1):
        d.text((x + k * 0.7, y + k), txt, font=f, fill=(160, 20, 10, 255), stroke_width=12, stroke_fill=(10, 10, 14, 255))
    d.text((x, y), txt, font=f, fill=cor + (255,), stroke_width=12, stroke_fill=(10, 10, 14, 255))
titulo('SUPER TÉCNICO', 30, 170)
titulo('98', 210, 250, (255, 255, 255))
f = fonte('seguibl.ttf', 44)
txt = 'GERENCIADOR DE FUTEBOL'
tw = d.textlength(txt, font=f)
d.rounded_rectangle([(W - tw) / 2 - 30, 470, (W + tw) / 2 + 30, 540], radius=18, fill=(30, 140, 60, 255), outline=(10, 10, 14, 255), width=6)
d.text(((W - tw) / 2, 476), txt, font=f, fill=(255, 255, 255, 255))

capa.convert('RGB').save(os.path.join(ARTE, 'capa.png'))
print('capa ok')
