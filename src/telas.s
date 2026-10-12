; =====================================================================
;  Telas: infraestrutura, titulo, jogos salvos, nome do tecnico,
;  escolha do time
; =====================================================================

BG_NONE  = 0
BG_TITLE = 1
BG_MENU  = 2

; escurece a tela e apaga o texto (tela desligada ao final)
BeginScreen:
    .a8
    .i16
    jsr FadeOut
    jsr OamClear
    lda #$80
    sta bright
    jsr WaitFrame
    jsr ClearBg3
    PAL_LOAD IconPal, 160, 128      ; os escudinhos usam as cores dos icones
    jmp UiReset             ; mapa do BG1 de volta ao fundo (sem botoes nem faixa)

; carrega o fundo A (com a tela desligada)
LoadBg:
    .a8
    .i16
    cmp cur_bg
    bne :+
    rts
:   sta cur_bg
    lda #$80
    sta INIDISP
    sta VMAIN
    lda cur_bg
    cmp #BG_TITLE
    bne @m
    VRAM_LOAD TitleTiles, VRAM_BG1TILES, (TitleTiles_end - TitleTiles)
    PAL_LOAD TitlePal, 32, 32
    ldx #.loword(TitleMap)
    lda #^TitleMap
    bra @map
@m: VRAM_LOAD MenuTiles, VRAM_BG1TILES, (MenuTiles_end - MenuTiles)
    PAL_LOAD MenuPal, 32, 32
    ldx #.loword(MenuMap)
    lda #^MenuMap
@map:
    ; o mapa vai para a copia na RAM (os botoes sao desenhados por cima dela)
    stx bg_map
    sta bg_map+2
    jmp UiReset

; mostra a tela montada (envia o texto e clareia)
ShowScreen:
    .a8
    .i16
    lda #1
    sta bg3_dirty
    jsr WaitFrame
    jmp FadeIn

; escudo 32x32 do time A na posicao (tmp5 = x, tmp5+1 = y); shd_slot 0/1 = paleta e sprites
DrawShield:
    .a8
    .i16
    pha
    ; paleta do escudo: cores 1..4 da paleta de sprite shd_slot
    lda shd_slot
    A16
    and #$0001
    asl a
    asl a
    asl a
    asl a
    asl a                   ; *32 bytes
    tay
    A8
    pla
    A16
    and #$00FF
    asl a
    asl a
    tax
    lda f:TeamCol,x
    sta cgram_buf+260,y
    lda f:TeamCol+2,x
    sta cgram_buf+262,y
    lda #$0C63
    sta cgram_buf+258,y
    lda #$7FFF
    sta cgram_buf+264,y
    A8
    lda #1
    sta pal_dirty
    ; sprites 0-3 (slot 0) ou 4-7 (slot 1)
    lda shd_slot
    and #1
    asl a
    asl a
    asl a
    asl a
    A16
    and #$00FF
    tax
    A8
    lda shd_slot
    and #1
    asl a
    ora #$30
    sta tmp4                ; atributo (prioridade + paleta)
    ldy #0
@l: lda tmp5
    clc
    adc ShOffX,y
    sta oam_buf,x
    lda tmp5+1
    clc
    adc ShOffY,y
    sta oam_buf+1,x
    lda ShTile,y
    sta oam_buf+2,x
    lda tmp4
    sta oam_buf+3,x
    inx
    inx
    inx
    inx
    iny
    cpy #4
    bne @l
    lda shd_slot
    beq :+
    lda #$AA
    sta oam_buf+513
    rts
:   lda #$AA
    sta oam_buf+512
    rts
ShOffX: .byte 0, 16, 0, 16
ShOffY: .byte 0, 0, 16, 16
ShTile: .byte 0, 2, 32, 34

; seta na coluna arr_col, linha A
ArrowOn:
    .a8
    .i16
    pha
    jsr UiBarOn             ; faixa de selecao na linha
    pla
    jsr ArrowPos
    lda #($20 | (1<<2))
    sta txt_attr
    lda #FONT_ARROW
    jmp PrintChar
ArrowOff:
    .a8
    .i16
    pha
    jsr UiBarOff
    pla
    jsr ArrowPos
    lda #$20
    sta txt_attr
    lda #FONT_SPACE
    jmp PrintChar
ArrowPos:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc arr_col
    sta txt_pos
    A8
    rts

