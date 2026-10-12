; =====================================================================
;  Carreira do tecnico, meta da diretoria, premios da temporada,
;  convocacoes, calendario e escudinhos nas cores dos clubes
; =====================================================================

; ---------------------------------------------------------------- escudinhos (sprites 8x8)
; cada escudinho usa um par de cores proprio dentro das paletas de sprite 2..4
; (7 pares por paleta). Vaga crest_n 0..15, time A, posicao tmp5 (x) / tmp5+1 (y).
DrawCrest:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    asl a
    sta ui_t                ; time * 4 (duas cores de 16 bits)
    lda crest_n
    and #$00FF
    tay
    asl a
    tax
    lda CrestCg,x           ; posicao da primeira cor no buffer de paletas
    sta lptr
    ldx ui_t
    lda f:TeamCol,x
    sta (lptr)
    lda f:TeamCol+2,x
    ldy #2
    sta (lptr),y
    A8
    ; contorno escuro (cor 15) nas tres paletas
    A16
    lda #$0421
    sta cgram_buf + (128+2*16+15)*2
    sta cgram_buf + (128+3*16+15)*2
    sta cgram_buf + (128+4*16+15)*2
    ; sprite 18 + vaga
    lda crest_n
    and #$00FF
    tay
    clc
    adc #18
    asl a
    asl a
    tax
    A8
    lda tmp5
    sta oam_buf,x
    lda tmp5+1
    sta oam_buf+1,x
    lda CrestVar,y
    clc
    adc #128
    sta oam_buf+2,x
    lda CrestAttr,y
    sta oam_buf+3,x
    lda #1
    sta pal_dirty
    rts
; vaga -> variante do tile (par de cores), atributo (paleta) e posicao no buffer de cores
CrestVar:  .byte 0,1,2,3,4,5,6, 0,1,2,3,4,5,6, 0,1
CrestAttr: .byte $34,$34,$34,$34,$34,$34,$34, $36,$36,$36,$36,$36,$36,$36, $38,$38
CrestCg:
    .repeat 16, n
    .word cgram_buf + (128 + (2 + n/7)*16 + (n .mod 7)*2 + 1)*2
    .endrepeat

; esconde os 16 escudinhos
CrestClear:
    .a8
    .i16
    ldx #(18*4)
    lda #$F0
@l: sta oam_buf+1,x
    inx
    inx
    inx
    inx
    cpx #(34*4)
    bne @l
    rts

; escudinho do time A na coluna tmp5 / linha tmp5+1 (de texto); usa a vaga crest_n e avanca
CrestAt:
    .a8
    .i16
    pha
    lda tmp5
    asl a
    asl a
    asl a
    sta tmp5
    lda tmp5+1
    asl a
    asl a
    asl a
    dec a
    sta tmp5+1
    pla
    jsr DrawCrest
    inc crest_n
    rts

; par de escudinhos de um jogo: A = jogo na tela (0..7), tmp6 = linha de texto,
; fx_h / fx_a = times (ao lado do placar: coluna 13 e coluna tmp4)
RowCrests:
    .a8
    .i16
    asl a
    sta crest_n
    lda tmp6
    sta tmp5+1
    lda #13
    sta tmp5
    lda fx_h
    jsr CrestAt
    lda tmp6
    sta tmp5+1
    lda tmp4
    sta tmp5
    lda fx_a
    jmp CrestAt

; escudinho na classificacao: A = time, Y = linha da tabela (0..15)
TableCrest:
    .a8
    .i16
    pha
    tya
    sta crest_n
    clc
    adc #4
    sta tmp5+1
    lda #3
    sta tmp5
    pla
    jmp CrestAt

; escudinhos dos 8 jogos mostrados na partida (linhas 10..17)
MatchCrests:
    .a8
    .i16
    jsr CrestClear
    ldy #0
@l: phy
    tya
    clc
    adc #10
    sta tmp6
    tya
    clc
    adc m_disp
    asl a
    A16
    and #$00FF
    tax
    A8
    lda m_team,x
    cmp #$FF
    beq @n
    sta fx_h
    lda m_team+1,x
    sta fx_a
    lda #18
    sta tmp4
    pla
    pha
    jsr RowCrests
@n: ply
    iny
    cpy #8
    bne @l
    rts

