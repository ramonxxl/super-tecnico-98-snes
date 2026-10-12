; =====================================================================
;  Mundo: criacao, escalacao, tabela, financas, temporada, transferencias
; =====================================================================

; ---------------------------------------------------------------- novo mundo
NewWorld:
    .a8
    .i16
    lda #<InitPlayers
    sta lptr
    lda #>InitPlayers
    sta lptr+1
    lda #^InitPlayers
    sta lptr+2
    ldx #0
@p: ldy #0
    lda [lptr],y
    sta f:P_POS,x
    iny
    lda [lptr],y
    sta f:P_STR,x
    iny
    lda [lptr],y
    sta f:P_AGE,x
    iny
    lda [lptr],y
    sta f:P_NML,x
    iny
    lda [lptr],y
    sta f:P_NMH,x
    lda #0
    sta f:P_OUT,x
    sta f:P_GOL,x
    lda #11
    jsr RandBelow
    clc
    adc #45
    sta f:P_MOR,x
    lda #4
    jsr RandBelow
    inc a
    sta f:P_CON,x
    A16
    lda lptr
    clc
    adc #5
    sta lptr
    A8
    inx
    cpx #NP
    bne @p
    ldx #0
@d: lda f:InitDiv,x
    sta f:DIVT,x
    inx
    cpx #64
    bne @d
    ; zera copa, historico e noticias
    ldx #0
    lda #0
@zr:
    sta f:CUP_LIST,x
    inx
    cpx #(W_END - CUP_LIST)
    bne @zr
    ; estadios
    ldx #0
@cap:
    lda f:TeamCap,x
    sta f:T_CAP,x
    inx
    cpx #128
    bne @cap
    jsr ResetTable
    A16
    lda #2026
    sta g_season
    A8
    stz g_round
    stz g_date
    stz g_titles
    stz g_seasons
    stz g_cups
    stz hist_n
    stz news_n
    jmp CupStart

; zera a classificacao e os placares
ResetTable:
    .a8
    .i16
    ldx #0
    lda #0
@l: sta f:T_PTS,x
    inx
    cpx #(RES + 64 - T_PTS)
    bne @l
    rts

; comeca o jogo com o time g_user
StartJob:
    .a8
    .i16
    lda g_user
    jsr TeamDiv
    A16
    and #$00FF
    sta div
    asl a
    asl a
    tax
    lda DivCash,x
    sta g_money
    lda DivCash+2,x
    sta g_money+2
    stz g_f_tv
    stz g_f_bil
    stz g_f_sal
    stz g_f_trans
    stz g_f_trans+2
    stz g_att
    A8
    ldx div
    lda DivTicket,x
    sta g_ticket
    lda #1
    sta g_style
    stz g_negrnd
    lda #60
    sta g_conf
    stz g_loan
    stz g_loan+1
    stz g_train
    ; reserva: + 10 rodadas da folha salarial
    lda g_user
    jsr SetTeam
    jsr TeamSalaries
    A16
    sta m_a
    lda #10
    sta m_b
    A8
    jsr Mul16
    A16
    lda m_r
    A8
    jsr MoneyAdd
    ; tira a marca de "a venda" de todo o elenco
    lda g_user
    jsr SetTeam
    ldx pbase
    ldy #SQ
@l: lda f:P_POS,x
    and #$7F
    sta f:P_POS,x
    inx
    dey
    bne @l
    inc c_clubs
    stz g_form
    jsr CalcGoal
    jmp UserAutoPick

; ---------------------------------------------------------------- escalacao
; melhor jogador disponivel do time (pbase) na posicao pk_pos ($FF = qualquer)
; que nao esteja em picked; A = vaga ou $FF. Marca picked.
BestOf:
    .a8
    .i16
    lda #$FF
    sta tmp3                ; melhor vaga
    stz tmp3+1              ; melhor forca
    ldy #0
    ldx pbase
@l: lda picked,y
    bne @n
    lda f:P_STR,x
    beq @n
    lda f:P_OUT,x
    and #$0F
    bne @n
    lda pk_pos
    cmp #$FF
    beq @any
    lda f:P_POS,x
    and #$03
    cmp pk_pos
    bne @n
@any:
    lda f:P_STR,x
    cmp tmp3+1
    bcc @n
    beq @n
    sta tmp3+1
    tya
    sta tmp3
@n: inx
    iny
    cpy #SQ
    bne @l
    lda tmp3
    cmp #$FF
    beq @r
    A16
    and #$00FF
    tay
    A8
    lda #1
    sta picked,y
    lda tmp3
@r: rts

ClearPicked:
    .a8
    .i16
    ldx #0
@l: stz picked,x
    inx
    cpx #SQ
    bne @l
    rts

