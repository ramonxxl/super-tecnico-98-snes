; =====================================================================
;  Partida: rodada ao vivo (32 jogos simultaneos, mostra a divisao do
;  usuario), gols, cartoes, lesoes e substituicoes
; =====================================================================

EVT_Y = 120
EVT_R = 4
EVT_L = 9
EV_GOL = 0
EV_AMA = 1
EV_EXP = 2
EV_LES = 3
EV_ENT = 4
EV_PEN = 5
EV_PENX = 6
EV_CON = 7
EVT_P = 2

; rodada inteira (bloqueante). Ao final chama EndRound.
PlayRound:
    .a8
    .i16
    SCR 6
    jsr RoundSetup
    stz m_shots
    stz m_shots+1
    jsr BeginScreen
    jsr DrawMatchScreen
    jsr ShowScreen
    SFX SFX_APITO
    stz m_minute
    stz m_halt
    lda #13
    sta m_evrow
@min:
    ; espera conforme a velocidade (segurar A acelera)
    lda #6
    sta m_ticks
@w: jsr NextFrame
    lda m_userm+1
    bne :+                  ; sem jogo do usuario: sem substituicoes
    lda pad_new+1
    bit #KH_START
    beq :+
    jsr SubstScreen
:   jsr MatchKeys
    lda pad
    bit #KL_A
    bne @go
    dec m_ticks
    bne @w
@go:
    inc m_minute
    jsr MatchTick
    jsr DrawMinute
    lda m_minute
    cmp #45
    bne @nh
    ; intervalo (torcida mais baixa)
    SFX SFX_APITO
    lda #25
    jsr ClearRow
    PRINT TXT_INTERVALO, 1, 25, 1
@hw:
    jsr NextFrame
    lda m_userm+1
    bne :+
    lda pad_new+1
    bit #KH_START
    beq :+
    jsr SubstScreen
    lda #25
    jsr ClearRow
    PRINT TXT_INTERVALO, 1, 25, 1
:   jsr MatchKeys
    lda pad_new
    bit #KL_A
    beq @hw
    lda #25
    jsr ClearRow
    PRINT TXT_MATCH_HELP, 1, 25, 4
@nh:
    lda m_minute
    cmp #90
    beq :+
    jmp @min
:   SFX SFX_FIM
    lda #25
    jsr ClearRow
    PRINT TXT_FIMJOGO, 1, 25, 1
@ew:
    jsr NextFrame
    jsr MatchKeys
    lda pad_new
    bit #KL_A
    beq @ew
    jmp EndRound

; ---------------------------------------------------------------- tela
DrawMatchScreen:
    .a8
    .i16
    jsr DrawMatchList
    jsr DrawScoreboard
    PRINT TXT_LANCES, 1, 18, 2
    PRINT TXT_MATCH_HELP, 1, 25, 4
    jmp DrawMinute

; cabecalho (serie e rodada, ou fase da copa) e os 8 jogos da pagina m_disp
DrawMatchList:
    .a8
    .i16
    lda m_iscup
    beq @liga
    PRINT TXT_COPA, 1, 1, 1
    lda cup_phase
    A16
    and #$00FF
    asl a
    tax
    lda CupPhaseTxt,x
    tax
    A8
    jsr PrintStr
    ldx #.loword(TXT_IDA)
    lda cup_leg
    beq :+
    ldx #.loword(TXT_VOLTA)
:   jsr PrintStr
    bra @jogos
@liga:
    lda m_disp
    lsr a
    lsr a
    lsr a
    sta div
    stz div+1
    PRINT TXT_SERIE, 1, 1, 1
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    jsr PrintChar
    ldx #.loword(TXT_RODADA)
    jsr PrintStr
    lda g_round
    inc a
    ldy #2
    jsr PrintN8
@jogos:
    ldx #0
@l: phx
    txa
    clc
    adc m_disp
    jsr DrawMatchLine
    plx
    inx
    cpx #8
    bne @l
    jmp MatchCrests

; placar grande do jogo do usuario, com os escudos
DrawScoreboard:
    .a8
    .i16
    lda m_userm+1
    beq :+
    PRINT TXT_SEM_JOGO, 6, 5, 4
    rts
