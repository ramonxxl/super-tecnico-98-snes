# Acha rotulos alcancados so por desvio onde o montador ainda esta em 16 bits
# (bloco A16 terminado em bra/jmp/rts) e a instrucao seguinte usa imediato do acumulador.
import re, sys
IMM = re.compile(r'^\s*(lda|cmp|and|ora|eor|adc|sbc|bit)\s+#', re.I)
for path in sys.argv[1:]:
    L = open(path, encoding='utf-8').read().split('\n')
    w = 8; prev_uncond = False
    for i, raw in enumerate(L):
        s = raw.split(';')[0].strip()
        if not s: continue
        lab = re.match(r'^(:|[@A-Za-z_][A-Za-z0-9_]*:)\s*(.*)$', s)
        if lab:
            rest = lab.group(2).strip()
            if w == 16 and prev_uncond:
                # procura a proxima instrucao
                j = i; nxt = rest
                while not nxt:
                    j += 1; nxt = L[j].split(';')[0].strip()
                if IMM.match(nxt):
                    print(f'{path}:{i+1}: rotulo em 16 bits apos desvio: {nxt}')
            s = rest
            if not s: continue
        tok = s.split()[0]
        if tok in ('A8', '.a8') or (tok == 'sep' and '#$20' in s or tok == 'sep' and '#$30' in s): w = 8
        elif tok in ('A16', '.a16') or (tok == 'rep' and ('#$20' in s or '#$30' in s)): w = 16
        elif tok in ('PRINT', 'PRINTNUM8', 'PRINTNUM16', 'SFX', 'SCR'): pass
        prev_uncond = tok.lower() in ('bra', 'jmp', 'rts', 'rtl', 'brl', 'jml', 'rti')
