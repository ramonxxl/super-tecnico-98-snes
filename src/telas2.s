; =====================================================================
;  Telas novas: treino, Copa do Brasil, historico, financas e estadio
; =====================================================================

; ---------------------------------------------------------------- treino
TrainScreen:
    .a8
    .i16
    SCR 21
    jsr BeginScreen
    PRINT TXT_TREINO_T, 2, 1, 1
    PRINT TXT_TR_0, 6, 5, 0
    PRINT TXT_TR_0D, 6, 6, 4
    PRINT TXT_TR_1, 6, 8, 0
    PRINT TXT_TR_1D, 6, 9, 4
    PRINT TXT_TR_2, 6, 11, 0
    PRINT TXT_TR_2D, 6, 12, 4
    PRINT TXT_TR_3, 6, 14, 0
    PRINT TXT_TR_3D, 6, 15, 4
    ; marca o treino atual
    lda g_train
    asl a
    clc
    adc g_train
    clc
    adc #5
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
    lda #($20 | (2<<2))
    sta txt_attr
    lda #FONT_STAR
    jsr PrintChar
    ; ultimo resultado
    lda train_n
    beq :+
    PRINT TXT_TR_ULT, 2, 18, 2
    ldx train_pid
    jsr PrintPName
    lda train_n
    cmp #2
    bcc :+
    PRINT TXT_TR_MAIS, 2, 19, 4
    lda train_n
    dec a
    ldy #2
    jsr PrintN8
:   PRINT TXT_VOLTAR_B, 2, 25, 4
    jsr ShowScreen
    lda #4
    sta menu_n
    lda #5
    sta menu_row0
    lda #3
    sta menu_step
    ldx #2
    stx arr_col
    lda g_train
    sta sel
    stz sel+1
    jsr RunMenu
    bcc :+
    lda sel
    sta g_train
:   rts

; ---------------------------------------------------------------- copa do brasil
CupScreen:
    .a8
    .i16
    SCR 22
    jsr BeginScreen
    PRINT TXT_COPA_T, 2, 1, 1
    lda cup_phase
    cmp #6
    bcc :+
    ; encerrada: campeao
    PRINT TXT_CAMPEAO_COPA, 2, 4, 2
    lda cup_champ
    jsr PrintTeam
    lda #$20
    sta tmp5
    lda #64
    sta tmp5+1
    stz shd_slot
    lda cup_champ
    jsr DrawShield
    jmp @fim
:   A16
    and #$00FF
    asl a
    tax
    lda CupPhaseTxt,x
    tax
    A8
    jsr PrintStr
    PRINT TXT_COPA_SPC, 2, 2, 4
    ldx #.loword(TXT_IDA_JOGADA)
    lda cup_leg
    bne :+
    ldx #.loword(TXT_IDA_FALTA)
:   jsr PrintStr
    ; jogos da fase: 2 colunas de 16
    lda cup_n
    lsr a
    sta cs_cnt              ; jogos
    ldx #0
@k: stx tmp6
    txa
    cmp cs_cnt
    bcc :+
    jmp @fim
:   ; linha = 4 + (k mod 16), coluna 2 ou 17
    and #$0F
    clc
    adc #4
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #2
    sta txt_pos
    A8
    lda tmp6
    cmp #16
    bcc :+
    A16
    lda txt_pos
    clc
    adc #15
    sta txt_pos
    A8
:   ; cor: jogo do usuario em amarelo
    A16
    lda tmp6
    asl a
    tax
    A8
    lda #$20
    sta txt_attr
    lda f:CUP_LIST,x
    cmp g_user
    beq :+
    lda f:CUP_LIST+1,x
    cmp g_user
    bne :++
:   lda #($20 | (1<<2))
    sta txt_attr
:   phx
    lda f:CUP_LIST,x
    jsr PrintAbbr
    lda #FONT_SPACE
    jsr PrintChar
    plx
    phx
    lda cup_leg
    beq @semida
    lda f:CUP_G1,x
    ldy #1
    jsr PrintN8
    lda #FONT_MINUS
    jsr PrintChar
    plx
    phx
    lda f:CUP_G1+1,x
    ldy #1
    jsr PrintN8
    bra @vis