:   A16
    lda m_userm
    and #$00FE
    sta dl_idx
    A8
    stz shd_slot
    lda #16
    sta tmp5
    lda #18
    sta tmp5+1
    ldx dl_idx
    lda m_team,x
    jsr DrawShield
    lda #1
    sta shd_slot
    lda #208
    sta tmp5
    lda #18
    sta tmp5+1
    ldx dl_idx
    lda m_team+1,x
    jsr DrawShield
    stz shd_slot
    ; nomes embaixo dos escudos
    ldx #(8*32+1)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    ldx dl_idx
    lda m_team,x
    jsr PrintTeam
    ldx #(8*32+19)
    stx txt_pos
    ldx dl_idx
    lda m_team+1,x
    jsr PrintTeam
; so os numeros grandes
DrawBigScore:
    .a8
    .i16
    lda m_userm+1
    bne @r
    A16
    lda m_userm
    and #$00FE
    sta dl_idx
    A8
    ldx dl_idx
    lda m_goal,x
    ldy #9                  ; coluna do mandante
    jsr BigNum
    ldx dl_idx
    lda m_goal+1,x
    ldy #18                 ; coluna do visitante
    jsr BigNum
    ; traco no meio
    ldx #(5*32+15)
    stx txt_pos
    lda #($20 | (7<<2))
    sta txt_attr
    lda #FONT_BOX
    jsr PrintChar
    jsr PrintChar
@r: rts

; numero A (0..99) em digitos grandes de 3x5 blocos a partir da coluna Y (linhas 3..7)
BigNum:
    .a8
    .i16
    sty bn_col
    cmp #10
    bcc @um
    ; dois digitos: dezena 4 colunas antes
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
    lda RDMPYL
    pha
    lda RDDIVL
    ldx bn_col
    dex
    dex
    stx bn_col
    jsr BigDigit
    ldx bn_col
    inx
    inx
    inx
    inx
    stx bn_col
    pla
    jmp BigDigit
@um:
    pha
    ; apaga a coluna da dezena de um placar anterior
    ldx bn_col
    dex
    dex
    stx bn_col
    lda #10
    jsr BigDigit
    ldx bn_col
    inx
    inx
    stx bn_col
    pla
; digito A (10 = em branco) na coluna bn_col
BigDigit:
    .a8
    .i16
    A16
    and #$00FF
    sta tmp
    asl a
    asl a
    clc
    adc tmp                 ; *5
    sta tmp3                ; inicio do desenho
    A8
    lda #0
    sta tmp4                ; linha 0..4
@lin:
    A16
    lda tmp4
    and #$00FF
    clc
    adc #3
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc bn_col
    sta txt_pos
    lda tmp3
    clc
    adc tmp4
    and #$00FF
    tax
    A8
    lda BigDig,x
    sta tmp4+1
    ldy #3
@col:
    asl tmp4+1
    lda tmp4+1
    and #$08
    beq @vz
    lda #($20 | (7<<2))
    sta txt_attr
    lda #FONT_BOX
    bra @pt
@vz:
    lda #$20
    sta txt_attr
    lda #FONT_SPACE
@pt:
    jsr PrintChar
    dey
    bne @col
    inc tmp4
    lda tmp4
    cmp #5
    bne @lin
    rts
; 3 bits por linha (bit 2 = esquerda), 5 linhas por digito; 10 = vazio
BigDig:
    .byte 7,5,5,5,7, 2,6,2,2,7, 7,1,7,4,7, 7,1,7,1,7, 5,5,7,1,1
    .byte 7,4,7,1,7, 7,4,7,5,7, 7,1,1,1,1, 7,5,7,5,7, 7,5,7,1,7
    .byte 0,0,0,0,0

; minuto no canto
DrawMinute:
    .a8
    .i16
    ldx #(1*32+26)
    stx txt_pos
    lda #$20
    sta txt_attr
    lda m_minute
    ldy #2
    jsr PrintN8
    lda #FONT_APOS
    jmp PrintChar

; linha do jogo A (0..31) - linhas 10..17
DrawMatchLine:
    .a8
    .i16
    sta tmp4
    and #$07
    clc
    adc #10
    pha
    jsr ClearRow
    pla
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    inc a
    sta txt_pos
    A8
    lda tmp4
    asl a
    A16
    and #$00FF
    sta dl_idx
    tax
    A8
    lda m_team,x
    cmp #$FF
    bne :+
    rts