; escala o time (pbase) no 4-4-2 -> pick_out[16]
AutoPick:
    .a8
    .i16
    stz ap_form             ; clubes da IA jogam no 4-4-2
; escala no esquema ap_form (0..5)
AutoPickF:
    .a8
    .i16
    jsr ClearPicked
    ; lista de posicoes desejadas: G, defensores, meias, atacantes e 5 reservas
    lda ap_form
    asl a
    clc
    adc ap_form
    A16
    and #$00FF
    tay                     ; esquema * 3
    A8
    ldx #0
    stz need_buf            ; goleiro
    inx
    lda #POS_D
    sta tmp
@pos:
    lda FormTab,y
    sta tmp+1
@rep:
    lda tmp
    sta need_buf,x
    inx
    dec tmp+1
    bne @rep
    iny
    inc tmp
    lda tmp
    cmp #4
    bne @pos
    ; reservas: G, D, M, A e o melhor que sobrar
    stz need_buf+11
    lda #POS_D
    sta need_buf+12
    lda #POS_M
    sta need_buf+13
    lda #POS_A
    sta need_buf+14
    lda #$FF
    sta need_buf+15
    ldx #0
    stx tmp4
@need:
    lda need_buf,x
    sta pk_pos
    jsr BestOf
    cmp #$FF
    bne @ok
    lda #$FF
    sta pk_pos
    jsr BestOf
@ok:
    ldx tmp4
    sta pick_out,x
    inx
    stx tmp4
    cpx #16
    bne @need
    rts
; esquemas: defensores, meias, atacantes
FormTab: .byte 4,4,2, 4,3,3, 3,5,2, 5,3,2, 4,5,1, 3,4,3
FORM_N = 6

; escala o time do usuario automaticamente (g_lineup)
UserAutoPick:
    .a8
    .i16
    lda g_user
    jsr SetTeam
    lda g_form
    sta ap_form
    jsr AutoPickF
    ldx #0
@l: lda pick_out,x
    sta g_lineup,x
    inx
    cpx #16
    bne @l
    rts

; confere a escalacao do usuario: tira quem nao pode jogar e completa
; com os melhores disponiveis (garante um goleiro entre os titulares)
FixUserLineup:
    .a8
    .i16
    lda g_user
    jsr SetTeam
    jsr ClearPicked
    ; 1) mantem as vagas validas (sem repeticao)
    ldx #0
@v: lda g_lineup,x
    cmp #SQ
    bcs @inv
    A16
    and #$00FF
    tay
    clc
    adc pbase
    sta tmp
    A8
    lda picked,y
    bne @inv
    phx
    ldx tmp
    lda f:P_STR,x
    beq @inv2
    lda f:P_OUT,x
    and #$0F
    bne @inv2
    plx
    lda #1
    sta picked,y
    bra @nx
@inv2:
    plx
@inv:
    lda #$FF
    sta g_lineup,x
@nx:
    inx
    cpx #16
    bne @v
    ; 2) tem goleiro titular?
    ldx #0
@g: lda g_lineup,x
    cmp #$FF
    beq @gn
    jsr SlotPos
    cmp #POS_G
    beq @hasg
@gn:
    inx
    cpx #11
    bne @g
    ; sem goleiro: poe o melhor goleiro numa vaga vazia (ou na ultima)
    lda #POS_G
    sta pk_pos
    jsr BestOf
    cmp #$FF
    beq @hasg
    pha
    ldx #0
@e: lda g_lineup,x
    cmp #$FF
    beq @put
    inx
    cpx #10
    bne @e
@put:
    pla
    sta g_lineup,x
@hasg:
    ; 3) completa titulares e reservas vazios com os melhores
    ldx #0
@f: lda g_lineup,x
    cmp #$FF
    bne @fn
    phx
    lda #$FF
    sta pk_pos
    jsr BestOf
    plx
    sta g_lineup,x
@fn:
    inx
    cpx #16
    bne @f
    rts

; A = vaga (do time em pbase) -> A = posicao
SlotPos:
    .a8
    .i16
    phx
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda f:P_POS,x
    and #$03
    plx
    rts

; ---------------------------------------------------------------- rodada
; monta os 32 jogos da rodada g_round e as escalacoes
BuildLeague:
    .a8
    .i16
    ; rodada dentro do turno
    lda g_round
    cmp #15
    bcc :+
    sec
    sbc #15
:   A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a                   ; *16 (8 jogos x 2)
    sta tmp5
    A8
    ldx #0                  ; jogo 0..31
