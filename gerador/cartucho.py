# Etiqueta do cartucho (formato classico) e manual de instrucoes (PDF A5) do Super Tecnico 98.
# Uso: python gerador/capa.py && python gerador/cartucho.py   (fotos em cartucho/fotos/foto_*.png)
import os, math
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'cartucho')
F = 'C:/Windows/Fonts/'
def fonte(nome, tam): return ImageFont.truetype(F + nome, tam)
VERDE, VERDE2, AMARELO, AZUL, BRANCO, PRETO, CINZA = '#0B3D1E', '#1E8C3C', '#F8D020', '#2850C8', '#FFFFFF', '#101410', '#E8EEE8'
CAPA = Image.open(os.path.join(OUT, 'arte', 'capa.png')).convert('RGB')

def foto(nome, escala=2):
    im = Image.open(os.path.join(OUT, 'fotos', 'foto_' + nome + '.png')).convert('RGB')
    return im.resize((im.width * escala, im.height * escala), Image.NEAREST)
def moldura(im, cor=VERDE, b=6):
    o = Image.new('RGB', (im.width + 2 * b, im.height + 2 * b), cor); o.paste(im, (b, b)); return o
def centro(d, xy, texto, f, cor, larg):
    w = d.textlength(texto, font=f); d.text((xy[0] + (larg - w) / 2, xy[1]), texto, font=f, fill=cor)

CAPA.save(os.path.join(OUT, 'capa_jogo.png'), dpi=(600, 600))

# ------------------------------------------------------------------ manual (A5 a 150 dpi)
PW, PH = 874, 1240
FT = fonte('seguibl.ttf', 46); FS = fonte('segoeuib.ttf', 30); FB = fonte('segoeui.ttf', 23); FBB = fonte('segoeuib.ttf', 23)

def pagina(titulo, n):
    p = Image.new('RGB', (PW, PH), CINZA); d = ImageDraw.Draw(p)
    d.rectangle([0, 0, PW, 110], fill=VERDE)
    d.text((40, 26), titulo, font=FT, fill=AMARELO)
    d.rectangle([0, PH - 50, PW, PH], fill=AMARELO)
    centro(d, (0, PH - 44), f'SUPER TÉCNICO 98  —  {n}', fonte('segoeuib.ttf', 22), VERDE, PW)
    return p, d

def texto(d, x, y, linhas, larg=PW - 80, f=FB, cor=PRETO, esp=7):
    for ln in linhas:
        fnt = f
        if ln.startswith('**'): ln = ln[2:]; fnt = FBB
        if ln.startswith('# '):
            d.text((x, y), ln[2:], font=FS, fill=VERDE2); y += 42; continue
        palavras, linha = ln.split(' '), ''
        for w in palavras:
            teste = (linha + ' ' + w).strip()
            if d.textlength(teste, font=fnt) > larg:
                d.text((x, y), linha, font=fnt, fill=cor); y += fnt.size + esp; linha = w
            else: linha = teste
        d.text((x, y), linha, font=fnt, fill=cor); y += fnt.size + esp + (6 if ln == '' else 0)
    return y