:   ; paleta: amarelo no jogo do usuario
    lda m_userm+1
    bne :+
    lda m_userm
    lsr a
    cmp tmp4
    bne :+
    lda #($20 | (1<<2))
    bra :++
:   lda #$20
:   sta txt_attr
    ldx dl_idx
    lda m_team,x
    jsr PrintTeam
    ldx dl_idx
    lda m_goal,x
    ldy #2
    jsr PrintN8
    lda #FONT_X
    jsr PrintChar
    ldx dl_idx
    lda m_goal+1,x
    cmp #10
    bcs :+
    ldy #1
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    bra :++
:   ldy #2
    jsr PrintN8
:   lda #FONT_SPACE
    jsr PrintChar
    ldx dl_idx
    lda m_team+1,x
    jmp PrintTeam

CupPhaseTxt: .word .loword(TXT_FASE1), .loword(TXT_FASE2), .loword(TXT_OITAVAS), .loword(TXT_QUARTAS), .loword(TXT_SEMI), .loword(TXT_FINAL), .loword(TXT_FINAL)

; ---------------------------------------------------------------- minuto
MatchTick:
    .a8
    .i16
    ldx #0
@s: stx m_side
    lda m_team,x
    cmp #$FF
    bne :+
    jmp @nx
:   jsr Rand4096
    A16
    sta tmp
    lda m_side
    asl a
    tax
    lda tmp
    cmp m_q,x
    A8
    bcs @ng
    jsr DoGoal
@ng:
    ; finalizacoes do jogo do usuario (chance de gol x 4)
    lda m_userm+1
    bne @ev
    lda m_side
    eor m_userm
    and #$FE
    bne @ev
    jsr Rand4096
    A16
    lsr a
    lsr a
    sta tmp
    lda m_side
    asl a
    tax
    lda tmp
    cmp m_q,x
    A8
    bcs @ev
    jsr ShotInc
@ev:
    jsr Rand4096
    A16
    cmp #EVT_Y
    bcc @y
    cmp #(EVT_Y + EVT_R)
    bcc @r
    cmp #(EVT_Y + EVT_R + EVT_L)
    bcc @le
    cmp #(EVT_Y + EVT_R + EVT_L + EVT_P)
    bcc @pe
    A8
    bra @nx
@pe:
    A8
    jsr DoPenalty
    bra @nx
@y: A8
    jsr DoYellow
    bra @nx
@r: A8
    jsr DoRed
    bra @nx
@le:
    A8
    jsr DoInjury
@nx:
    ldx m_side
    inx
    cpx #64
    beq :+
    jmp @s
:   rts

; carrega o time do lado m_side
SideTeam:
    .a8
    .i16
    ldx m_side
    lda m_team,x
    sta ev_team
    jmp SetTeam

; sorteia um jogador em campo do lado m_side na posicao pk_pos
; ($FE = qualquer menos goleiro, $FF = qualquer). carry=1: A = indice 0..10, X = pid
PickOnField:
    .a8
    .i16
    lda m_side
    jsr OnBase
    stx tmp5
    ldy #0
    stz tmp4                ; quantidade
@l: lda m_on,x
    cmp #$FF
    beq @n
    jsr SlotPos
    sta tmp
    lda pk_pos
    cmp #$FF
    beq @add
    cmp #$FE
    bne @eq
    lda tmp
    beq @n
    bra @add
@eq:
    cmp tmp
    bne @n
@add:
    phx
    lda tmp4
    A16
    and #$00FF
    tax
    A8
    tya
    sta cand,x
    inc tmp4
    plx
@n: inx
    iny
    cpy #11
    bne @l
    lda tmp4
    bne :+
    clc
    rts
:   jsr RandBelow
    A16
    and #$00FF
    tax
    A8
    lda cand,x
    sta tmp                 ; indice em campo
    A16
    and #$00FF
    clc
    adc tmp5
    sta tmp2                ; posicao em m_on
    tax
    A8
    lda m_on,x
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda tmp
    sec
    rts