; L / R durante a partida: mostra os jogos de outra serie (A = +8 ou -8)
MatchPage:
    .a8
    .i16
    clc
    adc m_disp
    bmi @r
    cmp #32
    bcs @r
    sta tmp
    asl a
    A16
    and #$00FF
    tax
    A8
    lda m_team,x
    cmp #$FF
    beq @r
    lda tmp
    sta m_disp
    SFX SFX_CURSOR
    jsr DrawMatchList
    lda #1
    sta bg3_dirty
@r: rts

; teclas L / R na tela da partida
MatchKeys:
    .a8
    .i16
    lda pad_new
    bit #KL_L
    beq :+
    lda #$F8
    jmp MatchPage
:   bit #KL_R
    beq :+
    lda #8
    jmp MatchPage
:   rts

; ---------------------------------------------------------------- reputacao e carreira
; A = variacao (com sinal) da reputacao, limitada a 0..100
RepAdd:
    .a8
    .i16
    clc
    adc c_rep
    bmi @z
    cmp #101
    bcc :+
    lda #100
:   sta c_rep
    rts
@z: stz c_rep
    rts

; A = serie (0 = A ... 3 = D) em que a reputacao permite trabalhar
RepDiv:
    .a8
    .i16
    lda c_rep
; idem, para a reputacao A
RepDivA:
    cmp #75
    bcc :+
    lda #0
    rts
:   cmp #50
    bcc :+
    lda #1
    rts
:   cmp #25
    bcc :+
    lda #2
    rts
:   lda #3
    rts

; serie das propostas quando o tecnico sai do clube: a da reputacao, mas nunca
; acima da serie atual. A = serie
JobDiv:
    .a8
    .i16
    lda g_user
    jsr TeamDiv
    sta tmp
    jsr RepDiv
    cmp tmp
    bcs :+
    lda tmp
:   rts

; resultado do jogo do usuario na carreira: A = 0 derrota, 1 empate, 2 vitoria
CareerResult:
    .a8
    .i16
    A16
    inc c_j
    A8
    cmp #2
    bne :+
    A16
    inc c_v
    A8
    lda #1
    jmp RepAdd
:   cmp #1
    bne :+
    A16
    inc c_e
    A8
    rts
:   A16
    inc c_d
    A8
    lda #$FF
    jmp RepAdd

; ---------------------------------------------------------------- meta da diretoria
; meta = posicao do elenco na serie (pela forca media) + 1, no maximo 12
CalcGoal:
    .a8
    .i16
    lda g_user
    jsr TeamAvg
    sta tmp6+1              ; forca media do usuario
    lda g_user
    jsr TeamDiv
    asl a
    asl a
    asl a
    asl a
    sta tmp6
    lda #1
    sta g_goal
    ldy #0
@l: phy
    tya
    clc
    adc tmp6
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    cmp g_user
    beq @n
    jsr TeamAvg
    cmp tmp6+1
    bcc @n
    beq @n
    inc g_goal
@n: ply
    iny
    cpy #16
    bne @l
    inc g_goal
    lda g_goal
    cmp #13
    bcc :+
    lda #12
    sta g_goal
:   rts

; ---------------------------------------------------------------- convocacoes
; os craques (forca 46+) vao para a selecao: perdem o proximo jogo e voltam animados
Convoca:
    .a8
    .i16
    stz sel_n
    stz tmp4                ; time
    ldx #0
@t: ldy #SQ
@p: lda f:P_STR,x
    cmp #46
    bcc @n
    lda f:P_OUT,x
    bne @n
    lda #$21                ; 1 jogo fora, marca "selecao"
    sta f:P_OUT,x
    lda f:P_MOR,x
    clc
    adc #8
    cmp #96
    bcc :+
    lda #95
:   sta f:P_MOR,x
    lda tmp4
    cmp g_user
    bne @n
    inc sel_n
@n: inx
    dey
    bne @p
    inc tmp4
    cpx #NP
    bne @t
    rts

; depois de uma rodada da liga: convites de clubes maiores conforme a reputacao
MidInvite:
    .a8
    .i16
    lda m_iscup
    bne @r
    lda g_round
    cmp #6
    bcc @r
    cmp #25
    bcs @r
    lda g_user
    jsr TeamDiv
    sta tmp6
    beq @r
    ; no meio da temporada o convite exige reputacao com folga (10 pontos)
    lda c_rep
    sec
    sbc #10
    bcc @r
    jsr RepDivA
    cmp tmp6
    bcs @r
    lda #10
    jsr RandBelow
    cmp #0
    bne @r
    stz job_fired
    lda tmp6
    dec a
    jsr MakeJobs
    jsr JobScreen
@r: rts

