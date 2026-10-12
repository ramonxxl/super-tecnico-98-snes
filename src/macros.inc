; ---------------------------------------------------------------- macros
.macro A8
    sep #$20
    .a8
.endmacro
.macro A16
    rep #$20
    .a16
.endmacro
.macro I8
    sep #$10
    .i8
.endmacro
.macro I16
    rep #$10
    .i16
.endmacro

; copia bloco de ROM para a VRAM (endereco em palavras)
.macro VRAM_LOAD src, vaddr, len
    ldx #vaddr
    stx VMADDL
    ldx #.loword(src)
    stx dma_src
    lda #^src
    sta dma_src+2
    ldx #len
    stx dma_len
    jsr DmaVram
.endmacro

; copia bloco de ROM para o buffer de paletas (indice de cor)
.macro PAL_LOAD src, color, len
    ldx #.loword(src)
    stx dma_src
    lda #^src
    sta dma_src+2
    ldx #(color*2)
    ldy #len
    jsr CopyPal
.endmacro

; imprime texto na camada BG3 (coluna, linha, paleta 0..7)
.macro PRINT str, col, row, pal
    ldx #((row)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
    ldx #.loword(str)
    jsr PrintStr
.endmacro

; imprime numero (variavel de 16 bits) com largura fixa
.macro PRINTNUM16 var, col, row, pal, width
    A16
    lda var
    sta num
    stz num+2
    A8
    ldx #((row)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
    lda #width
    sta num_w
    jsr PrintNum
.endmacro

.macro PRINTNUM8 var, col, row, pal, width
    A16
    lda var
    and #$00FF
    sta num
    stz num+2
    A8
    ldx #((row)*32+(col))
    stx txt_pos
    lda #(((pal)<<2)|$20)
    sta txt_attr
    lda #width
    sta num_w
    jsr PrintNum
.endmacro

.macro SFX id
    lda #id
    jsr PlaySfx
.endmacro

; desvios longos (condicao invertida + jmp)
.macro JNE target
    .local skip
    beq skip
    jmp target
skip:
.endmacro
.macro JEQ target
    .local skip
    bne skip
    jmp target
skip:
.endmacro
.macro JCS target
    .local skip
    bcc skip
    jmp target
skip:
.endmacro
.macro JCC target
    .local skip
    bcs skip
    jmp target
skip:
.endmacro

; marca a tela atual (usado pelo robo de testes)
.macro SCR n
    pha
    lda #n
    sta scr
    pla
.endmacro