@m: stx tmp6
    ; divisao = jogo/8, i = jogo%8
    A16
    txa
    and #$0007
    asl a
    clc
    adc tmp5
    tay
    txa
    and #$0018
    asl a                   ; divisao*16
    sta tmp4
    A8
    lda FixTab,y
    sta tmp
    lda FixTab+1,y
    sta tmp+1
    lda g_round
    cmp #15
    bcc :+
    lda tmp                 ; returno: inverte o mando
    xba
    lda tmp+1
    sta tmp
    xba
    sta tmp+1
:   A16
    lda tmp6
    asl a
    tay                     ; lado mandante
    lda tmp
    and #$00FF
    clc
    adc tmp4
    tax
    A8
    lda f:DIVT,x
    sta m_team,y
    A16
    lda tmp+1
    and #$00FF
    clc
    adc tmp4
    tax
    A8
    lda f:DIVT,x
    sta m_team+1,y
    lda #0
    sta m_goal,y
    sta m_goal+1,y
    sta m_subs,y
    sta m_subs+1,y
    ldx tmp6
    inx
    cpx #NM
    bne @m
    rts

RoundSetup:
    .a8
    .i16
    stz u_ngols
    stz m_iscup
    jsr IsCupDate
    bcs :+
    jsr BuildLeague
    bra :++
:   inc m_iscup
    jsr BuildCup
:
    ; ninguem em campo
    ldx #0
    lda #0
@c: sta f:PLAY,x
    inx
    cpx #NP
    bne @c
    ; ninguem escalado ainda
    ldx #0
    lda #$FF
@cl:
    sta m_on,x
    inx
    cpx #(64*11)
    bne @cl
    ldx #$FFFF
    stx m_userm
    ; confere a escalacao do usuario
    jsr FixUserLineup
    ; escalacoes de todos os lados
    ldx #0
@s: stx m_side
    lda m_team,x
    cmp #$FF
    bne :+
    jmp @skip
:   cmp g_user
    bne @ai
    A16
    stx m_userm
    A8
    ldx #0
@u: lda g_lineup,x
    sta pick_out,x
    inx
    cpx #11
    bne @u
    ldx m_side
    lda m_team,x
    jsr SetTeam
    bra @put
@ai:
    jsr SetTeam
    jsr AutoPick
@put:
    lda m_side
    jsr OnBase              ; X = lado*11
    ldy #0
@o: lda pick_out,y
    sta m_on,x
    cmp #$FF
    beq @on
    phx
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda #1
    sta f:PLAY,x
    plx
@on:
    inx
    iny
    cpy #11
    bne @o
@skip:
    ldx m_side
    inx
    cpx #64
    beq :+
    jmp @s
:   ; forcas e chances
    ldx #0
@r: stx m_side
    lda m_team,x
    cmp #$FF
    beq :+
    txa
    jsr Ratings
:   ldx m_side
    inx
    cpx #64
    bne @r
    ldx #0
@q: stx m_side
    lda m_team,x
    cmp #$FF
    beq :+
    txa
    jsr CalcQ
:   ldx m_side
    inx
    inx
    cpx #64
    bne @q
    ; bloco de 8 jogos mostrado na tela (o do usuario, ou o primeiro)
    stz m_disp
    lda m_userm+1
    bne :+
    lda m_userm
    lsr a
    and #$F8
    sta m_disp
:   rts

; A = lado -> X = lado*11
OnBase:
    .a8
    .i16
    A16
    and #$00FF
    sta tmp2
    asl a
    asl a
    clc
    adc tmp2                ; *5
    asl a                   ; *10
    clc
    adc tmp2                ; *11
    tax
    A8
    rts

; calcula ataque/defesa do lado A
Ratings:
    .a8
    .i16
    sta tmp6                ; lado
    stz tmp6+1
    ldx tmp6
    lda m_team,x
    jsr SetTeam
    A16
    stz rt_atk
    stz rt_mid
    stz rt_def
    stz rt_gk
    A8
    lda tmp6
    jsr OnBase
    ldy #11
@l: lda m_on,x
    cmp #$FF
    beq @n
    phx
    phy
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    ; forca efetiva = forca + (moral/16 - 3)
    lda f:P_MOR,x
    lsr a
    lsr a
    lsr a
    lsr a
    sec
    sbc #3
    clc
    adc f:P_STR,x
    bmi @f1
    bne @f2
@f1:
    lda #1
@f2:
    sta tmp
    stz tmp+1
    lda f:P_POS,x
    and #$03
    beq @gk
    cmp #POS_D
    beq @df
    cmp #POS_M
    beq @md
    A16
    lda rt_atk
    clc
    adc tmp
    sta rt_atk
    A8
    bra @nn
@md:
    A16
    lda rt_mid
    clc
    adc tmp
    sta rt_mid
    A8
    bra @nn
