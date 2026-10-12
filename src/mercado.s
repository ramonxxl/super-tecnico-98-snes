; =====================================================================
;  Mercado no estilo Elifoot: lista de transferencias, procurar em
;  qualquer clube e negociar (proposta, contraproposta, recusa)
; =====================================================================

MarketScreen:
    .a8
    .i16
    SCR 14
    jsr BeginScreen
    stz mk_menu
@menu:
    SCR 14
    jsr ClearBg3
    jsr UiReset             ; tira a faixa da lista de onde o jogador voltou
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_MK_MENU_T, 2, 1, 1
    PRINT TXT_CAIXA, 2, 4, 0
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_MK_OPT1, 8, 9, 0
    PRINT TXT_MK_OPT2, 8, 11, 0
    PRINT TXT_MK_OPT3, 8, 13, 0
    PRINT TXT_MK_DICA, 2, 17, 4
    PRINT TXT_MK_DICA2, 2, 18, 4
    PRINT TXT_VOLTAR_B, 2, 25, 4
    lda bright
    bpl :+
    jsr ShowScreen
:   lda #3
    sta menu_n
    lda #9
    sta menu_row0
    lda #2
    sta menu_step
    ldx #6
    stx arr_col
    lda mk_menu
    sta sel
    stz sel+1
    lda #6
    sta bm_col
    lda #26
    sta bm_w
    stz bm_pri
    lda #$FF
    sta bm_bad
    jsr MenuButtons
    jsr RunMenu
    bcs :+
    rts
:   lda sel
    sta mk_menu
    cmp #2
    bne :+
    rts
:   cmp #1
    beq @clubes
    jsr TransferList
    jmp @menu
@clubes:
    jsr ClubBrowse
    jmp @menu

; ---------------------------------------------------------------- lista de transferencias
TransferList:
    .a8
    .i16
    SCR 17
    lda #4
    sta mk_pos
@rebuild:
    lda mk_pos
    jsr BuildMarket
    stz sel
    stz sel+1
    stz top
    stz top+1
@redraw:
    SCR 17
    jsr UiReset             ; tira os botoes do menu / da tela anterior
    jsr MarketDraw
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_B
    beq :+
    rts
:   bit #KH_LEFT
    beq :+
    lda mk_pos
    beq @l
    dec mk_pos
    SFX SFX_CURSOR
    bra @rebuild
:   bit #KH_RIGHT
    beq :+
    lda mk_pos
    cmp #4
    bcs @l
    inc mk_pos
    SFX SFX_CURSOR
    bra @rebuild
:   bit #KH_UP
    beq :+
    lda sel
    beq @l
    dec sel
    jsr MkScroll
    bra @redraw
:   bit #KH_DOWN
    beq :+
    lda sel
    inc a
    cmp cnt
    bcs @l
    sta sel
    jsr MkScroll
    bra @redraw
:   lda pad_new
    bit #KL_A
    beq @l
    lda cnt
    beq @l
    A16
    lda sel
    and #$00FF
    asl a
    tax
    lda lst,x
    sta pid
    A8
    lda #1
    sta ng_listed
    lda sel
    pha
    jsr Negotiate
    pla
    bcc :+
    jmp @rebuild
:   sta sel
    SCR 17
    jmp @redraw

; ---------------------------------------------------------------- procurar nos clubes
ClubBrowse:
    .a8
    .i16
    SCR 18
    lda g_user
    jsr TeamDiv
    sta div
    stz div+1
    stz sel
    stz sel+1
@redraw:
    SCR 18
    jsr ClearBg3
    jsr UiReset
    PRINT TXT_CB_T, 2, 1, 1
    PRINT TXT_SERIE, 2, 3, 0
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_CB_COLS, 4, 5, 4
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
    lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp
    ply
    phy
    tya
    clc
    adc tmp
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    sta cs_team
    lda #$20
    sta txt_attr
    lda cs_team
    cmp g_user
    bne :+
    lda #($20 | (1<<2))
    sta txt_attr