@semida:
    lda #FONT_SPACE
    jsr PrintChar
    lda #FONT_X
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
@vis:
    lda #FONT_SPACE
    jsr PrintChar
    plx
    lda f:CUP_LIST+1,x
    jsr PrintAbbr
    ldx tmp6
    inx
    jmp @k
@fim:
    PRINT TXT_COPA_PREMIO, 2, 22, 4
    PRINT TXT_TAB_B, 2, 25, 4
    jsr ShowScreen
@w: jsr NextFrame
    lda pad_new+1
    bit #KH_B
    bne @x
    lda pad_new
    bit #KL_A
    beq @w
@x: rts

; ---------------------------------------------------------------- historico
HistoryScreen:
    .a8
    .i16
    SCR 23
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_HIST_T, 2, 1, 1
    ldx #(1*32+12)
    stx txt_pos
    lda #$20
    sta txt_attr
    lda #<g_coach
    sta txt_ptr
    lda #>g_coach
    sta txt_ptr+1
    stz txt_ptr+2
    ldy #10
    jsr PrintFixed
    PRINT TXT_CR_REP, 2, 3, 0
    lda c_rep
    ldy #3
    jsr PrintN8
    ldx #.loword(TXT_CR_CLUBES)
    jsr PrintStr
    lda c_clubs
    ldy #2
    jsr PrintN8
    PRINT TXT_CR_J, 2, 4, 0
    A16
    lda c_j
    A8
    ldy #4
    jsr PrintN16
    ldx #.loword(TXT_CR_V)
    jsr PrintStr
    A16
    lda c_v
    A8
    ldy #3
    jsr PrintN16
    ldx #.loword(TXT_CR_E)
    jsr PrintStr
    A16
    lda c_e
    A8
    ldy #3
    jsr PrintN16
    ldx #.loword(TXT_CR_D)
    jsr PrintStr
    A16
    lda c_d
    A8
    ldy #3
    jsr PrintN16
    PRINT TXT_CR_UP, 2, 6, 0
    lda c_up
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_CR_DOWN)
    jsr PrintStr
    lda c_down
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_CR_FIRED)
    jsr PrintStr
    lda c_fired
    ldy #2
    jsr PrintN8
    PRINT TXT_HIST_TIT, 2, 5, 0
    lda g_titles
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_HIST_COPAS)
    jsr PrintStr
    lda g_cups
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_HIST_TEMP)
    jsr PrintStr
    lda g_seasons
    ldy #3
    jsr PrintN8
    lda hist_n
    bne :+
    PRINT TXT_HIST_VAZIO, 2, 9, 4
    jmp @fim
:   PRINT TXT_HIST_COLS, 2, 8, 4
    ldx #0
@e: stx tmp6
    txa
    cmp hist_n
    bcc :+
    jmp @fim
:   clc
    adc #9
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #2
    sta txt_pos
    lda tmp6
    asl a
    sta tmp
    asl a
    asl a
    clc
    adc tmp                 ; *10
    sta tmp5
    tax
    lda f:HIST,x
    sta num
    stz num+2
    A8
    lda #$20
    sta txt_attr
    lda #4
    sta num_w
    jsr PrintNum
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    ldx tmp5
    lda f:HIST+2,x          ; campeao da serie A
    jsr PrintAbbr
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    jsr PrintChar
    ldx tmp5
    lda f:HIST+6,x          ; copa
    cmp #$FF
    beq :+
    jsr PrintAbbr
    bra :++
:   lda #FONT_MINUS
    jsr PrintChar
    jsr PrintChar
    jsr PrintChar
:   lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    jsr PrintChar
    lda #($20 | (1<<2))
    sta txt_attr
    ldx tmp5
    lda f:HIST+7,x          ; seu time
    jsr PrintAbbr
    lda #FONT_SPACE
    jsr PrintChar
    ldx tmp5
    lda f:HIST+9,x
    ldy #2
    jsr PrintN8
    lda #FONT_ORD
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    ldx tmp5
    lda f:HIST+8,x
    clc
    adc #FONT_LA
    jsr PrintChar
    ldx tmp6
    inx
    jmp @e