@df:
    A16
    lda rt_def
    clc
    adc tmp
    sta rt_def
    A8
    bra @nn
@gk:
    ; o melhor goleiro em campo defende; outros jogam na defesa
    lda tmp
    cmp rt_gk
    bcc @gkd
    lda rt_gk
    pha
    lda tmp
    sta rt_gk
    pla
    sta tmp
@gkd:
    A16
    lda rt_def
    clc
    adc tmp
    sta rt_def
    A8
@nn:
    ply
    plx
@n: inx
    dey
    beq :+
    jmp @l
:   ; goleiro: se nao houver, alguem improvisa (forca 3)
    lda rt_gk
    bne :+
    lda #3
    sta rt_gk
:   A16
    lda rt_mid
    lsr a
    sta tmp
    clc
    adc rt_atk
    sta tmp2                ; ataque
    lda rt_gk
    asl a
    clc
    adc tmp
    clc
    adc rt_def
    sta tmp3                ; defesa
    A8
    ; estilo (so o time do usuario)
    lda team
    cmp g_user
    bne @st
    lda g_style
    beq @defs
    cmp #2
    bne @st
    A16                     ; ofensivo: ataque +25%, defesa -12%
    lda tmp2
    lsr a
    lsr a
    clc
    adc tmp2
    sta tmp2
    lda tmp3
    lsr a
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc tmp3
    sta tmp3
    A8
    bra @st
@defs:
    A16                     ; defensivo: ataque -25%, defesa +25%
    lda tmp2
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc tmp2
    sta tmp2
    lda tmp3
    lsr a
    lsr a
    clc
    adc tmp3
    sta tmp3
    A8
@st:
    A16
    lda tmp6
    asl a
    tax
    lda tmp2
    bne :+
    lda #1
:   sta m_atk,x
    lda tmp3
    bne :+
    lda #1
:   sta m_def,x
    A8
    rts

; chances de gol do jogo cujo lado mandante e A
CalcQ:
    .a8
    .i16
    A16
    and #$00FE
    asl a
    tax                     ; mandante*2 (palavras)
    stx tmp6
    lda m_atk,x
    ldy m_def+2,x
    jsr QIndex
    clc
    lsr a
    lsr a
    clc
    adc tmp                 ; mandante +25%
    cmp #255
    bcc :+
    lda #255
:   ldx tmp6
    sta m_q,x
    lda m_atk+2,x
    ldy m_def,x
    jsr QIndex
    lsr a
    lsr a
    lsr a
    eor #$FFFF
    sec
    adc tmp                 ; visitante -12%
    ldx tmp6
    sta m_q+2,x
    A8
    rts

; (A16) A = ataque, Y = defesa -> A = tmp = QTab[min(255, ataque*128/defesa)]
QIndex:
    .a16
    .i16
    sty d_d
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    sta d_n
    stz d_n+2
    A8
    jsr Div32
    A16
    lda d_q
    ldy d_q+2
    bne @max
    cmp #256
    bcc @ok
@max:
    lda #255
@ok:
    tax
    lda QTab,x
    and #$00FF
    sta tmp
    rts

; ---------------------------------------------------------------- fim da rodada
EndRound:
    .a8
    .i16
    lda m_iscup
    beq :+
    jsr CupEndDate
    jmp @comum
:   ; placares e tabela
    ldx #0
@m: stx tmp6
    A16
    txa
    asl a
    tax
    A8
    lda m_goal,x
    sta f:RES,x
    lda m_goal+1,x
    sta f:RES+1,x
    ; mandante
    lda m_goal,x
    sta tmp
    lda m_goal+1,x
    sta tmp+1
    lda m_team+1,x
    pha
    lda m_team,x
    jsr AddResult
    lda tmp
    xba
    lda tmp+1
    sta tmp
    xba
    sta tmp+1
    pla
    jsr AddResult
    ldx tmp6
    inx
    cpx #NM
    bne @m
@comum:
    jsr UpdateMoral
    ; suspensoes e lesoes: desconta um jogo de quem ficou de fora
    ldx #0
@o: lda f:P_OUT,x
    beq @on
    bit #$40
    beq @dec
    and #$BF                ; novo: comeca a contar na proxima rodada
    bra @st
@dec:
    dec a
    bit #$0F
    bne @st
    lda #0
@st:
    sta f:P_OUT,x
@on:
    inx
    cpx #NP
    bne @o
    jsr Training
    jsr RoundFinance
    jsr UpdateConf
    lda m_iscup
    bne :+
    jsr AiTransfers
    inc g_round
:   inc g_date
    rts