; linha do item sel = menu_row0 + sel*menu_step
MenuRow:
    .a8
    .i16
    lda sel
    sta WRMPYA
    lda menu_step
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYL
    clc
    adc menu_row0
    rts

; menu vertical: menu_n itens. carry=1 (A) / 0 (B). sel = item
RunMenu:
    .a8
    .i16
    jsr MenuMark
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_UP
    beq @nu
    jsr MenuUnmark
    lda sel
    bne :+
    lda menu_n
:   dec a
    sta sel
    SFX SFX_CURSOR
    jsr MenuMark
    bra @l
@nu:
    bit #KH_DOWN
    beq @nd
    jsr MenuUnmark
    lda sel
    inc a
    cmp menu_n
    bcc :+
    lda #0
:   sta sel
    SFX SFX_CURSOR
    jsr MenuMark
    bra @l
@nd:
    bit #KH_SEL
    beq :+
    lda menu_selok
    beq :+
    stz menu_selok
    lda #2
    sta menu_selok          ; avisa quem chamou: SELECT
    clc
    rts
:   lda pad_new+1
    bit #KH_B
    bne @b
    bit #KH_START
    bne @a
    lda pad_new
    bit #KL_A
    beq @l
@a: SFX SFX_OK
    sec
    rts
@b: clc
    rts

; ---------------------------------------------------------------- titulo
; A = 0 novo jogo, 1 continuar
TitleScreen:
    .a8
    .i16
    SCR 1
    jsr BeginScreen
    lda #BG_TITLE
    jsr LoadBg
    lda #SONG_TITULO
    jsr PlaySong
    PRINT TXT_TITULO_SUB, 7, 17, 1
    PRINT TXT_PRESS_START, 9, 21, 0
    PRINT TXT_CREDITO, 4, 26, 4
    jsr ShowScreen
    ; pisca "aperte start"
@w: jsr NextFrame
    lda frame
    and #$20
    beq @on
    lda #21
    jsr ClearRow
    bra @k
@on:
    PRINT TXT_PRESS_START, 9, 21, 0
@k: lda pad_new+1
    bit #KH_START
    bne @go
    lda pad_new
    bit #KL_A
    beq @w
@go:
    SFX SFX_OK
    lda #21
    jsr ClearRow
    PRINT TXT_NOVO_JOGO, 11, 20, 0
    PRINT TXT_CONTINUAR, 11, 22, 0
    lda #2
    sta menu_n
    lda #20
    sta menu_row0
    lda #2
    sta menu_step
    ldx #9
    stx arr_col
    stz sel
    stz sel+1
    ; dois botoes: NOVO JOGO em destaque
    lda #8
    sta bm_col
    lda #16
    sta bm_w
    stz bm_pri
    lda #$FF
    sta bm_bad
    jsr MenuButtons
@m: jsr RunMenu
    bcc @m
    lda sel
    rts

; ---------------------------------------------------------------- jogos salvos
; A = 0 (novo jogo) ou 1 (continuar). carry=1: slot_cur escolhido
SlotScreen:
    .a8
    .i16
    SCR 2
    sta tmp6
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_ESCOLHA_SLOT, 2, 3, 1
    lda #0
@s: sta slot_cur
    jsr SlotInfo            ; carry=1 se ocupado (le o cabecalho)
    lda slot_cur
    A16
    and #$00FF
    tax
    A8
    lda #0
    rol a
    sta slot_ok,x
    ; linha 7 + slot*3
    lda slot_cur
    asl a
    clc
    adc slot_cur
    clc
    adc #7
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #4
    sta txt_pos
    A8
    lda #$20
    sta txt_attr
    lda slot_cur
    clc
    adc #FONT_1
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    lda slot_cur
    A16
    and #$00FF
    tax
    A8
    lda slot_ok,x
    bne @used
    ldx #.loword(TXT_VAZIO)
    jsr PrintStr
    bra @nx
@used:
    lda si_team
    jsr PrintTeam
    lda #FONT_SPACE
    jsr PrintChar
    A16
    lda si_season
    sta num
    stz num+2
    A8
    lda #4
    sta num_w
    jsr PrintNum
    ldx #.loword(TXT_ROD_CURTA)
    jsr PrintStr
    lda si_round
    inc a
    cmp #31
    bcc :+
    lda #30
:   ldy #2
    jsr PrintN8