def colar(p, nome, y, escala=2):
    im = moldura(foto(nome, escala))
    livre = PH - 70 - y
    if im.height > livre:
        k = livre / im.height
        im = im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)
    p.paste(im, ((PW - im.width) // 2, y))
    return y + im.height

def duas(p, a, b, y):
    ia, ib = moldura(foto(a, 1)), moldura(foto(b, 1))
    larg = (PW - 120) // 2
    k = larg / ia.width
    ia = ia.resize((larg, int(ia.height * k)), Image.NEAREST); ib = ib.resize((larg, int(ib.height * k)), Image.NEAREST)
    p.paste(ia, (40, y)); p.paste(ib, (PW - 40 - larg, y))
    return y + ia.height

pags = []
# 1 capa
p = Image.new('RGB', (PW, PH), VERDE); d = ImageDraw.Draw(p)
cap = CAPA.copy(); cap.thumbnail((780, 780))
p.paste(moldura(cap, AMARELO, 8), ((PW - cap.width - 16) // 2, 60))
centro(d, (0, 900), 'MANUAL DE INSTRUÇÕES', fonte('seguibl.ttf', 52), AMARELO, PW)
centro(d, (0, 975), 'Homenagem ao Elifoot 98', fonte('segoeuib.ttf', 32), BRANCO, PW)
d.rectangle([0, PH - 110, PW, PH], fill=AMARELO)
centro(d, (0, PH - 82), 'PARA SUPER NINTENDO', fonte('seguibl.ttf', 44), VERDE, PW)
pags.append(p)

# 2 comecando
p, d = pagina('COMEÇANDO', 2)
y = texto(d, 40, 135, [
    '# A HISTÓRIA',
    'Você é um técnico em início de carreira. Escolha um dos 64 clubes brasileiros (ou sorteie um da Série D, o desafio clássico) e leve o time ao topo: suba de série, ganhe a Copa do Brasil, cuide do caixa e não deixe a diretoria perder a paciência.',
    '# CONTROLES',
    '**Direcional: move o cursor. Setas seguradas repetem.',
    '**A / START: confirmar.   B: voltar.',
    '**SELECT (menu do clube): liga e desliga a música.',
    '# INICIANDO',
    'Escolha NOVO JOGO, um dos 3 espaços de jogo salvo, digite o nome do técnico e escolha o time (← → troca a série, X sorteia um time da Série D). O jogo é salvo no cartucho depois de cada jogo.'])
colar(p, 'escolha', y + 8)
pags.append(p)

# 3 menu do clube
p, d = pagina('O MENU DO CLUBE', 3)
y = texto(d, 40, 135, [
    'No topo: série, temporada, rodada, caixa, posição e a META da diretoria, o próximo jogo (C = em casa, F = fora), a situação na Copa do Brasil e a CONFIANÇA DA DIRETORIA.',
    '**JOGAR: a próxima rodada do campeonato ou jogo da copa.',
    '**ESCALAÇÃO, TREINO, TABELA, JOGOS, COPA, MERCADO, FINANÇAS, CARREIRA e SALVAR E SAIR: botões com ícones; use o direcional nas quatro direções.',
    '**JOGOS: resultados e artilheiros; X mostra o CALENDÁRIO com os próximos adversários.',
    'Os botões A (vermelho), B (amarelo), X (azul) e Y (verde) aparecem na tela com as cores do controle. Ações que gastam dinheiro pedem confirmação.',
    'Vitórias aumentam a confiança; derrotas e caixa negativo diminuem. Se chegar a zero, você é demitido!'])
colar(p, 'hub', y + 8)
pags.append(p)

# 4 dia de jogo
p, d = pagina('DIA DE JOGO', 4)
y = texto(d, 40, 135, [
    'A rodada é jogada ao vivo, minuto a minuto: o placar grande mostra o seu jogo com os escudos, e embaixo aparecem os outros jogos da série, com escudinhos nas cores dos clubes, e os lances (gols, pênaltis, gols contra, cartões, lesões).',
    '**Segure A para acelerar.  START: substituições (até 3).',
    '**L e R: mostram os jogos das outras séries.',
    'No fim, o resumo traz os gols, o destaque, os chutes a gol e a posse de bola.',
    '**No intervalo o jogo para: A continua, START substitui.',
    '**Estilo: defensivo, equilibrado ou ofensivo (SELECT na tela de substituições ou na escalação).'])
colar(p, 'partida', y + 8)
pags.append(p)

# 5 escalacao e treino
p, d = pagina('ESCALAÇÃO E TREINO', 5)
y = texto(d, 40, 135, [
    '**A: titular → reserva → fora.  X: escalação automática.',
    '**L: troca a TÁTICA (4-4-2, 4-3-3, 3-5-2, 5-3-2, 4-5-1, 3-4-3) e escala o time sozinho.',
    '**Y: põe à venda.  R: renova o contrato (paga luvas).',
    'Colunas: força, idade, situação (LES lesionado, SUS suspenso, SEL na seleção, VND à venda), C = anos de contrato e M = moral (↑ animado, ↓ desanimado). Moral alta joga melhor; quem fica no banco desanima.',
    'No TREINO escolha o foco: ataque, defesa, equilibrado (todos) ou físico (metade das lesões). Jogadores de até 30 anos podem ganhar força.'])
duas(p, 'escalacao', 'treino', y + 8)
pags.append(p)

# 6 mercado
p, d = pagina('MERCADO DA BOLA', 6)
y = texto(d, 40, 135, [
    '**LISTA DE TRANSFERÊNCIAS: quem está à venda nesta rodada; o clube aceita o valor de mercado.',
    '**PROCURAR NOS CLUBES: veja o elenco de qualquer clube e faça proposta por qualquer jogador. Titular custa mais caro.',
    '**NEGOCIAÇÃO: ← → e ↑ ↓ mudam o valor; A faz a proposta. O clube aceita, faz CONTRAPROPOSTA ou recusa.',
    'Seus jogadores à venda recebem propostas depois das rodadas. Os outros clubes também negociam entre si: veja as notícias no fim da rodada.'])
colar(p, 'negocia', y + 8)
pags.append(p)

# 7 copa e financas
p, d = pagina('COPA E FINANÇAS', 7)
y = texto(d, 40, 135, [
    '# COPA DO BRASIL',
    'Os 64 clubes em mata-mata com jogos de ida e volta e pênaltis no empate. Cada fase vencida dá prêmio; o campeão leva R$ 6 milhões.',
    '# FINANÇAS E ESTÁDIO',
    'Entram a cota de TV e a bilheteria; saem salários e juros. Ajuste o preço do ingresso, amplie o estádio (+2000 lugares) e peça ou pague empréstimos no banco (2% de juros por data).'])
duas(p, 'copa', 'financas', y + 8)
pags.append(p)

# 8 temporada, dicas
p, d = pagina('A TEMPORADA', 8)
y = texto(d, 40, 135, [
    '30 rodadas (turno e returno). Os 4 primeiros sobem, os 4 últimos caem. No fim saem os PRÊMIOS (artilheiros, melhor goleiro e craque; premiado do seu time vale dinheiro), jogadores envelhecem, veteranos se aposentam e a base revela garotos. Contrato vencido: o jogador vai embora!',
    'Depois das rodadas 8, 16 e 24 os craques são convocados para a SELEÇÃO e perdem um jogo.',
    '# CARREIRA',
    'Cumprir a META da diretoria, vencer e subir aumentam a sua REPUTAÇÃO; com ela chegam convites de clubes maiores, até no meio da temporada. Em CARREIRA veja seus números e o histórico; X pede demissão. Rebaixado ou sem a confiança da diretoria? Demitido!',
    '# DICAS',
    '• Renove os craques antes do contrato acabar.  • Não deixe o caixa negativo.  • Ingresso caro esvazia o estádio.'])
duas(p, 'premios', 'historico', y + 8)
pags.append(p)

pdf = os.path.join(OUT, 'manual_super_tecnico_98.pdf')
pags[0].save(pdf, save_all=True, append_images=pags[1:], resolution=150)
for i, pg in enumerate(pags): pg.save(os.path.join(OUT, f'manual_pagina_{i + 1}.png'))
print('manual ok:', pdf)

# ------------------------------------------------------------------ etiqueta no formato classico (800x440, escala 3x)
S = 3
LW, LH = 800 * S, 440 * S
lab = Image.new('RGBA', (LW, LH), (0, 0, 0, 0))
d = ImageDraw.Draw(lab)
d.rounded_rectangle([0, 0, LW - 1, LH - 1], radius=22 * S, fill='#050505')
# coluna esquerda: selos proprios
d.text((24 * S, 78 * S), 'UMA HOMENAGEM AO', font=fonte('arialbd.ttf', 9 * S), fill=BRANCO)
d.rounded_rectangle([20 * S, 94 * S, 112 * S, 118 * S], radius=12 * S, fill=VERDE2, outline=BRANCO, width=2 * S)
centro(d, (20 * S, 99 * S), 'ELIFOOT 98', fonte('arialbd.ttf', 10 * S), BRANCO, 92 * S)
cx, cy, r = 66 * S, 343 * S, 38 * S
pts = []
for k in range(48):
    a = 2 * math.pi * k / 48; rr = r if k % 2 == 0 else r - 4 * S
    pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
d.polygon(pts, fill='#C9A55C')
d.ellipse([cx - r + 9 * S, cy - r + 9 * S, cx + r - 9 * S, cy + r - 9 * S], fill='#E8D6A8', outline='#8A6A2A', width=2 * S)
centro(d, (cx - r, cy - 14 * S), '64 CLUBES', fonte('arialbd.ttf', 7 * S), '#5A3A10', 2 * r)
centro(d, (cx - r, cy - 4 * S), '4 SÉRIES', fonte('arialbd.ttf', 7 * S), '#5A3A10', 2 * r)
centro(d, (cx - r, cy + 6 * S), '+ COPA', fonte('arialbd.ttf', 7 * S), '#5A3A10', 2 * r)
d.text((20 * S, 392 * S), 'ST-SNES-BRA', font=fonte('arialbd.ttf', 11 * S), fill=BRANCO)
d.text((20 * S, 406 * S), 'FEITO NO BRASIL', font=fonte('arialbd.ttf', 11 * S), fill=BRANCO)
# arte central
ax0, ay0, ax1, ay1 = 128 * S, 22 * S, 548 * S, 418 * S
lab.paste(CAPA.resize((ax1 - ax0, ay1 - ay0), Image.LANCZOS), (ax0, ay0))
# coluna direita
d.rectangle([557 * S, 66 * S, 767 * S, 82 * S], fill=VERDE2)
d.text((558 * S, 94 * S), 'O TÉCNICO É VOCÊ!', font=fonte('arialbd.ttf', 11 * S), fill=BRANCO)
for k, ln in enumerate(['Leve seu clube da Série D', 'ao título brasileiro e', 'à Copa do Brasil.']):
    d.text((558 * S, (112 + 12 * k) * S), ln, font=fonte('arial.ttf', 8 * S), fill='#D8D8D8')
recursos = [('ESCALE', 'jogos ao vivo, minuto a minuto'), ('NEGOCIE', 'propostas e contrapropostas'),
            ('ADMINISTRE', 'estádio, banco e salários'), ('CONQUISTE', 'acesso, copa e títulos')]
for k, (tit, txt) in enumerate(recursos):
    y = (158 + k * 35) * S
    d.ellipse([558 * S, y, 570 * S, y + 12 * S], fill=AMARELO, outline=VERDE, width=S)
    centro(d, (558 * S, y - S), str(k + 1), fonte('arialbd.ttf', 7 * S), VERDE, 12 * S)
    d.text((576 * S, y - 2 * S), tit, font=fonte('arialbd.ttf', 8 * S), fill=BRANCO)
    d.text((576 * S, y + 9 * S), txt, font=fonte('arial.ttf', 7 * S), fill='#BDBDBD')
larguras = [2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3, 2, 1, 4, 1, 2, 3, 1, 2, 4, 1, 1, 3, 2]
x = 558 * S
for n, w in enumerate(larguras):
    if n % 2 == 0: d.rectangle([x, 307 * S, x + w * S, 337 * S], fill=BRANCO)
    x += w * S + S
centro(d, (558 * S, 339 * S), '789  ST98  2026  064', fonte('arial.ttf', 6 * S), '#BDBDBD', 145 * S)
d.text((560 * S, 352 * S), 'PARA', font=fonte('arialbd.ttf', 14 * S), fill='#E00000')
d.text((556 * S, 366 * S), 'SUPER NINTENDO', font=fonte('impact.ttf', 26 * S), fill='#E00000')
lab.save(os.path.join(OUT, 'etiqueta_formato_classico.png'), dpi=(800, 800))
print('etiqueta ok')