DoGoal:
    .a8
    .i16
    ; gol contra (1 em 25): um defensor do adversario
    lda #25
    jsr RandBelow
    cmp #0
    bne @normal
    lda m_side
    eor #1
    sta m_side
    jsr SideTeam
    lda #POS_D
    sta pk_pos
    jsr PickOnField
    php
    lda m_side
    eor #1
    sta m_side
    plp
    bcc @normal
    stx ev_pid
    lda m_side
    eor #1
    A16
    and #$00FF
    tax
    A8
    lda m_team,x
    sta ev_team
    lda #EV_CON
    sta ev_type
    jmp GoalScore
@normal:
    jsr SideTeam
    lda #10
    jsr RandBelow
    ldx #POS_A
    cmp #6
    bcc @p
    ldx #POS_M
    cmp #9
    bcc @p
    ldx #POS_D
@p: txa
    sta pk_pos
    jsr PickOnField
    bcs @got
    lda #$FE
    sta pk_pos
    jsr PickOnField
    bcs @got
    lda #$FF
    sta pk_pos
    jsr PickOnField
    bcc @nos
@got:
    lda #EV_GOL
    sta ev_type
    jmp GoalBy
@nos:
    ldx #$FFFF
    stx ev_pid
    lda #EV_GOL
    sta ev_type
    ldx m_side
    lda m_team,x
    sta ev_team
    jmp GoalScore

; gol do jogador X (credita o gol a ele); ev_type ja definido
GoalBy:
    .a8
    .i16
    stx ev_pid
    lda f:P_GOL,x
    inc a
    beq :+
    sta f:P_GOL,x
:   ldx m_side
    lda m_team,x
    sta ev_team
; soma o gol para o lado m_side, mostra e atualiza o placar
GoalScore:
    .a8
    .i16
    ldx m_side
    inc m_goal,x
    jsr LiveEvent
    ; linha do jogo, se estiver na tela
    lda m_side
    lsr a
    and #$F8
    cmp m_disp
    bne @nd
    lda m_side
    lsr a
    jsr DrawMatchLine
@nd:
    ; placar grande, se for o jogo do usuario
    lda m_userm+1
    bne @r
    lda m_side
    lsr a
    sta tmp
    lda m_userm
    lsr a
    cmp tmp
    bne @r
    jsr ShotInc
    jsr DrawBigScore
@r: rts

; soma uma finalizacao para o lado m_side (jogo do usuario)
ShotInc:
    .a8
    .i16
    lda m_side
    A16
    and #$0001
    tax
    A8
    inc m_shots,x
    rts

; penalti: 3 em 4 viram gol
DoPenalty:
    .a8
    .i16
    jsr SideTeam
    lda #POS_A
    sta pk_pos
    jsr PickOnField
    bcs :+
    lda #$FE
    sta pk_pos
    jsr PickOnField
    bcs :+
    rts
:   stx ev_pid
    lda #4
    jsr RandBelow
    cmp #3
    beq @perdeu
    ldx ev_pid
    lda #EV_PEN
    sta ev_type
    jmp GoalBy
@perdeu:
    ldx m_side
    lda m_team,x
    sta ev_team
    lda #EV_PENX
    sta ev_type
    jmp LiveEvent

DoYellow:
    .a8
    .i16
    jsr SideTeam
    lda #$FF
    sta pk_pos
    jsr PickOnField
    bcs :+
    rts
:   stx ev_pid
    lda f:PLAY,x
    cmp #3
    beq @second
    lda #3
    sta f:PLAY,x
    ; amarelos acumulados: o terceiro suspende
    lda f:P_POS,x
    clc
    adc #$10
    sta f:P_POS,x
    and #$30
    cmp #$30
    bne @ev
    lda f:P_POS,x
    and #$CF
    sta f:P_POS,x
    lda #$41
    sta f:P_OUT,x
@ev:
    lda #EV_AMA
    sta ev_type
    jmp LiveEvent
@second:
    lda #$41
    sta f:P_OUT,x
    bra SendOff

DoRed:
    .a8
    .i16
    jsr SideTeam
    lda #$FF
    sta pk_pos
    jsr PickOnField
    bcs :+
    rts
:   stx ev_pid
    lda #$42
    sta f:P_OUT,x
; tira o jogador ev_pid (posicao tmp2 em m_on) de campo
SendOff:
    lda #2
    sta f:PLAY,x
    ldx tmp2
    lda #$FF
    sta m_on,x
    lda #EV_EXP
    sta ev_type
    jsr LiveEvent
    jmp Recalc