@nx:
    lda slot_cur
    inc a
    cmp #3
    bcs :+
    jmp @s
:   PRINT TXT_VOLTAR_B, 2, 25, 4
    jsr ShowScreen
    lda #3
    sta menu_n
    lda #7
    sta menu_row0
    lda #3
    sta menu_step
    ldx #2
    stx arr_col
    stz sel
    stz sel+1
    ; um cartao por jogo salvo
    lda #2
    sta bm_col
    lda #28
    sta bm_w
    lda #$FF
    sta bm_pri
    sta bm_bad
    jsr MenuButtons
@m: jsr RunMenu
    bcs :+
    clc
    rts
:   lda sel
    sta slot_cur
    A16
    and #$00FF
    tax
    A8
    lda tmp6
    bne @cont
    ; novo jogo: se ocupado, confirma
    lda slot_ok,x
    beq @ok
    ; acao critica: caixa de confirmacao
    jsr ConfirmOpen
    PRINT TXT_APAGAR, 5, 10, 3
    PRINT TXT_APAGAR2, 5, 12, 4
    jsr ConfirmAsk
    cmp #0
    bne @ok
    lda gm_mode             ; desistiu: redesenha a tela dos jogos salvos
    jmp SlotScreen
@ok:
    sec
    rts
@cont:
    lda slot_ok,x
    bne @ok
    SFX SFX_ERRO
    bra @m

; ---------------------------------------------------------------- nome do tecnico
NameEntry:
    .a8
    .i16
    SCR 3
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    lda #SONG_MENU
    jsr PlaySong
    ; nome comeca vazio
    ldx #0
    lda #FONT_SPACE
@c: sta g_coach,x
    inx
    cpx #10
    bne @c
    stz tmp6                ; tamanho
    PRINT TXT_NOME_T, 2, 3, 1
    PRINT TXT_NOME_H, 2, 22, 4
    PRINT TXT_NOME_H2, 2, 24, 4
    ; grade de letras (linhas 11,13,15; colunas 6,8,...)
    ldx #0
@g: stx tmp5
    jsr GridPos
    lda #$20
    sta txt_attr
    ldx tmp5
    lda NameGrid,x
    jsr PrintChar
    ldx tmp5
    inx
    cpx #30
    bne @g
    stz sel
    stz sel+1
    jsr ShowScreen
@draw:
    ; nome atual
    ldx #(7*32+11)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    lda #<g_coach
    sta txt_ptr
    lda #>g_coach
    sta txt_ptr+1
    stz txt_ptr+2
    ldy #10
    jsr PrintFixed
    jsr GridCursor
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_START
    beq :+
    jmp @done
:   bit #KH_B
    beq :+
    jsr NameDel
    bra @draw
:   bit #KH_UP
    beq @nu
    jsr GridCurOff
    lda sel
    sec
    sbc #10
    bcs :+
    adc #30
:   sta sel
    bra @draw
@nu:
    bit #KH_DOWN
    beq @nd
    jsr GridCurOff
    lda sel
    clc
    adc #10
    cmp #30
    bcc :+
    sbc #30
:   sta sel
    bra @draw
@nd:
    bit #KH_LEFT
    beq @nl
    jsr GridCurOff
    lda sel
    bne :+
    lda #30
:   dec a
    sta sel
    bra @draw
@nl:
    bit #KH_RIGHT
    beq @nr
    jsr GridCurOff
    lda sel
    inc a
    cmp #30
    bcc :+
    lda #0
:   sta sel
    jmp @draw
@nr:
    lda pad_new
    bit #KL_A
    beq @l
    lda sel
    cmp #28
    bne :+
    jsr NameDel
    jmp @draw
:   cmp #29
    beq @done
    ; acrescenta letra
    lda tmp6
    cmp #10
    bcs @full
    A16
    and #$00FF
    tay
    lda sel
    and #$00FF
    tax
    A8
    lda NameGrid,x
    sta g_coach,y
    inc tmp6
    SFX SFX_CURSOR
    jmp @draw
@full:
    SFX SFX_ERRO
    jmp @draw
@done:
    lda tmp6
    bne :+
    ; sem nome: "TECNICO"
    ldx #0
@d: lda DefaultCoach,x
    sta g_coach,x
    inx
    cpx #10
    bne @d
:   SFX SFX_OK
    rts

