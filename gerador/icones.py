# Icones do menu do clube (16x16) a partir de emojis Twemoji (licenca CC-BY 4.0, Twitter/X).
# Baixa os PNG uma vez (cache em arte_fonte/emoji), reduz para 14x14, poe contorno escuro,
# reduz as cores para 4 paletas de 15 cores e grava os tiles 4bpp de sprite.
# Saidas: gen/icon_tiles.bin (folha 128x32), gen/icon_pal.bin (4 paletas), gen/icon_pal.inc
import os, urllib.request
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, 'arte_fonte', 'emoji')
GEN = os.path.join(ROOT, 'gen')
URL = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/{}.png'

# ordem = itens do menu do clube
ICONES = [
    '26bd',   # jogar: bola
    '1f455',  # escalacao: camisa
    '1f3cb',  # treino: halterofilista
    '1f4ca',  # classificacao: grafico de barras
    '1f4cb',  # resultados: prancheta
    '1f3c6',  # copa: trofeu
    '1f91d',  # mercado: aperto de mao
    '1f4b0',  # financas: saco de dinheiro
    '1f4d6',  # historico: livro aberto
    '1f4be',  # salvar: disquete
]
CONTORNO = (8, 12, 28)

def baixa(cod):
    os.makedirs(CACHE, exist_ok=True)
    arq = os.path.join(CACHE, cod + '.png')
    if not os.path.exists(arq):
        urllib.request.urlretrieve(URL.format(cod), arq)
    return arq

def snes(c): return tuple((v >> 3) << 3 for v in c)

def icone(cod):
    im = Image.open(baixa(cod)).convert('RGBA')
    im = im.crop(im.getbbox())
    lado = max(im.size)
    q = Image.new('RGBA', (lado, lado), (0, 0, 0, 0))
    q.paste(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    pq = q.resize((14, 14), Image.LANCZOS)
    out = Image.new('RGBA', (16, 16), (0, 0, 0, 0)); out.paste(pq, (1, 1))
    px = out.load()
    cheio = [[px[x, y][3] >= 110 for x in range(16)] for y in range(16)]
    res = Image.new('RGBA', (16, 16), (0, 0, 0, 0)); r = res.load()
    for y in range(16):
        for x in range(16):
            if cheio[y][x]:
                c = px[x, y]; r[x, y] = (c[0], c[1], c[2], 255)
            elif any(0 <= x + dx < 16 and 0 <= y + dy < 16 and cheio[y + dy][x + dx] for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                r[x, y] = CONTORNO + (255,)
    return res

def paleta_de(imgs):
    tira = Image.new('RGB', (16 * len(imgs), 16), CONTORNO)
    for i, im in enumerate(imgs):
        rgb = Image.new('RGB', (16, 16), CONTORNO); rgb.paste(im, (0, 0), im)
        tira.paste(rgb, (16 * i, 0))
    pq = tira.quantize(14, method=Image.MEDIANCUT)
    return [snes(CONTORNO)] + [snes(tuple(pq.getpalette()[i * 3:i * 3 + 3])) for i in range(14)]

def perto(c, pal): return min(range(len(pal)), key=lambda i: sum((a - b) ** 2 for a, b in zip(c, pal[i])))

def enc4(pix):
    b = bytearray(32)
    for y in range(8):
        for x in range(8):
            v = pix[y * 8 + x]
            for p in range(4):
                if v >> p & 1: b[(p >> 1) * 16 + y * 2 + (p & 1)] |= 0x80 >> x
    return bytes(b)

def main():
    imgs = [icone(c) for c in ICONES]
    def media(im):
        px = [im.getpixel((x, y)) for x in range(16) for y in range(16) if im.getpixel((x, y))[3]]
        return tuple(sum(p[k] for p in px) // len(px) for k in range(3))
    ordem = sorted(range(len(imgs)), key=lambda i: (lambda m: (max(m) - min(m) < 40, m[0] - m[2]))(media(imgs[i])))
    grupos = [[], [], [], []]
    for j, i in enumerate(ordem): grupos[min(3, j * 4 // len(imgs))].append(i)
    pals, grupo_de = [], [0] * len(imgs)
    for g, idx in enumerate(grupos):
        pals.append(paleta_de([imgs[i] for i in idx]))
        for i in idx: grupo_de[i] = g
    folha = [[0] * 128 for _ in range(32)]
    prev = Image.new('RGBA', (128, 32), (20, 30, 60, 255))
    for i, im in enumerate(imgs):
        pal = pals[grupo_de[i]]
        ox, oy = (i % 8) * 16, (i // 8) * 16
        for y in range(16):
            for x in range(16):
                c = im.getpixel((x, y))
                if c[3]:
                    k = 1 if c[:3] == CONTORNO else min(15, 2 + perto(c[:3], pal[1:]))
                    folha[oy + y][ox + x] = k
                    prev.putpixel((ox + x, oy + y), pal[k - 1] + (255,))
    tiles = bytearray()
    for ty in range(4):
        for tx in range(16):
            tiles += enc4([folha[ty * 8 + y][tx * 8 + x] for y in range(8) for x in range(8)])
    open(os.path.join(GEN, 'icon_tiles.bin'), 'wb').write(tiles)
    palb = bytearray()
    for pal in pals:
        cores = [(0, 0, 0)] + pal + [(0, 0, 0)] * (15 - len(pal))
        for c in cores[:16]:
            v = (c[0] >> 3) | ((c[1] >> 3) << 5) | ((c[2] >> 3) << 10)
            palb += bytes([v & 255, v >> 8])
    open(os.path.join(GEN, 'icon_pal.bin'), 'wb').write(palb)
    # paletas de sprite 2..5 (0 e 1 sao dos escudos): atributo = prioridade 3 + paleta
    open(os.path.join(GEN, 'icon_pal.inc'), 'w').write(
        '; gerado por gerador/icones.py\nIconAttr: .byte ' + ', '.join(str(0x30 | ((2 + g) << 1)) for g in grupo_de) + '\n')
    os.makedirs(os.path.join(GEN, 'preview'), exist_ok=True)
    prev.resize((512, 128), Image.NEAREST).save(os.path.join(GEN, 'preview', 'icones.png'))
    print('icones:', len(imgs))

if __name__ == '__main__':
    main()