; A = time, tmp = gols pro, tmp+1 = gols contra
AddResult:
    .a8
    .i16
    A16
    and #$00FF
    tax
    A8
    lda f:T_J,x
    inc a
    sta f:T_J,x
    lda f:T_GP,x
    clc
    adc tmp
    sta f:T_GP,x
    lda f:T_GC,x
    clc
    adc tmp+1
    sta f:T_GC,x
    lda tmp
    cmp tmp+1
    beq @e
    bcc @d
    lda f:T_V,x
    inc a
    sta f:T_V,x
    lda f:T_PTS,x
    clc
    adc #3
    sta f:T_PTS,x
    rts
@e: lda f:T_E,x
    inc a
    sta f:T_E,x
    lda f:T_PTS,x
    inc a
    sta f:T_PTS,x
    rts
@d: lda f:T_D,x
    inc a
    sta f:T_D,x
    rts

; financas do usuario na rodada que acabou
RoundFinance:
    .a8
    .i16
    lda g_user
    jsr TeamDiv
    A16
    and #$00FF
    sta div
    asl a
    tax
    lda DivTV,x
    sta g_f_tv
    stz g_f_bil
    stz g_juros
    A8
    lda m_iscup
    beq :+
    stz g_f_tv
    stz g_f_tv+1
:   ; jogou em casa?
    lda m_userm+1
    bne @fora
    lda m_userm
    and #$01
    bne @fora
    jsr Attendance
    A16
    sta g_att
    sta m_a
    lda g_ticket
    and #$00FF
    sta m_b
    A8
    jsr Mul16
    A16
    lda m_r
    sta d_n
    lda m_r+2
    sta d_n+2
    lda #1000
    sta d_d
    A8
    jsr Div32
    A16
    lda d_q
    sta g_f_bil
    A8
@fora:
    lda g_user
    jsr SetTeam
    jsr TeamSalaries
    A16
    sta g_f_sal
    lda g_f_tv
    clc
    adc g_f_bil
    A8
    jsr MoneyAdd
    A16
    lda g_f_sal
    A8
    jsr MoneySub
    ; juros do emprestimo: 2% por data (minimo 1)
    A16
    lda g_loan
    beq @sj
    sta d_n
    stz d_n+2
    lda #50
    sta d_d
    A8
    jsr Div32
    A16
    lda d_q
    bne :+
    lda #1
:   sta g_juros
    A8
    jsr MoneySub
    A16
@sj:
    A8
    lda g_money+3
    bmi @neg
    stz g_negrnd
    rts
@neg:
    inc g_negrnd
    rts

; A(16) = publico do usuario em casa (div ja definido)
Attendance:
    .a8
    .i16
    ; demanda = publico_base * fama / 5
    A16
    lda div
    asl a
    tax
    lda DivPub,x
    sta m_a
    lda g_user
    and #$00FF
    tax
    A8
    lda f:TeamFame,x
    A16
    and #$00FF
    sta m_b
    A8
    jsr Mul16
    A16
    lda m_r
    sta d_n
    lda m_r+2
    sta d_n+2
    lda #5
    sta d_d
    A8
    jsr Div32
    ; preco: demanda * (2*ref - preco) / ref
    ldx div
    lda DivTicket,x
    A16
    and #$00FF
    sta tmp5
    lda g_ticket
    and #$00FF
    sta tmp
    lda tmp5
    asl a
    sec
    sbc tmp
    bpl :+
    lda #0
:   sta m_b
    lda d_q
    sta m_a
    A8
    jsr Mul16
    A16
    lda m_r
    sta d_n
    lda m_r+2
    sta d_n+2
    lda tmp5
    sta d_d
    A8
    jsr Div32
    ; limite: capacidade do estadio
    A16
    lda g_user
    and #$00FF
    asl a
    tax
    lda f:T_CAP,x
    sta tmp
    lda d_q+2
    bne @cap
    lda d_q
    cmp tmp
    bcc @ok
@cap:
    lda tmp
@ok:
    A8
    rts

; ---------------------------------------------------------------- classificacao
; ordena a divisao A -> sorted[16] (times)
SortDiv:
    .a8
    .i16
    A16
    and #$0003
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    A8
    ldy #0
@k: A16
    tya
    clc
    adc tmp5
    tax
    A8
    lda f:DIVT,x
    sta sorted,y
    phy
    A16
    and #$00FF
    tax
    A8
    lda f:T_PTS,x
    sta skey_hi,y
    ; chave baixa = (saldo+128)*256 + gols pro
    lda f:T_GP,x
    sec
    sbc f:T_GC,x
    clc
    adc #128
    xba
    lda f:T_GP,x
    A16
    pha
    tya
    asl a
    tay
    pla
    sta skey_lo,y
    A8
    ply
    iny
    cpy #16
    bne @k
    ; ordenacao por insercao (decrescente)
    ldx #1