; novo jogo (ou jogo salvo antigo): carreira zerada, reputacao pela serie do clube
CareerInit:
    .a8
    .i16
    ldx #0
@z: stz c_rep,x
    inx
    cpx #(c_clubs + 1 - c_rep)
    bne @z
    lda g_user
    jsr TeamDiv
    sta tmp
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp                 ; * 17
    sta tmp
    lda #72
    sec
    sbc tmp                 ; A 72, B 55, C 38, D 21
    sta c_rep
    rts

; fim da temporada: acessos, quedas e meta da diretoria (tmp6 = serie nova)
SeasonCareer:
    .a8
    .i16
    lda tmp6
    cmp u_div
    beq @same
    bcc @up
    inc c_down
    inc c_fired
    lda #$F6
    jmp RepAdd
@up:
    inc c_up
    lda #8
    jsr RepAdd
    bra @meta
@same:
    lda u_pos
    cmp #1
    bne @meta
    lda #10
    jsr RepAdd
@meta:
    lda g_goal
    cmp u_pos
    bcc @falhou
    PRINT TXT_META_OK, 2, 21, 2
    lda #5
    jsr RepAdd
    lda g_conf
    clc
    adc #10
    cmp #101
    bcc :+
    lda #100
:   sta g_conf
    rts
@falhou:
    PRINT TXT_META_X, 2, 21, 3
    lda #$FD
    jsr RepAdd
    lda g_conf
    sec
    sbc #15
    bcc :+
    cmp #10
    bcs :++
:   lda #10
:   sta g_conf
    rts

; estatisticas do jogo do usuario no resumo (linha 11)
MatchStats:
    .a8
    .i16
    PRINT TXT_ST_FIN, 2, 11, 4
    lda m_shots
    ldy #2
    jsr PrintN8
    lda #FONT_X
    jsr PrintChar
    lda m_shots+1
    ldy #1
    cmp #10
    bcc :+
    iny
:   jsr PrintN8
    ldx #.loword(TXT_ST_POSSE)
    jsr PrintStr
    ; posse do mandante: 50 + 3 * (diferenca de finalizacoes), entre 35 e 65
    lda m_shots
    sec
    sbc m_shots+1
    bpl @pos
    cmp #$FB
    bcs @ok
    lda #$FB
    bra @ok
@pos:
    cmp #6
    bcc @ok
    lda #5
@ok:
    sta tmp
    asl a
    clc
    adc tmp
    clc
    adc #50
    pha
    ldy #2
    jsr PrintN8
    lda #FONT_PCT
    jsr PrintChar
    lda #FONT_X
    jsr PrintChar
    pla
    eor #$FF
    sec
    adc #100                ; 100 - posse do mandante
    ldy #2
    jsr PrintN8
    lda #FONT_PCT
    jmp PrintChar

; ---------------------------------------------------------------- calendario
; lista as proximas datas do usuario (linhas 4..17)
CalendarDraw:
    .a8
    .i16
    jsr CrestClear
    lda div
    pha
    PRINT TXT_CAL_T, 1, 1, 1
    lda g_round
    sta cal_r
    lda g_date
    sta tmp6
    lda #4
    sta tmp6+1
@l: lda tmp6
    cmp #CAL_N
    bcc :+
    jmp @fim
:   lda tmp6+1
    cmp #18
    bcc :+
    jmp @fim
:   A16
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
    and #$00FF
    tax
    A8
    lda CalTab,x
    beq @liga
    lda #($20 | (1<<2))
    sta txt_attr
    ldx #.loword(TXT_COPA_T)
    jsr PrintStr
    bra @nx
@liga:
    lda #$20
    sta txt_attr
    ldx #.loword(TXT_RODADA)
    jsr PrintStr
    lda cal_r
    inc a
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    jsr NextOppR
    lda fx_h
    jsr PrintTeam
    lda fx_a
    beq :+
    ldx #.loword(TXT_CASA)
    bra :++
:   ldx #.loword(TXT_FORA_C)
:   jsr PrintStr
    inc cal_r
@nx:
    inc tmp6
    inc tmp6+1
    jmp @l
@fim:
    lda g_date
    cmp #CAL_N
    bcc :+
    PRINT TXT_FIM_TEMP, 2, 4, 1
:   PRINT TXT_JG_H, 1, 25, 4
    pla
    sta div
    stz div+1
    rts

; ---------------------------------------------------------------- premios da temporada
; mostrado antes de encerrar a temporada (os gols ainda nao foram zerados)
AwardsScreen:
    .a8
    .i16
    SCR 24
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    stz aw_prize
    PRINT TXT_AW_T, 2, 1, 1
    PRINT TXT_AW_ART, 2, 3, 2
    ; artilheiro de cada serie
    lda #0