:   lda cs_team
    jsr PrintTeam
    lda cs_team
    jsr TeamAvg
    ldy #4
    jsr PrintN8
    ply
    iny
    cpy #16
    bne @t
    PRINT TXT_CB_H, 2, 24, 4
    PRINT TXT_TAB_H2, 2, 25, 4
    lda #16
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
    bit #KH_B
    beq :+
    jsr OamClear
    rts
:   bit #KH_LEFT
    beq :+
    lda div
    beq @l
    dec div
    SFX SFX_CURSOR
    jmp @redraw
:   bit #KH_RIGHT
    beq :+
    lda div
    cmp #3
    bcs @l
    inc div
    SFX SFX_CURSOR
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
    SFX SFX_CURSOR
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
    SFX SFX_CURSOR
    jsr MenuRow
    jsr ArrowOn
    jsr PickShield
    jmp @l
:   lda pad_new
    bit #KL_A
    bne :+
    jmp @l
:   lda div
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
    cmp g_user
    bne :+
    SFX SFX_ERRO
    jmp @l
:   sta cs_team
    SFX SFX_OK
    jsr OamClear
    lda sel
    pha
    jsr ClubSquad
    pla
    sta sel
    jmp @redraw

; A = time -> A = forca media dos jogadores
TeamAvg:
    .a8
    .i16
    jsr SetTeam
    A16
    stz tmp4
    A8
    stz tmp3
    ldx pbase
    ldy #SQ
@l: lda f:P_STR,x
    beq @n
    A16
    and #$00FF
    clc
    adc tmp4
    sta tmp4
    A8
    inc tmp3
@n: inx
    dey
    bne @l
    lda tmp3
    bne :+
    lda #0
    rts
:   A16
    lda tmp4
    sta WRDIVL
    A8
    lda tmp3
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDDIVL
    rts

; elenco de outro clube (cs_team): escolher jogador e negociar
ClubSquad:
    .a8
    .i16
    SCR 19
    lda cs_team
    jsr SquadListT
    stz sel
    stz sel+1
    stz top
    stz top+1
@redraw:
    SCR 19
    jsr UiReset
    jsr ClubSquadDraw
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_B
    beq :+
    rts
:   bit #KH_UP
    beq :+
    lda sel
    beq @l
    dec sel
    jsr CsScroll
    bra @redraw
:   bit #KH_DOWN
    beq :+
    lda sel
    inc a
    cmp sq_n
    bcs @l
    sta sel
    jsr CsScroll
    bra @redraw
:   lda pad_new
    bit #KL_A
    beq @l
    lda sel
    A16
    and #$00FF
    tax
    A8
    lda sq_list,x
    A16
    and #$00FF
    clc
    adc pbase
    sta pid
    A8
    jsr IsListed
    lda #0
    rol a
    sta ng_listed
    jsr Negotiate
    bcc :+
    ; comprou: refaz a lista do clube
    lda cs_team
    jsr SquadListT
    stz sel
    stz top
    bra @redraw
:   lda cs_team
    jsr SetTeam
    bra @redraw

CsScroll:
    .a8
    .i16
    SFX SFX_CURSOR
    lda sel
    cmp top
    bcs :+
    sta top
:   lda top
    clc
    adc #16
    cmp sel
    bcs :+
    lda sel
    sec
    sbc #16
    sta top
:   rts

ClubSquadDraw:
    .a8
    .i16
    jsr ClearBg3
    lda cs_team
    jsr SetTeam
    ldx #(1*32+2)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    lda cs_team
    jsr PrintTeam
    lda #$20
    sta txt_attr
    ldx #.loword(TXT_SERIE_SP)
    jsr PrintStr
    lda cs_team
    jsr TeamDiv
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_CAIXA, 2, 2, 0
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_CS_COLS, 2, 4, 4
    ldy #0
@r: phy
    tya
    clc
    adc top
    cmp sq_n
    bcc :+
    jmp @skip
:   sta tmp6
    tya
    clc
    adc #5
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    inc a
    sta txt_pos
    lda tmp6
    and #$00FF
    tax
    A8
    lda sq_list,x
    A16
    and #$00FF
    clc
    adc pbase
    sta pid
    A8
    lda tmp6
    cmp sel
    bne :+
    lda #($20 | (1<<2))
    sta txt_attr
    lda #FONT_ARROW
    bra :++