DoInjury:
    .a8
    .i16
    jsr SideTeam
    lda team
    cmp g_user
    bne :+
    lda g_train
    cmp #3
    bne :+
    lda #2
    jsr RandBelow
    cmp #0
    bne :+
    rts
:
    lda #$FF
    sta pk_pos
    jsr PickOnField
    bcs :+
    rts
:   stx ev_pid
    lda f:P_POS,x
    and #$03
    sta pk_pos
    lda #2
    sta f:PLAY,x
    lda #4
    jsr RandBelow
    inc a
    ora #$C0
    ldx ev_pid
    sta f:P_OUT,x
    ldx tmp2
    lda #$FF
    sta m_on,x
    phx
    lda #EV_LES
    sta ev_type
    jsr LiveEvent
    plx
    stx tmp2
    ; substituicao automatica
    ldx m_side
    lda m_subs,x
    cmp #3
    bcs @done
    jsr FindSub
    bcc @done
    ldx tmp2
    sta m_on,x
    ldx m_side
    inc m_subs,x
    ldx ev_pid
    lda #1
    sta f:PLAY,x
    lda #EV_ENT
    sta ev_type
    jsr LiveEvent
@done:
    jmp Recalc

; reserva para o lado m_side (posicao preferida pk_pos)
; carry=1: A = vaga, ev_pid = jogador
FindSub:
    .a8
    .i16
    jsr SideTeam
    stz tmp4+1              ; passada 0 = mesma posicao, 1 = qualquer
@pass:
    lda team
    cmp g_user
    bne @ai
    ; usuario: so os reservas escolhidos
    ldy #11
@u: lda g_lineup,y
    cmp #$FF
    beq @un
    jsr SubOk
    bcc @un
    lda g_lineup,y
    sec
    rts
@un:
    iny
    cpy #16
    bne @u
    bra @np
@ai:
    ; time da casa: o mais forte disponivel
    lda #$FF
    sta tmp3
    stz tmp3+1
    ldy #0
@a: tya
    jsr SubOk
    bcc @an
    lda f:P_STR,x
    cmp tmp3+1
    bcc @an
    sta tmp3+1
    tya
    sta tmp3
@an:
    iny
    cpy #SQ
    bne @a
    lda tmp3
    cmp #$FF
    beq @np
    A16
    and #$00FF
    clc
    adc pbase
    sta ev_pid
    A8
    lda tmp3
    sec
    rts
@np:
    lda tmp4+1
    bne @no
    inc tmp4+1
    bra @pass
@no:
    clc
    rts

; A = vaga: carry=1 se pode entrar (e X = ev_pid = jogador)
SubOk:
    .a8
    .i16
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda f:P_STR,x
    beq @no
    lda f:PLAY,x
    bne @no
    lda f:P_OUT,x
    and #$0F
    bne @no
    lda tmp4+1
    bne @ok
    lda f:P_POS,x
    and #$03
    cmp pk_pos
    bne @no
@ok:
    stx ev_pid
    sec
    rts
@no:
    clc
    rts

; recalcula forcas e chances do jogo do lado m_side
Recalc:
    .a8
    .i16
    lda m_side
    jsr Ratings
    lda m_side
    jmp CalcQ

; ---------------------------------------------------------------- eventos
; mostra o evento ev_type/ev_pid se for no jogo do usuario
LiveEvent:
    .a8
    .i16
    lda m_side
    lsr a
    sta tmp
    lda m_userm
    lsr a
    cmp tmp
    beq :+
    rts
:   lda ev_type
    beq @gol
    cmp #EV_PEN
    beq @gol
    cmp #EV_CON
    bne @role
@gol:
    lda m_side
    cmp m_userm
    bne @contra
    SFX SFX_GOL
    bra @anota
@contra:
    SFX SFX_GOLCONTRA
@anota:
    ; guarda o gol para o resumo: minuto (bit7 = visitante), jogador (bit15 = contra)
    lda u_ngols
    cmp #8
    bcs @role
    A16
    and #$00FF
    sta tmp
    asl a
    clc
    adc tmp
    tax
    A8
    lda m_side
    and #1
    lsr a
    ror a
    ora m_minute
    sta u_gols,x
    A16
    lda ev_pid
    sta u_gols+1,x
    A8
    lda ev_type
    cmp #EV_CON
    bne :+
    lda u_gols+2,x
    ora #$80
    sta u_gols+2,x