@i: stx tmp4
@j: cpx #0
    beq @nx
    jsr KeyGreater
    bcc @nx
    jsr SwapKeys
    dex
    bra @j
@nx:
    ldx tmp4
    inx
    cpx #16
    bne @i
    rts

; carry = 1 se a chave X for maior que a chave X-1
KeyGreater:
    .a8
    .i16
    lda skey_hi,x
    cmp skey_hi-1,x
    beq @eq
    rts
@eq:
    A16
    txa
    asl a
    tay
    lda skey_lo,y
    cmp skey_lo-2,y
    A8
    beq @no
    rts
@no:
    clc
    rts

; troca os itens X e X-1
SwapKeys:
    .a8
    .i16
    lda skey_hi,x
    pha
    lda skey_hi-1,x
    sta skey_hi,x
    pla
    sta skey_hi-1,x
    lda sorted,x
    pha
    lda sorted-1,x
    sta sorted,x
    pla
    sta sorted-1,x
    A16
    txa
    asl a
    tay
    lda skey_lo,y
    pha
    lda skey_lo-2,y
    sta skey_lo,y
    pla
    sta skey_lo-2,y
    A8
    rts

; posicao (1..16) do time A na sua divisao (ordena a divisao)
TeamRank:
    .a8
    .i16
    sta tmp6
    jsr TeamDiv
    jsr SortDiv
    ldx #0
@l: lda sorted,x
    cmp tmp6
    beq @f
    inx
    cpx #16
    bne @l
@f: txa
    inc a
    rts

; conta os jogadores de todos os times -> tcnt[64]
CountAll:
    .a8
    .i16
    ldx #0
@t: stx tmp5
    txa
    jsr SetTeam
    jsr TeamCount
    ldx tmp5
    sta tcnt,x
    inx
    cpx #NT
    bne @t
    rts

; ---------------------------------------------------------------- transferencias
; move o jogador pid para o time A. carry = 1 se deu certo
MovePlayer:
    .a8
    .i16
    jsr SetTeam
    ; vaga livre
    ldx pbase
    ldy #SQ
@f: lda f:P_STR,x
    beq @got
    inx
    dey
    bne @f
    clc
    rts
@got:
    stx tmp5                ; destino
    ; tira da escalacao do usuario se for dele
    A16
    lda pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    cmp g_user
    bne @nu
    lda d_r                 ; vaga de origem
    ldx #0
@lu: cmp g_lineup,x
    bne :+
    pha
    lda #$FF
    sta g_lineup,x
    pla
:   inx
    cpx #16
    bne @lu
@nu:
    ldx pid
    ldy tmp5
    lda f:P_POS,x
    and #$03
    phx
    tyx
    sta f:P_POS,x
    plx
    lda f:P_STR,x
    phx
    tyx
    sta f:P_STR,x
    plx
    lda f:P_AGE,x
    phx
    tyx
    sta f:P_AGE,x
    plx
    lda f:P_NML,x
    phx
    tyx
    sta f:P_NML,x
    plx
    lda f:P_NMH,x
    phx
    tyx
    sta f:P_NMH,x
    plx
    lda f:P_OUT,x
    phx
    tyx
    sta f:P_OUT,x
    plx
    lda f:P_GOL,x
    phx
    tyx
    sta f:P_GOL,x
    plx
    lda f:P_MOR,x
    clc
    adc #10                 ; clube novo: animado
    cmp #96
    bcc :+
    lda #95
:   phx
    tyx
    sta f:P_MOR,x
    lda #3
    sta f:P_CON,x           ; contrato novo de 3 anos
    plx
    lda #0
    sta f:P_STR,x
    sta f:P_POS,x
    sta f:P_OUT,x
    sta f:P_GOL,x
    sec
    rts

; aleatorio 16 bits: A(16) = 0..(A-1)
RandBelow16:
    .a8
    .i16
    A16
    sta m_b
    A8
    jsr Rand
    jsr Rand
    A16
    lda rng
    sta m_a
    A8
    jsr Mul16
    A16
    lda m_r+2
    A8
    rts

; lista de jogadores a venda (outros times) -> lst / cnt. A = posicao (4 = todas)
BuildMarket:
    .a8
    .i16
    sta pk_pos
    jsr CountAll
    ldx #0
    stx cnt
    ldx #0
@t: stx tmp5                ; time
    txa
    cmp g_user
    beq @nt
    lda tcnt,x
    cmp #18
    bcc @nt
    txa
    jsr SetTeam
    ldy #0
