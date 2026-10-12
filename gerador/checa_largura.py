# Verificador: acha desvios (branch/jmp) para rotulos onde o montador assume
# uma largura de acumulador diferente da largura em vigor no ponto do desvio.
import re, sys

MACRO_END = {'A8': 8, 'A16': 16, 'PRINT': 8, 'PRINTNUM8': 8, 'PRINTNUM16': 8}
BR = re.compile(r'^\s*(bra|brl|beq|bne|bcc|bcs|bmi|bpl|bvc|bvs|jmp)\s+(\S+)\s*(;.*)?$', re.I)

def check(path):
    lines = open(path, encoding='utf-8').read().split('\n')
    width = 8
    labels = {}      # nome -> (largura assumida, linha)
    anon = []        # (indice_linha, largura)
    branches = []    # (linha, alvo, largura)
    scope = ''
    pending = []     # rotulos aguardando diretivas imediatamente apos
    for i, raw in enumerate(lines):
        l = raw.split(';')[0].rstrip()
        s = l.strip()
        if not s:
            continue
        m = re.match(r'^([A-Za-z_@][A-Za-z0-9_]*):\s*(.*)$', s)
        is_anon = s.startswith(':')
        if is_anon:
            anon.append([i, width]); pending.append(('anon', len(anon) - 1))
            s = s[1:].strip()
            if not s: continue
        elif m:
            name = m.group(1)
            if not name.startswith('@'): scope = name; key = name
            else: key = scope + name
            labels[key] = [width, i]; pending.append(('lab', key))
            s = m.group(2).strip()
            if not s: continue
        tok = s.split()[0]
        if tok in ('.a8', '.a16'):
            width = 8 if tok == '.a8' else 16
            for kind, k in pending:
                if kind == 'anon': anon[k][1] = width
                else: labels[k][0] = width
            continue
        for kind, k in pending:
            if tok in ('A8', 'A16', 'rep', 'sep'):
                if kind == 'anon': anon[k].append('ok')
                else: labels[k].append('ok')
        pending = []
        if tok in MACRO_END:
            width = MACRO_END[tok]; continue
        if tok == 'rep' and '#$20' in s or tok == 'rep' and '#$30' in s:
            width = 16; continue
        if tok == 'sep' and ('#$20' in s or '#$30' in s):
            width = 8; continue
        mb = BR.match(s)
        if mb:
            tgt = mb.group(2)
            if tgt.startswith('('): continue
            branches.append((i, tgt, width, scope))
            if mb.group(1).lower() in ('bra', 'brl', 'jmp'):
                pass
    errs = 0
    for (i, tgt, w, sc) in branches:
        if re.match(r'^:[+-]+$', tgt):
            n = len(tgt) - 1
            idx = [a[0] for a in anon]
            if tgt[1] == '+':
                after = [k for k, a in enumerate(anon) if a[0] > i]
                k = after[n - 1] if len(after) >= n else None
            else:
                before = [k for k, a in enumerate(anon) if a[0] <= i]
                k = before[-n] if len(before) >= n else None
            if k is None: continue
            if 'ok' in anon[k]: continue
            lw = anon[k][1]; ln = anon[k][0]
        else:
            key = sc + tgt if tgt.startswith('@') else tgt
            if key not in labels: continue
            if 'ok' in labels[key]: continue
            lw, ln = labels[key][0], labels[key][1]
        if lw != w:
            errs += 1
            print(f'{path}:{i+1}: desvio para {tgt} (linha {ln+1}) em A{w}, mas o rotulo esta montado como A{lw}')
    return errs

total = sum(check(p) for p in sys.argv[1:])
print('problemas:', total)