@fim:
    PRINT TXT_CR_H, 2, 25, 4
    jsr ShowScreen
@w: jsr NextFrame
    lda pad_new+1
    bit #KH_B
    bne @x
    lda pad_new
    bit #KL_A
    bne @x
    bit #KL_X
    beq @w
    jsr Resign
    bcs @x
    jmp HistoryScreen
@x: rts

; ---------------------------------------------------------------- financas e estadio
EXP_SEATS = 2000
EXP_COST  = 1000

FinanceScreen:
    .a8
    .i16
    SCR 15
    jsr BeginScreen
    stz sel
    stz sel+1
@redraw:
    jsr FinanceDraw
    lda bright
    bpl :+
    jsr ShowScreen
:   lda #4
    sta menu_n
    lda #19
    sta menu_row0
    lda #1
    sta menu_step
    ldx #1
    stx arr_col
    jsr MenuRow
    jsr ArrowOn
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
    SFX SFX_CURSOR
    bra @redraw
:   bit #KH_DOWN
    beq :+
    lda sel
    cmp #3
    bcs @l
    inc sel
    SFX SFX_CURSOR
    bra @redraw
:   lda sel
    bne @acoes
    ; ingresso: setas
    lda pad_new+1
    bit #KH_LEFT
    beq :+
    lda g_ticket
    cmp #2
    bcc @l
    dec g_ticket
    SFX SFX_CURSOR
    jmp @redraw
:   bit #KH_RIGHT
    beq @l
    lda g_ticket
    cmp #200
    bcs @l
    inc g_ticket
    SFX SFX_CURSOR
    jmp @redraw
@acoes:
    lda pad_new
    bit #KL_A
    beq @l
    lda sel
    cmp #1
    bne :+
    jsr Expand
    jmp @redraw
:   cmp #2
    bne :+
    jsr LoanTake
    jmp @redraw
:   jsr LoanPay
    jmp @redraw

; amplia o estadio do usuario
Expand:
    .a8
    .i16
    A16
    lda g_user
    and #$00FF
    asl a
    tax
    lda f:T_CAP,x
    cmp #(65000 - EXP_SEATS)
    A8
    bcc :+
    ldx #.loword(TXT_T_ESTADIO_MAX)
    lda #STY_BAD
    jmp UiToast
:   jsr ConfirmOpen
    PRINT TXT_C_AMPLIAR, 5, 10, 1
    PRINT TXT_OP_AMPLIAR, 5, 12, 4
    jsr ConfirmAsk
    cmp #0
    bne :+
    rts
:   A16
    lda #EXP_COST
    A8
    jsr MoneyHas
    bcs :+
    SFX SFX_ERRO
    ldx #.loword(TXT_SEM_DINHEIRO)
    lda #STY_BAD
    jmp UiToast
:   A16
    lda g_user
    and #$00FF
    asl a
    tax
    lda f:T_CAP,x
    clc
    adc #EXP_SEATS
    sta f:T_CAP,x
    lda #EXP_COST
    A8
    jsr MoneySub
    SFX SFX_MOEDA
    ldx #.loword(TXT_T_AMPLIADO)
    lda #STY_OK
    jmp UiToast

; limite e parcela do emprestimo -> tmp4 (limite), tmp5 (parcela = limite/10)
LoanInfo:
    .a8
    .i16
    lda g_user
    jsr TeamDiv
    A16
    and #$00FF
    asl a
    tax
    lda DivLoan,x
    sta tmp4
    sta d_n
    stz d_n+2
    lda #10
    sta d_d
    A8
    jsr Div32
    A16
    lda d_q
    sta tmp5
    A8
    rts

LoanTake:
    .a8
    .i16
    jsr LoanInfo
    A16
    lda g_loan
    clc
    adc tmp5
    cmp tmp4
    A8
    beq :+
    bcc :+
    ldx #.loword(TXT_T_LIMITE)
    lda #STY_BAD
    jmp UiToast
:   jsr ConfirmOpen
    PRINT TXT_C_EMPRESTIMO, 5, 10, 1
    PRINT TXT_C_JUROS, 5, 12, 4
    jsr ConfirmAsk
    cmp #0
    bne :+
    rts