@p: phy
    A16
    tya
    clc
    adc pbase
    sta pid
    ; sorteio fixo por rodada: (pid*7 + rodada*13 + temporada) & 31 == 0
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
    sbc tmp2                ; *13
    clc
    adc tmp
    clc
    adc g_season
    and #$001F
    A8
    bne @np
    ldx pid
    lda f:P_STR,x
    beq @np
    lda pk_pos
    cmp #4
    beq @add
    lda f:P_POS,x
    and #$03
    cmp pk_pos
    bne @np
@add:
    A16
    lda cnt
    cmp #64
    bcs @np16
    asl a
    tax
    lda pid
    sta lst,x
    inc cnt
@np16:
    A8
@np:
    ply
    iny
    cpy #SQ
    bne @p
@nt:
    ldx tmp5
    inx
    cpx #NT
    beq :+
    jmp @t
:   rts

; propostas pelos jogadores do usuario (depois da rodada) -> offer_pid ($FFFF = nada)
RoundOffers:
    .a8
    .i16
    ldx #$FFFF
    stx offer_pid
    jsr CountAll
    lda g_user
    jsr SetTeam
    lda g_user
    A16
    and #$00FF
    tax
    A8
    lda tcnt,x
    cmp #(MIN_ELENCO + 1)
    bcs :+
    rts
:   ; jogadores a venda: 1 em 3
    ldy #0
@l: A16
    tya
    clc
    adc pbase
    tax
    A8
    lda f:P_STR,x
    beq @n
    lda f:P_POS,x
    bpl @n
    phy
    phx
    lda #3
    jsr RandBelow
    plx
    ply
    cmp #0
    bne @n
    stx offer_pid
    lda #80
    sta tmp4
    lda #41
    jsr RandBelow
    clc
    adc tmp4
    bra @make
@n: iny
    cpy #SQ
    bne @l
    ; proposta surpresa pelo craque: 1 em 14
    lda #14
    jsr RandBelow
    cmp #0
    beq :+
    rts
:   ldx pbase
    ldy #SQ
    stz tmp4
@b: lda f:P_STR,x
    cmp tmp4
    bcc :+
    sta tmp4
    stx offer_pid
:   inx
    dey
    bne @b
    lda #130
@make:
    sta m_b
    stz m_b+1
    ldx offer_pid
    jsr GetValue
    jsr Percent
    A16
    sta offer_val
    stz offer_val+2
    A8
    ; clube interessado: outro time com vaga
@try:
    lda #64
    jsr RandBelow
    cmp g_user
    beq @try
    sta offer_team
    A16
    and #$00FF
    tax
    A8
    lda tcnt,x
    cmp #MAX_ELENCO
    bcs @try
    rts

; ---------------------------------------------------------------- temporada
; fim de temporada: campeoes, acesso/rebaixamento, idade, aposentadoria
SeasonEnd:
    .a8
    .i16
    ; posicao final do usuario
    lda g_user
    jsr TeamDiv
    sta u_div
    lda g_user
    jsr TeamRank
    sta u_pos
    ; premio pela colocacao: premio * (17 - posicao) / 16
    lda u_div
    A16
    and #$0003
    asl a
    tax
    lda DivPrize,x
    sta m_a
    A8
    lda #17
    sec
    sbc u_pos
    sta m_b
    stz m_b+1
    jsr Mul16
    A16
    lda m_r
    lsr m_r+2
    ror a
    lsr m_r+2
    ror a
    lsr m_r+2
    ror a
    lsr m_r+2
    ror a
    sta g_prize
    A8
    jsr MoneyAdd
    ; ordena as 4 divisoes
    lda #0
@d: sta div
    stz div+1
    jsr SortDiv
    lda div
    A16
    and #$0003
    tax
    asl a
    asl a
    asl a
    asl a
    sta tmp5
    A8
    lda sorted
    sta champ,x
    ldy #0
@c: A16
    tya
    clc
    adc tmp5
    tax
    A8
    lda sorted,y
    sta f:DIVT,x
    iny
    cpy #16
    bne @c
    lda div
    inc a
    cmp #4
    bne @d
    ; troca os 4 ultimos de cada divisao com os 4 primeiros da de baixo
    ldx #0
@sw:
    stx tmp4
    A16
    txa
    and #$0003
    sta tmp
    txa
    and #$00FC              ; divisao*4
    asl a
    asl a                   ; divisao*16
    clc
    adc tmp
    tax                     ; topo da divisao de baixo = (d+1)*16 + j  -> x+16
    A8
    lda f:DIVT+12,x
    pha
    lda f:DIVT+16,x
    sta f:DIVT+12,x
    pla
    sta f:DIVT+16,x
    ldx tmp4
    inx
    cpx #12
    bne @sw
    ; titulo do usuario
    lda u_pos
    cmp #1
    bne :+
    inc g_titles
