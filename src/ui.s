; =====================================================================
;  Interface: componentes reutilizaveis de todas as telas
;   - UiBtn     botao de 2 tiles de altura (cantos arredondados) em 5 estilos
;   - UiPanel   painel (caixa de dialogo)
;   - UiBarOn   faixa de selecao na linha de texto (listas)
;   - menus de botoes (MenuButtons + RunMenu), Confirm (dialogo SIM/NAO), UiToast (aviso)
;  As pecas ficam no BG1, que e desenhado 4 px acima do texto: o botao nas linhas
;  r e r+1 do BG1 fica centrado na linha de texto r.
;  O mapa do BG1 fica numa copia na RAM ($7E2000) enviada no vblank quando muda.
; =====================================================================

BG1BUF   = $7E2000
UI_TILE  = $C0              ; byte baixo do primeiro tile da interface (tile 960)

STY_NORMAL = 0              ; secundario (azul-acinzentado)
STY_PRI    = 1              ; principal (azul vibrante)
STY_SEL    = 2              ; selecionado (borda amarela, pulsa)
STY_OK     = 3              ; positivo (verde)
STY_BAD    = 4              ; critico (vermelho)

; ---------------------------------------------------------------- base
; X = deslocamento no mapa para (ui_row, ui_col)
UiOfs:
    .a8
    .i16
    lda ui_row
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta ui_t
    lda ui_col
    and #$00FF
    clc
    adc ui_t
    asl a
    tax
    A8
    rts

; byte alto das entradas do mapa para o estilo ui_style
UiHi:
    .a8
    .i16
    lda ui_style
    clc
    adc #3                  ; paletas 3..7 do BG1
    asl a
    asl a
    ora #$03                ; tiles 960+ (bits altos do numero do tile)
    sta ui_hi
    rts

; fileira: ponta esquerda ui_tl, miolo ui_tm, ponta direita espelhada; X = posicao, ui_w = largura
UiRun:
    .a8
    .i16
    lda ui_tl
    clc
    adc #UI_TILE
    sta f:BG1BUF,x
    lda ui_hi
    sta f:BG1BUF+1,x
    inx
    inx
    lda ui_w
    sec
    sbc #2
    sta ui_t
@m: lda ui_t
    beq @fim
    lda ui_tm
    clc
    adc #UI_TILE
    sta f:BG1BUF,x
    lda ui_hi
    sta f:BG1BUF+1,x
    inx
    inx
    dec ui_t
    bra @m
@fim:
    lda ui_tl
    clc
    adc #UI_TILE
    sta f:BG1BUF,x
    lda ui_hi
    ora #$40                ; espelha na horizontal
    sta f:BG1BUF+1,x
    lda #1
    sta bg1_dirty
    rts

; botao em (ui_col, ui_row), largura ui_w, estilo ui_style
UiBtn:
    .a8
    .i16
    jsr UiHi
    jsr UiOfs
    stz ui_tl
    lda #1
    sta ui_tm
    jsr UiRun
    inc ui_row
    jsr UiOfs
    dec ui_row
    lda #2
    sta ui_tl
    lda #3
    sta ui_tm
    jmp UiRun

; painel em (ui_col, ui_row), largura ui_w, altura ui_h (linhas do BG1), estilo ui_style
UiPanel:
    .a8
    .i16
    jsr UiHi
    lda ui_row
    pha
    jsr UiOfs
    stz ui_tl
    lda #1
    sta ui_tm
    jsr UiRun
    lda ui_h
    sec
    sbc #2
    sta ui_n
@m: inc ui_row
    lda ui_n
    beq @b
    jsr UiOfs
    lda #4
    sta ui_tl
    lda #5
    sta ui_tm
    jsr UiRun
    dec ui_n
    bra @m
@b: jsr UiOfs
    lda #2
    sta ui_tl
    lda #3
    sta ui_tm
    jsr UiRun
    pla
    sta ui_row
    rts

; devolve ao fundo original Y linhas do BG1 a partir da linha A
UiRestore:
    .a8
    .i16
    sty ui_t
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a                   ; linha * 64 bytes
    tay
    lda ui_t
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    sta ui_t
    A8
@l: lda [bg_map],y
    tyx
    sta f:BG1BUF,x
    iny
    A16
    dec ui_t
    A8
    bne @l
    lda #1
    sta bg1_dirty
    rts

; mapa inteiro de volta ao fundo (ao trocar de tela)
UiReset:
    .a8
    .i16
    lda #$FF
    sta bar_row
    stz menu_kind
    lda #0
    ldy #32
    jmp UiRestore

; ---------------------------------------------------------------- faixa de selecao (listas)
; faixa na linha de texto A (colunas 1..30)
UiBarOn:
    .a8
    .i16
    cmp bar_row
    bne :+
    rts
:   pha
    jsr UiBarOff
    pla
    sta bar_row
    sta ui_row
    lda #1
    sta ui_col
    lda #30
    sta ui_w
    lda #STY_SEL
    sta ui_style
    jsr UiHi
    jsr UiOfs
    lda #6
    sta ui_tl
    lda #7
    sta ui_tm
    jsr UiRun
    inc ui_row
    jsr UiOfs
    lda #8
    sta ui_tl
    lda #9
    sta ui_tm
    jmp UiRun

UiBarOff:
    .a8
    .i16
    lda bar_row
    cmp #$FF
    beq :+
    ldy #2
    jsr UiRestore
    lda #$FF
    sta bar_row
:   rts

