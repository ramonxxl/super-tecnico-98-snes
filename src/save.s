; =====================================================================
;  Jogos salvos na SRAM (64 KB): 3 espacos de 16 KB
;  +0 "EF98"  +4 soma  +6 bloco G  +$100 bloco W (mundo)
; =====================================================================

SAVE_G = 6
SAVE_W = $100

; lptr2 = inicio do espaco slot_cur
SlotPtr:
    .a8
    .i16
    lda slot_cur
    A16
    and #$00FF
    asl a
    tax
    lda SlotAddr,x
    sta lptr2
    A8
    lda SlotBank,x
    sta lptr2+2
    rts
SlotAddr: .word $0000, $4000, $0000
SlotBank: .byte $70, 0, $70, 0, $71, 0

SaveGame:
    .a8
    .i16
    jsr SlotPtr
    ; invalida a assinatura durante a gravacao
    ldy #0
    lda #0
    sta [lptr2],y
    A16
    stz tmp4                ; soma
    A8
    ; bloco G
    ldx #0
    ldy #SAVE_G
@g: lda g_start,x
    sta [lptr2],y
    jsr SumA
    inx
    iny
    cpx #G_SIZE
    bne @g
    ; bloco W
    ldx #0
    ldy #SAVE_W
@w: lda f:W,x
    sta [lptr2],y
    jsr SumA
    inx
    iny
    cpx #W_SIZE
    bne @w
    ; soma e assinatura
    ldy #4
    lda tmp4
    sta [lptr2],y
    iny
    lda tmp4+1
    sta [lptr2],y
    ldy #1
    lda #FONT_LF
    sta [lptr2],y
    iny
    lda #9
    sta [lptr2],y
    iny
    lda #9
    sta [lptr2],y
    ldy #0
    lda #FONT_LE
    sta [lptr2],y
    rts

; tmp4 += A (8 bits)
SumA:
    .a8
    .i16
    clc
    adc tmp4
    sta tmp4
    bcc :+
    inc tmp4+1
:   rts

; confere o espaco slot_cur: carry=1 se valido. Preenche si_*
SlotInfo:
    .a8
    .i16
    jsr SlotPtr
    ldy #0
    lda [lptr2],y
    cmp #FONT_LE
    bne @no
    iny
    lda [lptr2],y
    cmp #FONT_LF
    bne @no
    iny
    lda [lptr2],y
    cmp #9
    bne @no
    iny
    lda [lptr2],y
    cmp #9
    bne @no
    ; soma (aceita tambem o formato anterior, sem carreira / meta / tatica)
    stz sv_old
    ldx #G_SIZE
    jsr SlotSum
    bcs @ok
    inc sv_old
    ldx #G_OLD
    jsr SlotSum
    bcc @no
@ok:
    ldy #(SAVE_G + g_user - g_start)
    lda [lptr2],y
    sta si_team
    ldy #(SAVE_G + g_round - g_start)
    lda [lptr2],y
    sta si_round
    ldy #(SAVE_G + g_season - g_start)
    lda [lptr2],y
    sta si_season
    iny
    lda [lptr2],y
    sta si_season+1
    sec
    rts
@no:
    clc
    rts

; soma do espaco com X bytes de bloco G: carry=1 se bate com a gravada
G_OLD = g_form - g_start
SlotSum:
    .a8
    .i16
    A16
    stz tmp4
    A8
    ldy #SAVE_G
@g: lda [lptr2],y
    jsr SumA
    iny
    dex
    bne @g
    ldy #SAVE_W
    ldx #W_SIZE
@w: lda [lptr2],y
    jsr SumA
    iny
    dex
    bne @w
    ldy #4
    lda [lptr2],y
    cmp tmp4
    bne @no
    iny
    lda [lptr2],y
    cmp tmp4+1
    bne @no
    sec
    rts
@no:
    clc
    rts

; carrega o espaco slot_cur. carry=1 se deu certo
LoadGame:
    .a8
    .i16
    jsr SlotInfo
    bcs :+
    rts
:   ldx #0
    ldy #SAVE_G
@g: lda [lptr2],y
    sta g_start,x
    inx
    iny
    cpx #G_SIZE
    bne @g
    ldx #0
    ldy #SAVE_W
@w: lda [lptr2],y
    sta f:W,x
    inx
    iny
    cpx #W_SIZE
    bne @w
    ; formato anterior: os campos novos comecam zerados
    lda sv_old
    beq @fim
    ldx #0
@z: stz g_form,x
    inx
    cpx #(g_end - g_form)
    bne @z
@fim:
    sec
    rts