:   lda #$20
    sta txt_attr
    lda #FONT_SPACE
:   jsr PrintChar
    ldx pid
    jsr PrintPos
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    jsr PrintPName
    ldx pid
    lda f:P_STR,x
    ldy #3
    jsr PrintN8
    ldx pid
    lda f:P_AGE,x
    ldy #3
    jsr PrintN8
    ldx pid
    jsr GetValue
    ldy #7
    jsr PrintN16
    ; marca de lista de transferencias
    jsr IsListed
    bcc @skip
    lda #($20 | (2<<2))
    sta txt_attr
    lda #FONT_STAR
    jsr PrintChar
@skip:
    ply
    iny
    cpy #17
    beq :+
    jmp @r
:   lda sel
    sec
    sbc top
    clc
    adc #5
    jsr UiBarOn
    PRINT TXT_CS_H, 1, 24, 4
    PRINT TXT_CS_H2, 1, 25, 4
    rts

; carry=1 se o jogador pid esta na lista de transferencias desta rodada
IsListed:
    .a8
    .i16
    A16
    lda pid
    asl a
    asl a
    asl a
    sec
    sbc pid
    sta tmp
    lda g_round
    and #$00FF
    sta tmp2
    asl a
    asl a
    asl a
    asl a
    sec
    sbc tmp2
    sec
    sbc tmp2
    sec
    sbc tmp2
    clc
    adc tmp
    clc
    adc g_season
    and #$001F
    A8
    bne :+
    sec
    rts
:   clc
    rts

; ---------------------------------------------------------------- negociacao
; negocia o jogador pid (ng_listed = 1 se esta na lista). carry=1 se comprou
Negotiate:
    .a8
    .i16
    SCR 20
    jsr UiReset             ; sem a faixa da lista por baixo
    ; clube vendedor
    A16
    lda pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    sta ng_team
    jsr SetTeam
    ; preco: valor de mercado; titular custa 60% a mais, reserva 25%
    ldx pid
    jsr GetValue
    A16
    sta ng_val
    A8
    stz ng_tit
    lda ng_listed
    bne @pct
    jsr AutoPick
    A16
    lda pid
    sec
    sbc pbase
    A8
    ldx #0
@t: cmp pick_out,x
    beq @tit
    inx
    cpx #11
    bne @t
    lda #125
    bra @pct2
@tit:
    lda #1
    sta ng_tit
    lda #160
    bra @pct2
@pct:
    lda #100
@pct2:
    sta m_b
    stz m_b+1
    A16
    lda ng_val
    A8
    jsr Percent
    A16
    sta ng_ask
    ; proposta inicial = valor; passo = 5% do valor (minimo 1)
    lda ng_val
    sta ng_off
    lsr a
    lsr a
    lsr a
    lsr a
    bne :+
    lda #1
:   sta ng_step
    A8
    jsr NgDraw
    ; elenco curto: o clube nao vende
    lda ng_team
    jsr SetTeam
    jsr TeamCount
    cmp #(MIN_ELENCO + 1)
    bcs @loop
    PRINT TXT_NG_PEQ, 2, 19, 3
    SFX SFX_ERRO
    jsr WaitAB
    clc
    rts
@loop:
    jsr NextFrame
    lda pad_new+1
    bit #KH_B
    beq :+
    clc
    rts
:   bit #KH_RIGHT
    beq :+
    A16
    lda ng_off
    clc
    adc ng_step
    bcs @maxv
    bra @chk
:
    .a8
    bit #KH_UP
    beq :+
    A16
    lda ng_step
    asl a
    asl a
    clc
    adc ng_off
    bcs @maxv
    bra @chk
:
    .a8
    bit #KH_LEFT
    beq :+
    A16
    lda ng_off
    sec
    sbc ng_step
    bcc @minv
    beq @minv
    bra @store
:
    .a8
    bit #KH_DOWN
    beq :+
    A16
    lda ng_step
    asl a
    asl a
    sta tmp
    lda ng_off
    sec
    sbc tmp
    bcc @minv
    beq @minv
    bra @store