:   inc g_seasons
    jsr HistPush
    jsr AgePlayers
    jsr ContractsEnd
    jsr ResetTable
    ; zera gols, amarelos e punicoes
    ldx #0
@z: lda #0
    sta f:P_GOL,x
    sta f:P_OUT,x
    lda f:P_POS,x
    and #$83
    sta f:P_POS,x
    inx
    cpx #NP
    bne @z
    A16
    inc g_season
    stz g_f_trans
    stz g_f_trans+2
    A8
    stz g_round
    stz g_date
    jmp CupStart

; envelhece, evolui e aposenta jogadores (garotos da base substituem)
AgePlayers:
    .a8
    .i16
    ldx #0
@p: stx pid
    lda f:P_STR,x
    bne :+
    jmp @n
:   lda f:P_AGE,x
    inc a
    sta f:P_AGE,x
    ; aposentadoria
    cmp #37
    bcs @ret
    cmp #34
    bcc @evo
    lda #2
    jsr RandBelow
    ldx pid
    cmp #0
    beq @ret
@evo:
    lda f:P_AGE,x
    cmp #22
    bcc @y1
    cmp #25
    bcc @y2
    cmp #30
    bcc @y3
    cmp #33
    bcc @y4
    lda #4
    jsr RandBelow
    inc a
    bra @minus
@y4:
    lda #3
    jsr RandBelow
    bra @minus
@y3:
    lda #3
    jsr RandBelow
    dec a
    bmi @m1
    bra @plus
@m1:
    lda #1
    bra @minus
@y2:
    lda #3
    jsr RandBelow
    bra @plus
@y1:
    lda #5
    jsr RandBelow
@plus:
    ldx pid
    clc
    adc f:P_STR,x
    cmp #51
    bcc :+
    lda #50
:   sta f:P_STR,x
    bra @n
@minus:
    ldx pid
    sta tmp
    lda f:P_STR,x
    sec
    sbc tmp
    beq :+
    bcs :++
:   lda #1
:   sta f:P_STR,x
    bra @n
@ret:
    jsr Youth
@n: ldx pid
    inx
    cpx #NP
    beq :+
    jmp @p
:   rts

; transforma a vaga pid num garoto da base (mesma posicao)
Youth:
    .a8
    .i16
    ; time e divisao
    A16
    lda pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    jsr TeamDiv
    A16
    and #$00FF
    tax
    A8
    lda DivBase,x
    sta tmp4
    lda #9
    jsr RandBelow
    clc
    adc tmp4
    ldx pid
    sta f:P_STR,x
    lda #3
    jsr RandBelow
    clc
    adc #17
    ldx pid
    sta f:P_AGE,x
    lda f:P_POS,x
    and #$03
    sta f:P_POS,x
    lda #0
    sta f:P_OUT,x
    sta f:P_GOL,x
    lda #55
    sta f:P_MOR,x
    lda #3
    sta f:P_CON,x
    A16
    lda #NAME_POOL_N
    A8
    jsr RandBelow16
    A16
    clc
    adc #NAME_POOL_START
    A8
    ldx pid
    sta f:P_NML,x
    xba
    sta f:P_NMH,x
    rts

; completa com garotos os times com menos de 18 jogadores
FillSquads:
    .a8
    .i16
    jsr CountAll
    ldx #0
@t: stx tmp6
    lda tcnt,x
    cmp #18
    bcs @nt
    sta tmp3
    txa
    jsr SetTeam
    ; posicao que falta: alterna D, M, A, G
    ldx pbase
    ldy #SQ
@v: lda f:P_STR,x
    bne @nv
    stx pid
    phy
    A16
    lda tmp3
    and #$0003
    tax
    A8
    lda FillPos,x
    ldx pid
    sta f:P_POS,x
    phx
    jsr Youth
    plx
    ply
    inc tmp3
    lda tmp3
    cmp #18
    bcs @nt
@nv:
    inx
    dey
    bne @v
@nt:
    ldx tmp6
    inx
    cpx #NT
    bne @t
    rts
FillPos: .byte 1, 2, 3, 0

; sorteia 3 clubes da divisao A (diferentes do usuario) -> job_list
MakeJobs:
    .a8
    .i16
    sta tmp4
    stz job_n
@l: lda #16
    jsr RandBelow
    sta tmp
    lda tmp4
    asl a
    asl a
    asl a
    asl a
    clc
    adc tmp
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    cmp g_user
    beq @l
    sta tmp+1
    ; repetido?
    ldx #0
@r: txa
    cmp job_n
    beq @ok
    lda tmp+1
    cmp job_list,x
    beq @l
    inx
    bra @r
@ok:
    lda tmp+1
    sta job_list,x
    inc job_n
    lda job_n
    cmp #3
    bne @l
    rts