:   inc u_ngols
@role:
    ; rola as linhas 19..24 para cima
    ldx #0
@sc:
    lda bg3_buf+(20*64),x
    sta bg3_buf+(19*64),x
    inx
    cpx #(5*64)
    bne @sc
    lda #24
    jsr ClearRow
    ldx #(24*32+1)
    stx txt_pos
    ; cor por tipo
    lda ev_type
    A16
    and #$00FF
    tax
    A8
    lda EvPal,x
    sta txt_attr
    lda m_minute
    ldy #2
    jsr PrintN8
    lda #FONT_APOS
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    lda ev_type
    A16
    and #$00FF
    asl a
    tax
    lda EvTxt,x
    tax
    A8
    jsr PrintStr
    ldx ev_pid
    cpx #$FFFF
    beq :+
    jsr PrintPName
:   lda #FONT_LPAR
    jsr PrintChar
    lda ev_team
    jsr PrintAbbr
    lda #FONT_RPAR
    jmp PrintChar

EvPal: .byte $20|(2<<2), $20|(1<<2), $20|(3<<2), $20|(5<<2), $20|(4<<2), $20|(2<<2), $20|(4<<2), $20|(6<<2)
EvTxt: .word .loword(TXT_EV_GOL), .loword(TXT_EV_AMA), .loword(TXT_EV_EXP), .loword(TXT_EV_LES), .loword(TXT_EV_ENT), .loword(TXT_EV_PEN), .loword(TXT_EV_PENX), .loword(TXT_EV_CON)

; ---------------------------------------------------------------- substituicoes
; tela de substituicao durante o jogo (START)
SubstScreen:
    .a8
    .i16
    SCR 16
    lda m_userm
    sta m_side
    stz m_side+1
    jsr SideTeam
    stz sel
    stz sel+1
    jsr OamClear            ; esconde os escudos do placar
@redraw:
    jsr ClearBg3
    PRINT TXT_SUBST_T, 1, 1, 1
    ldx m_side
    lda m_subs,x
    sta tmp
    lda #3
    sec
    sbc tmp
    ldy #1
    jsr PrintN8
    PRINT TXT_SUBST_H, 1, 25, 4
    PRINT TXT_ESTILO, 1, 23, 4
    lda g_style
    A16
    and #$00FF
    asl a
    tax
    lda StyleTxt,x
    tax
    A8
    jsr PrintStr
    ; em campo (linhas 3..13)
    lda m_side
    jsr OnBase
    stx tmp5
    ldy #0
@f: phy
    tya
    clc
    adc #3
    jsr SubRowPos
    ldx tmp5
    A16
    tya
    clc
    adc tmp5
    tax
    A8
    lda m_on,x
    jsr SubPrintSlot
    ply
    iny
    cpy #11
    bne @f
    PRINT TXT_RESERVAS, 3, 15, 2
    ldy #11
@r: phy
    tya
    clc
    adc #5                  ; linhas 16..20
    jsr SubRowPos
    lda g_lineup,y
    jsr SubPrintSlot
    ply
    iny
    cpy #16
    bne @r
    jsr SubCursor
@in:
    jsr NextFrame
    lda pad_new+1
    bit #KH_B
    bne @exit
    bit #KH_START
    bne @exit
    bit #KH_SEL
    beq :+
    lda g_style
    inc a
    cmp #3
    bcc @sty
    lda #0
@sty:
    sta g_style
    jsr Recalc
    jmp @redraw
:   bit #KH_UP
    beq :+
    jsr SubCurOff
    lda sel
    beq @in2
    dec sel
@in2:
    jsr SubCursor
    bra @in
:   bit #KH_DOWN
    beq :+
    jsr SubCurOff
    lda sel
    cmp #15
    bcs @in3
    inc sel
@in3:
    jsr SubCursor
    bra @in
:   lda pad_new
    bit #KL_A
    beq @in
    jsr SubPick
    jmp @redraw