@d: sta div
    stz div+1
    jsr TopScorers
    lda div
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
    lda #$20
    sta txt_attr
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    lda #FONT_COLON
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    ldx cnt
    beq @sem
    ldx lst
    stx aw_pid
    jsr AwPlayer
    ldx aw_pid
    lda f:P_GOL,x
    ldy #3
    jsr PrintN8
@sem:
    lda div
    inc a
    cmp #4
    bne @d
    ; melhor goleiro e craque da serie do usuario
    lda g_user
    jsr TeamDiv
    sta div
    stz div+1
    PRINT TXT_AW_GOL, 2, 9, 2
    jsr BestKeeper
    ldx #(10*32+5)
    stx txt_pos
    lda #$20
    sta txt_attr
    jsr AwPlayer
    PRINT TXT_AW_CRAQUE, 2, 12, 2
    jsr BestPlayer
    ldx #(13*32+5)
    stx txt_pos
    lda #$20
    sta txt_attr
    jsr AwPlayer
    ; premio em dinheiro se algum premiado for do usuario
    lda aw_prize
    beq @fim
    PRINT TXT_AW_SEU, 2, 16, 1
    lda div
    A16
    and #$0003
    asl a
    tax
    lda DivPrize,x
    lsr a
    lsr a
    lsr a
    A8
    pha
    xba
    pha
    xba
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    pla
    xba
    pla
    jsr MoneyAdd
    lda #3
    jsr RepAdd
@fim:
    PRINT TXT_CONTINUAR_A, 2, 25, 4
    jsr ShowScreen
    jmp WaitAB

; imprime o jogador aw_pid e a sigla do time; marca aw_prize se for do usuario
AwPlayer:
    .a8
    .i16
    ldx aw_pid
    cpx #$FFFF
    bne :+
    rts
:   jsr PrintPName
    lda #FONT_SPACE
    jsr PrintChar
    A16
    lda aw_pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    cmp g_user
    bne :+
    inc aw_prize
:   lda d_q
    jmp PrintAbbr

; aw_pid = goleiro (o mais forte) do time que menos sofreu gols na serie div
BestKeeper:
    .a8
    .i16
    lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp6
    lda #$FF
    sta tmp3                ; menor numero de gols sofridos
    ldy #0
@t: phy
    tya
    clc
    adc tmp6
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    A16
    and #$00FF
    tax
    A8
    lda f:T_GC,x
    cmp tmp3
    bcs @n
    sta tmp3
    stx tmp4                ; time
@n: ply
    iny
    cpy #16
    bne @t
    lda tmp4
    jsr SetTeam
    ldx #$FFFF
    stx aw_pid
    stz tmp3
    ldx pbase
    ldy #SQ
@p: lda f:P_STR,x
    beq @np
    lda f:P_POS,x
    and #$03
    bne @np
    lda f:P_STR,x
    cmp tmp3
    bcc @np
    sta tmp3
    stx aw_pid
@np:
    inx
    dey
    bne @p
    rts

; aw_pid = craque da serie div: maior (forca + gols)
BestPlayer:
    .a8
    .i16
    lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp6
    ldx #$FFFF
    stx aw_pid
    stz tmp3
    ldy #0
@t: phy
    tya
    clc
    adc tmp6
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    jsr SetTeam
    ldx pbase
    ldy #SQ
@p: lda f:P_STR,x
    beq @np
    clc
    adc f:P_GOL,x
    bcs @novo               ; passou de 255: certamente o melhor
    cmp tmp3
    bcc @np
    beq @np
@novo:
    sta tmp3
    stx aw_pid
@np:
    inx
    dey
    bne @p
    ply
    iny
    cpy #16
    bne @t
    rts

; ---------------------------------------------------------------- pedir demissao
; (chamado da tela de carreira) carry=1 se o tecnico trocou de clube
Resign:
    .a8
    .i16
    jsr ConfirmOpen
    PRINT TXT_RS_PEDIR, 5, 10, 3
    PRINT TXT_RS_PEDIR2, 5, 12, 4
    jsr ConfirmAsk
    cmp #0
    bne :+
    clc
    rts
:   lda #$FD                ; -3 de reputacao
    jsr RepAdd
    lda #1
    sta job_fired
    jsr JobDiv
    jsr MakeJobs
    jsr JobScreen
    sec
    rts