:   jsr LoanInfo
    A16
    lda g_loan
    clc
    adc tmp5
    sta g_loan
    lda tmp5
    A8
    jsr MoneyAdd
    SFX SFX_MOEDA
    ldx #.loword(TXT_T_EMPRESTADO)
    lda #STY_OK
    jmp UiToast

LoanPay:
    .a8
    .i16
    jsr LoanInfo
    A16
    lda g_loan
    A8
    bne :+
    ldx #.loword(TXT_T_SEM_DIVIDA)
    lda #STY_BAD
    jmp UiToast
:   A16
    lda g_loan
    cmp tmp5
    bcs :+
    sta tmp5                ; paga o que falta
:   lda tmp5
    A8
    jsr MoneyHas
    bcs :+
    SFX SFX_ERRO
    ldx #.loword(TXT_SEM_DINHEIRO)
    lda #STY_BAD
    jmp UiToast
:   A16
    lda g_loan
    sec
    sbc tmp5
    sta g_loan
    lda tmp5
    A8
    jsr MoneySub
    SFX SFX_MOEDA
    ldx #.loword(TXT_T_PAGO)
    lda #STY_OK
    jmp UiToast

FinanceDraw:
    .a8
    .i16
    jsr ClearBg3
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_FINANCAS_T, 2, 1, 1
    PRINT TXT_CAIXA, 2, 3, 1
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_ULTIMA_ROD, 2, 4, 2
    PRINT TXT_F_TV, 2, 5, 0
    A16
    lda g_f_tv
    A8
    ldy #7
    jsr PrintN16
    PRINT TXT_F_BIL, 2, 6, 0
    A16
    lda g_f_bil
    A8
    ldy #7
    jsr PrintN16
    PRINT TXT_PUBLICO, 4, 7, 4
    A16
    lda g_att
    A8
    ldy #6
    jsr PrintN16
    PRINT TXT_F_SAL, 2, 8, 0
    A16
    lda g_f_sal
    A8
    ldy #7
    jsr PrintN16
    PRINT TXT_F_JUROS, 2, 9, 0
    A16
    lda g_juros
    A8
    ldy #7
    jsr PrintN16
    PRINT TXT_F_COPA, 2, 10, 0
    A16
    lda g_cupprize
    A8
    ldy #7
    jsr PrintN16
    PRINT TXT_TEMP_T, 2, 12, 2
    PRINT TXT_F_TRANS, 2, 13, 0
    ldx #g_f_trans
    ldy #7
    jsr PrintS32
    PRINT TXT_FOLHA, 2, 14, 0
    lda g_user
    jsr SetTeam
    jsr TeamSalaries
    ldy #7
    jsr PrintN16
    PRINT TXT_CAPACIDADE, 2, 16, 0
    A16
    lda g_user
    and #$00FF
    asl a
    tax
    lda f:T_CAP,x
    A8
    ldy #6
    jsr PrintN16
    PRINT TXT_EMPRESTIMO, 2, 17, 0
    A16
    lda g_loan
    A8
    ldy #6
    jsr PrintN16
    jsr LoanInfo
    ldx #.loword(TXT_LIMITE)
    jsr PrintStr
    A16
    lda tmp4
    A8
    ldy #5
    jsr PrintN16
    ; opcoes
    PRINT TXT_OP_INGRESSO, 3, 19, 0
    lda g_ticket
    ldy #3
    jsr PrintN8
    ldx #.loword(TXT_NORMAL)
    jsr PrintStr
    lda g_user
    jsr TeamDiv
    A16
    and #$00FF
    tax
    A8
    lda DivTicket,x
    ldy #2
    jsr PrintN8
    PRINT TXT_OP_AMPLIAR, 3, 20, 0
    PRINT TXT_OP_PEDIR, 3, 21, 0
    jsr LoanInfo
    A16
    lda tmp5
    A8
    ldy #5
    jsr PrintN16
    PRINT TXT_OP_PAGAR, 3, 22, 0
    A16
    lda tmp5
    A8
    ldy #5
    jsr PrintN16
    PRINT TXT_FIN_H, 2, 24, 4
    PRINT TXT_FIN_H2, 2, 25, 4
    rts