; ---------------------------------------------------------------- menus de botoes
; estilo de repouso do item sel: principal, critico ou normal
MenuBase:
    .a8
    .i16
    lda sel
    cmp bm_pri
    bne :+
    lda #STY_PRI
    rts
:   cmp bm_bad
    bne :+
    lda #STY_BAD
    rts
:   lda #STY_NORMAL
    rts

; desenha o botao do item sel com o estilo A
MenuBtn:
    .a8
    .i16
    sta ui_style
    jsr MenuRow
    sta ui_row
    lda bm_col
    sta ui_col
    lda bm_w
    sta ui_w
    jmp UiBtn

; marca / desmarca o item sel (botao ou faixa, conforme menu_kind)
MenuMark:
    .a8
    .i16
    lda menu_kind
    bne :+
    jsr MenuRow
    jmp ArrowOn
:   lda #STY_SEL
    jmp MenuBtn
MenuUnmark:
    .a8
    .i16
    lda menu_kind
    bne :+
    jsr MenuRow
    jmp ArrowOff
:   jsr MenuBase
    jmp MenuBtn

; desenha todos os botoes do menu (menu_n itens em menu_row0 + i*menu_step,
; coluna bm_col, largura bm_w) e passa o RunMenu para o modo de botoes
MenuButtons:
    .a8
    .i16
    lda #1
    sta menu_kind
    lda sel
    pha
    stz sel
@l: jsr MenuBase
    jsr MenuBtn
    inc sel
    lda sel
    cmp menu_n
    bne @l
    pla
    sta sel
    rts

; ---------------------------------------------------------------- pulso do item selecionado
; chamado a cada quadro: anima as cores do corpo do estilo "selecionado"
UiPulse:
    .a8
    .i16
    lda frame
    and #$03
    bne @r
    A16
    lda frame
    lsr a
    lsr a
    and #$0007
    sta ui_t
    asl a
    clc
    adc ui_t
    asl a                   ; *6 bytes
    tax
    lda PulseTab,x
    sta cgram_buf + (5*16+3)*2
    lda PulseTab+2,x
    sta cgram_buf + (5*16+4)*2
    lda PulseTab+4,x
    sta cgram_buf + (5*16+5)*2
    A8
    lda #1
    sta pal_dirty
@r: rts

; ---------------------------------------------------------------- dialogo de confirmacao
; abre a caixa: limpa as linhas de texto 9..16 e desenha o painel.
; Quem chama escreve a pergunta nas linhas 10..12 (coluna 5) e depois chama ConfirmAsk.
ConfirmOpen:
    .a8
    .i16
    jsr UiBarOff
    lda #9
@c: pha
    jsr ClearRow
    pla
    inc a
    cmp #17
    bne @c
    lda #3
    sta ui_col
    lda #9
    sta ui_row
    lda #26
    sta ui_w
    lda #9
    sta ui_h
    lda #STY_NORMAL
    sta ui_style
    jmp UiPanel

; mostra os botoes SIM (verde) e NAO (vermelho) e espera. A = 1 (sim) ou 0 (nao).
; Fecha a caixa; quem chamou redesenha a tela.
ConfirmAsk:
    .a8
    .i16
    lda #14
    sta ui_row
    lda #5
    sta ui_col
    lda #10
    sta ui_w
    lda #STY_OK
    sta ui_style
    jsr UiBtn
    lda #17
    sta ui_col
    lda #STY_BAD
    sta ui_style
    jsr UiBtn
    PRINT TXT_BT_SIM, 7, 14, 0
    PRINT TXT_BT_NAO, 19, 14, 0
    jsr WaitAB
    pha
    cmp #0
    beq :+
    SFX SFX_OK
:   lda #9
@c: pha
    jsr ClearRow
    pla
    inc a
    cmp #17
    bne @c
    lda #9
    ldy #10
    jsr UiRestore
    pla
    rts

; ---------------------------------------------------------------- aviso rapido
; X = texto, A = estilo (STY_OK sucesso, STY_BAD erro): faixa na linha 23 por ~1 s
UiToast:
    .a8
    .i16
    sta ui_style
    phx
    lda #23
    jsr ClearRow
    lda #23
    sta ui_row
    lda #2
    sta ui_col
    lda #28
    sta ui_w
    jsr UiBtn
    ldx #(23*32+4)
    stx txt_pos
    lda #$20
    sta txt_attr
    plx
    jsr PrintStr
    lda #55
    sta ui_n
@w: jsr NextFrame
    lda pad_new
    ora pad_new+1
    bne @x
    dec ui_n
    bne @w
@x: lda #23
    jsr ClearRow
    lda #23
    ldy #2
    jmp UiRestore

; ---------------------------------------------------------------- icones (sprites 16x16)
; icone A no sprite 8+A, posicao (tmp5 = x, tmp5+1 = y)
DrawIcon:
    .a8
    .i16
    sta ui_t
    A16
    and #$00FF
    tay
    clc
    adc #8
    asl a
    asl a
    tax
    A8
    lda tmp5
    sta oam_buf,x
    lda tmp5+1
    sta oam_buf+1,x
    ; tile: 64 + (i mod 8)*2 + (i/8)*32
    lda ui_t
    and #$07
    asl a
    clc
    adc #64
    sta oam_buf+2,x
    lda ui_t
    cmp #8
    bcc :+
    lda oam_buf+2,x
    clc
    adc #32
    sta oam_buf+2,x
:   lda IconAttr,y
    sta oam_buf+3,x
    ; tamanho grande para os sprites 8..17
    lda #$AA
    sta oam_buf+514
    sta oam_buf+515
    lda #$0A
    sta oam_buf+516
    rts