:
    .a8
    lda pad_new
    bit #KL_A
    bne :+
    jmp @loop
:   jmp @offer
@chk:
    .a16
    cmp #60000
    bcc @store
@maxv:
    lda #60000
    bra @store
@minv:
    lda #1
@store:
    sta ng_off
    A8
    SFX SFX_CURSOR
    jsr NgOffer
    jmp @loop

@offer:
    lda #19
    jsr ClearRow
    lda #20
    jsr ClearRow
    A16
    lda ng_off
    cmp ng_ask
    A8
    bcc :+
    jmp @accept
:   ; perto do preco (75%): contraproposta
    A16
    lda ng_ask
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc ng_ask
    cmp ng_off
    A8
    beq @counter
    bcc @counter
    PRINT TXT_NG_RECUSA, 2, 19, 3
    SFX SFX_ERRO
    jmp @loop
@counter:
    PRINT TXT_NG_CONTRA, 2, 19, 1
    A16
    lda ng_ask
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_NG_CONTRA2, 2, 20, 0
    SFX SFX_OK
    jsr WaitAB
    pha
    lda #19
    jsr ClearRow
    lda #20
    jsr ClearRow
    pla
    cmp #0
    bne :+
    jmp @loop
:   A16
    lda ng_ask
    sta ng_off
    A8
    jsr NgOffer
@accept:
    ; dinheiro?
    A16
    lda ng_off
    A8
    jsr MoneyHas
    bcs :+
    PRINT TXT_SEM_DINHEIRO, 2, 19, 3
    SFX SFX_ERRO
    jmp @loop
:   lda g_user
    jsr MovePlayer
    bcs :+
    PRINT TXT_ELENCO_CHEIO, 2, 19, 3
    SFX SFX_ERRO
    jmp @loop
:   A16
    lda ng_off
    A8
    jsr MoneySub
    A16
    lda g_f_trans
    sec
    sbc ng_off
    sta g_f_trans
    lda g_f_trans+2
    sbc #0
    sta g_f_trans+2
    A8
    SFX SFX_MOEDA
    lda #23
    jsr ClearRow
    lda #24
    jsr ClearRow
    lda #25
    jsr ClearRow
    PRINT TXT_NG_ACEITA, 2, 19, 2
    PRINT TXT_NG_ACEITA2, 2, 20, 0
    PRINT TXT_CONTINUAR_A, 2, 25, 4
    jsr WaitAB
    sec
    rts

; tela da negociacao
NgDraw:
    .a8
    .i16
    jsr ClearBg3
    PRINT TXT_NG_T, 2, 1, 1
    ldx #(3*32+2)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    ldx pid
    jsr PrintPos
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    jsr PrintPName
    PRINT TXT_NG_CLUBE, 2, 4, 0
    lda ng_team
    jsr PrintTeam
    PRINT TXT_FORCA, 2, 5, 0
    ldx pid
    lda f:P_STR,x
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_IDADE_SP)
    jsr PrintStr
    ldx pid
    lda f:P_AGE,x
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_GOLS_SP)
    jsr PrintStr
    ldx pid
    lda f:P_GOL,x
    ldy #3
    jsr PrintN8
    PRINT TXT_NG_VALOR, 2, 7, 0
    A16
    lda ng_val
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_NG_SAL, 2, 8, 0
    ldx pid
    jsr GetSalary
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    lda ng_listed
    beq :+
    PRINT TXT_NG_LISTA, 2, 10, 2
    bra :++
:   lda ng_tit
    beq :+
    PRINT TXT_NG_TITULAR, 2, 10, 5
:   PRINT TXT_CAIXA, 2, 12, 0
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_NG_H, 2, 23, 4
    PRINT TXT_NG_H2, 2, 24, 4
    PRINT TXT_NG_H3, 2, 25, 4
; linha da proposta
NgOffer:
    .a8
    .i16
    PRINT TXT_NG_PROP, 2, 15, 1
    A16
    lda ng_off
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jmp PrintStr