NameDel:
    .a8
    .i16
    lda tmp6
    beq :+
    dec tmp6
    lda tmp6
    A16
    and #$00FF
    tax
    A8
    lda #FONT_SPACE
    sta g_coach,x
:   rts

; X = celula (0..29) -> txt_pos
GridPos:
    .a8
    .i16
    txa
    sta WRDIVL
    stz WRDIVL+1
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ; linha = 11 + q*2, coluna = 6 + r*2
    lda RDDIVL
    asl a
    clc
    adc #11
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    sta tmp
    lda RDMPYL
    and #$00FF
    asl a
    clc
    adc #6
    clc
    adc tmp
    sta txt_pos
    A8
    rts
GridCursor:
    .a8
    .i16
    ldx sel
    jsr GridPos
    A16
    dec txt_pos
    A8
    lda #($20 | (1<<2))
    sta txt_attr
    lda #FONT_ARROW
    jmp PrintChar
GridCurOff:
    .a8
    .i16
    ldx sel
    jsr GridPos
    A16
    dec txt_pos
    A8
    lda #$20
    sta txt_attr
    lda #FONT_SPACE
    jmp PrintChar

; ---------------------------------------------------------------- escolher time
; escolhe o time -> g_user
PickTeam:
    .a8
    .i16
    SCR 4
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    lda #3
    sta div
    stz div+1
    stz sel
    stz sel+1
@redraw:
    jsr ClearBg3
    PRINT TXT_ESCOLHA_TIME, 2, 1, 1
    PRINT TXT_SERIE, 2, 3, 0
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_PICK_COLS, 4, 5, 4
    ; 16 times da divisao
    ldy #0
@t: phy
    tya
    clc
    adc #6
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #4
    sta txt_pos
    A8
    lda #$20
    sta txt_attr
    lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp
    pla
    pha
    clc
    adc tmp
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    sta tmp5
    jsr PrintTeam
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    ; fama em estrelas (1 a 10 -> 1 a 5)
    lda tmp5
    A16
    and #$00FF
    tax
    A8
    lda f:TeamFame,x
    inc a
    lsr a
    sta tmp4
    lda #($20 | (1<<2))
    sta txt_attr
@st:
    lda #FONT_STAR
    jsr PrintChar
    dec tmp4
    bne @st
    ply
    iny
    cpy #16
    bne @t
    PRINT TXT_PICK_H, 2, 24, 4
    PRINT TXT_PICK_H2, 2, 25, 4
    lda bright
    bpl :+
    jsr ShowScreen
:   lda #16
    sta menu_n
    lda #6
    sta menu_row0
    lda #1
    sta menu_step
    ldx #2
    stx arr_col
    jsr MenuRow
    jsr ArrowOn
    jsr PickShield
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_LEFT
    beq :+
    lda div
    beq @l
    dec div
    jmp @redraw
:   bit #KH_RIGHT
    beq :+
    lda div
    cmp #3
    bcs @l
    inc div
    jmp @redraw
:   bit #KH_UP
    beq :+
    jsr MenuRow
    jsr ArrowOff
    lda sel
    bne @u1
    lda #16
@u1:
    dec a
    sta sel
    jsr MenuRow
    jsr ArrowOn
    jsr PickShield
    bra @l
:   bit #KH_DOWN
    beq :+
    jsr MenuRow
    jsr ArrowOff
    lda sel
    inc a
    and #$0F
    sta sel
    jsr MenuRow
    jsr ArrowOn
    jsr PickShield
    bra @l
:   lda pad_new
    bit #KL_X
    beq :+
    ; sorteia um time da serie D
    lda #16
    jsr RandBelow
    clc
    adc #48
    bra @pick
:   bit #KL_A
    beq @l
    lda div
    asl a
    asl a
    asl a
    asl a
    clc
    adc sel
@pick:
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    sta g_user
    SFX SFX_OK
    rts

; escudo do time sob o cursor na escolha de time
PickShield:
    .a8
    .i16
    lda div
    asl a
    asl a
    asl a
    asl a
    clc
    adc sel
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    pha
    lda #216
    sta tmp5
    lda #56
    sta tmp5+1
    pla
    jmp DrawShield

DefaultCoach: .byte FONT_LT, FONT_LE, FONT_LC, FONT_LN, FONT_LI, FONT_LC, FONT_LO, FONT_SPACE, FONT_SPACE, FONT_SPACE