@exit:
    SCR 6
    jsr UiBarOff
    jsr ClearBg3
    jsr DrawMatchScreen
    ; reimprime os ultimos eventos nao e possivel; avisa
    PRINT TXT_SEUJOGO, 1, 12, 2
    rts

; A = linha -> txt_pos = linha*32 + 3, txt_attr branco
SubRowPos:
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
    adc #3
    sta txt_pos
    A8
    lda #$20
    sta txt_attr
    rts

; imprime a vaga A do time (pos, nome, forca, situacao)
SubPrintSlot:
    .a8
    .i16
    cmp #$FF
    bne :+
    ldx #.loword(TXT_VAZIO)
    jmp PrintStr
:   A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    phx
    jsr PrintPos
    lda #FONT_SPACE
    jsr PrintChar
    plx
    phx
    jsr PrintPName
    lda #FONT_SPACE
    jsr PrintChar
    plx
    phx
    lda f:P_STR,x
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    plx
    lda f:PLAY,x
    cmp #2
    bne :+
    ldx #.loword(TXT_SAIU)
    jmp PrintStr
:   lda f:P_OUT,x
    and #$0F
    beq :+
    ldx #.loword(TXT_FORA)
    jmp PrintStr
:   rts

; linha na tela do item sel (0..10 em campo, 11..15 reservas)
SubSelRow:
    .a8
    .i16
    lda sel
    cmp #11
    bcs :+
    clc
    adc #3
    rts
:   clc
    adc #5
    rts

SubCursor:
    .a8
    .i16
    jsr SubSelRow
    jsr UiBarOn
    jsr SubSelRow
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    inc a
    sta txt_pos
    A8
    lda #($20 | (1<<2))
    sta txt_attr
    lda #FONT_ARROW
    jmp PrintChar
SubCurOff:
    .a8
    .i16
    jsr SubSelRow
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    inc a
    sta txt_pos
    A8
    lda #FONT_SPACE
    jmp PrintChar

; A no item sel: primeiro escolhe quem sai (em campo), depois quem entra
SubPick:
    .a8
    .i16
    lda sel
    cmp #11
    bcc :+
    SFX SFX_ERRO
    rts
:   ; quem sai precisa estar em campo
    lda m_side
    jsr OnBase
    A16
    lda sel
    and #$00FF
    stx tmp
    clc
    adc tmp
    sta tmp2                ; posicao em m_on
    tax
    A8
    lda m_on,x
    cmp #$FF
    bne :+
    SFX SFX_ERRO
    rts
:   ldx m_side
    lda m_subs,x
    cmp #3
    bcc :+
    SFX SFX_ERRO
    rts
:   SFX SFX_CURSOR
    PRINT TXT_QUEM_ENTRA, 1, 25, 1
    lda sel
    sta tmp6
    lda #11
    sta sel
    jsr SubCursor
@in:
    jsr NextFrame
    lda pad_new+1
    bit #KH_B
    beq :+
    lda tmp6
    sta sel
    rts
:   bit #KH_UP
    beq :+
    jsr SubCurOff
    lda sel
    cmp #12
    bcc @c1
    dec sel
@c1:
    jsr SubCursor
    bra @in
:   bit #KH_DOWN
    beq :+
    jsr SubCurOff
    lda sel
    cmp #15
    bcs @c2
    inc sel
@c2:
    jsr SubCursor
    bra @in
:   lda pad_new
    bit #KL_A
    beq @in
    ; reserva valido?
    lda sel
    A16
    and #$00FF
    tax
    A8
    lda g_lineup,x
    cmp #$FF
    beq @bad
    sta tmp3
    stz tmp4+1
    lda #1
    sta tmp4+1              ; qualquer posicao
    lda tmp3
    jsr SubOk
    bcc @bad
    ; troca
    ldx tmp2
    lda m_on,x
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda #2
    sta f:PLAY,x
    ldx ev_pid
    lda #1
    sta f:PLAY,x
    ldx tmp2
    lda tmp3
    sta m_on,x
    ldx m_side
    inc m_subs,x
    SFX SFX_OK
    lda tmp6
    sta sel
    jmp Recalc
@bad:
    SFX SFX_ERRO
    jmp @in

StyleTxt: .word .loword(TXT_DEFENSIVO), .loword(TXT_EQUILIBRADO), .loword(TXT_OFENSIVO)
