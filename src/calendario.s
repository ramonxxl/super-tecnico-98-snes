; =====================================================================
;  Calendario (30 rodadas + 12 datas de copa), Copa do Brasil,
;  moral, treino, confianca da diretoria, mercado da IA e noticias
; =====================================================================

CAL_N = 42

; carry = 1 se a data atual (g_date) e de copa
IsCupDate:
    .a8
    .i16
    lda g_date
    cmp #CAL_N
    bcs @no
    A16
    and #$00FF
    tax
    A8
    lda CalTab,x
    beq @no
    sec
    rts
@no:
    clc
    rts

; ---------------------------------------------------------------- copa: inicio
; chave inicial: o 1o de cada serie contra o ultimo (A x D, B x C)
CupStart:
    .a8
    .i16
    ldx #0
@l: stx tmp
    A16
    txa
    asl a
    tay                     ; posicao 2i
    lda #63
    sec
    sbc tmp
    sta tmp2                ; 63-i
    A8
    lda f:DIVT,x
    phx
    tyx
    sta f:CUP_LIST,x
    plx
    phx
    ldx tmp2
    lda f:DIVT,x
    tyx
    sta f:CUP_LIST+1,x
    plx
    inx
    cpx #32
    bne @l
    ldx #0
    lda #0
@z: sta f:CUP_G1,x
    sta f:CUP_RES,x
    inx
    cpx #64
    bne @z
    ldx #0
@p: sta f:CUP_PEN,x
    inx
    cpx #32
    bne @p
    lda #64
    sta cup_n
    stz cup_phase
    stz cup_leg
    lda #$FF
    sta cup_champ
    rts

; usuario ainda esta na copa? carry=1, A = posicao na chave
UserInCup:
    .a8
    .i16
    lda cup_phase
    cmp #6
    bcs @no
    ldx #0
@l: lda f:CUP_LIST,x
    cmp g_user
    beq @s
    inx
    txa
    cmp cup_n
    bcc @l
@no:
    clc
    rts
@s: txa
    sec
    rts

; ---------------------------------------------------------------- copa: jogos da data
BuildCup:
    .a8
    .i16
    lda cup_n
    lsr a
    sta tmp3                ; numero de jogos
    ldx #0
@m: stx tmp6
    A16
    txa
    asl a
    tay                     ; lado mandante = 2m (e posicao 2m na chave)
    A8
    txa
    cmp tmp3
    bcs @off
    phx
    tyx
    lda f:CUP_LIST,x
    sta tmp
    lda f:CUP_LIST+1,x
    sta tmp+1
    plx
    lda cup_leg
    beq :+
    lda tmp                 ; volta: inverte o mando
    xba
    lda tmp+1
    sta tmp
    xba
    sta tmp+1
:   lda tmp
    sta m_team,y
    lda tmp+1
    sta m_team+1,y
    bra @z
@off:
    lda #$FF
    sta m_team,y
    sta m_team+1,y
@z: lda #0
    sta m_goal,y
    sta m_goal+1,y
    sta m_subs,y
    sta m_subs+1,y
    ldx tmp6
    inx
    cpx #NM
    bne @m
    rts

; ---------------------------------------------------------------- copa: resultado da data
CupEndDate:
    .a8
    .i16
    stz g_cupprize
    stz g_cupprize+1
    lda cup_n
    lsr a
    sta tmp3
    ldx #0
@m: stx tmp6
    txa
    cmp tmp3
    bcc :+
    jmp @fim
:   A16
    txa
    asl a
    tax                     ; 2m
    A8
    ; gols de cada time da chave (na volta o mando inverte)
    lda cup_leg
    bne @volta
    lda m_goal,x
    sta f:CUP_G1,x
    sta f:CUP_RES,x
    lda m_goal+1,x
    sta f:CUP_G1+1,x
    sta f:CUP_RES+1,x
    jmp @nx
@volta:
    lda m_goal+1,x
    sta f:CUP_RES,x
    clc
    adc f:CUP_G1,x
    sta tmp                 ; agregado do time 2m
    lda m_goal,x
    sta f:CUP_RES+1,x
    clc
    adc f:CUP_G1+1,x
    sta tmp+1               ; agregado do time 2m+1
    stx tmp4
    lda tmp
    cmp tmp+1
    beq @pen
    bcc @b
@a: ldx tmp4
    lda f:CUP_LIST,x
    bra @win
@b: ldx tmp4
    lda f:CUP_LIST+1,x
    bra @win
@pen:
    jsr Penalties           ; A = (a<<4)|b, carry=1 se o time 2m venceu
    php
    pha
    lda tmp6
    A16
    and #$00FF
    tax
    A8
    pla
    sta f:CUP_PEN,x
    plp
    bcs @a
    bra @b
@win:
    ; vencedor vai para a posicao m da proxima fase
    pha
    ldx tmp6
    sta f:CUP_LIST,x        ; (sobrescreve; m < 2m)
    pla
    cmp g_user
    bne @nx
    ; premio por passar de fase
    lda cup_phase
    A16
    and #$00FF
    asl a
    tax
    lda CupPrize,x
    sta g_cupprize
    A8
    jsr MoneyAdd
    lda g_conf
    clc
    adc #5
    jsr SetConfU
@nx:
    ldx tmp6
    inx
    jmp @m
@fim:
    lda cup_leg
    bne :+
    inc cup_leg
    rts
:   stz cup_leg
    lsr cup_n
    inc cup_phase
    ; zera ida/penaltis da nova fase
    ldx #0
    lda #0
@z: sta f:CUP_G1,x
    inx
    cpx #64
    bne @z
    lda cup_n
    cmp #1
    bne @r
    lda f:CUP_LIST
    sta cup_champ
    lda #6
    sta cup_phase
    lda cup_champ
    cmp g_user
    bne @r
    inc g_cups
    lda #100
    jsr SetConfU
@r: rts

; disputa de penaltis: A = (gols a<<4)|gols b (max 15), carry=1 se a venceu
Penalties:
    .a8
    .i16
    stz tmp5
    stz tmp5+1
    ldy #5
@l: jsr PenKick
    adc tmp5
    sta tmp5
    jsr PenKick
    adc tmp5+1
    sta tmp5+1
    dey
    bne @l
    ; morte subita
    ldy #20
@s: lda tmp5
    cmp tmp5+1
    bne @d
    jsr PenKick
    adc tmp5
    sta tmp5
    jsr PenKick
    adc tmp5+1
    sta tmp5+1
    dey
    bne @s
    ; ainda empatado: o primeiro leva
    inc tmp5
@d: lda tmp5
    cmp #15
    bcc :+
    lda #15
:   asl a
    asl a
    asl a
    asl a
    sta tmp
    lda tmp5+1
    cmp #15
    bcc :+
    lda #15
:   ora tmp
    pha
    lda tmp5
    cmp tmp5+1
    pla
    rts                     ; carry do cmp: a >= b (e nunca sao iguais)

; A = 1 (gol, 75%) ou 0; carry limpo
PenKick:
    .a8
    .i16
    lda #4
    jsr RandBelow
    cmp #3
    lda #0
    bcs :+
    lda #1
:   clc
    rts

; ---------------------------------------------------------------- moral e treino
; depois da data: moral de quem jogou sobe/cai com o resultado; banco fica impaciente
UpdateMoral:
    .a8
    .i16
    ldx #0
@s: stx m_side
    lda m_team,x
    cmp #$FF
    bne :+
    jmp @nx
:   jsr SetTeam
    ; resultado do lado
    lda m_side
    eor #1
    A16
    and #$00FF
    tax
    A8
    lda m_goal,x
    sta tmp
    ldx m_side
    lda m_goal,x
    cmp tmp
    beq @e
    bcc @d
    lda #6
    bra @set
@e: lda #1
    bra @set
@d: lda #$FA                ; -6
@set:
    sta tmp2
    ldx pbase
    ldy #SQ
@p: lda f:P_STR,x
    beq @np
    lda f:PLAY,x
    beq @banco
    lda f:P_MOR,x
    clc
    adc tmp2
    bmi @min
    cmp #95
    bcc @st
    lda #95
    bra @st
@min:
    lda #5
    bra @st
@banco:
    lda f:P_MOR,x
    cmp #41
    bcc @np
    dec a
@st:
    cmp #5
    bcs :+
    lda #5
:   sta f:P_MOR,x
@np:
    inx
    dey
    bne @p
@nx:
    ldx m_side
    inx
    cpx #64
    beq :+
    jmp @s
:   rts

; treino do time do usuario: chance de +1 de forca nas posicoes do foco
; train_pid = primeiro que melhorou ($FFFF = ninguem), train_n = quantos
Training:
    .a8
    .i16
    ldx #$FFFF
    stx train_pid
    stz train_n
    lda g_train
    cmp #3
    beq @r                  ; fisico: so reduz lesoes
    lda g_user
    jsr SetTeam
    ldx pbase
    ldy #SQ
@p: phy
    stx pid
    lda f:P_STR,x
    beq @n
    cmp #50
    bcs @n
    lda f:P_AGE,x
    cmp #31
    bcs @n
    lda f:P_POS,x
    and #$03
    sta tmp3
    lda g_train
    beq @eq
    cmp #1
    beq @atq
    ; defesa: goleiro e defensor
    lda tmp3
    cmp #2
    bcs @n
    bra @foco
@atq:
    lda tmp3
    cmp #2
    bcc @n
@foco:
    lda #22
    bra @roll
@eq:
    lda #50
@roll:
    jsr RandBelow
    cmp #0
    bne @n
    ldx pid
    lda f:P_STR,x
    inc a
    sta f:P_STR,x
    lda train_n
    bne :+
    stx train_pid
:   inc train_n
@n: ply
    ldx pid
    inx
    dey
    bne @p
@r: rts

; ---------------------------------------------------------------- diretoria
; depois da data: confianca pelo resultado do usuario e pelo caixa
UpdateConf:
    .a8
    .i16
    lda m_userm+1
    bne @caixa              ; nao jogou
    lda m_userm
    eor #1
    A16
    and #$00FF
    tax
    A8
    lda m_goal,x
    sta tmp
    ldx m_userm
    lda m_goal,x
    cmp tmp
    beq @e
    bcc @d
    lda g_conf
    clc
    adc #5
    jsr SetConfU
    bra @caixa
@e: lda g_conf
    inc a
    jsr SetConfU
    bra @caixa
@d: lda g_conf
    sec
    sbc #6
    bcs :+
    lda #0
:   jsr SetConfU
@caixa:
    lda g_money+3
    bpl @r
    lda g_conf
    sec
    sbc #3
    bcs :+
    lda #0
:   jsr SetConfU
@r: rts
; A = confianca 0..255 sem sinal
SetConfU:
    .a8
    .i16
    cmp #101
    bcc :+
    lda #100
:   sta g_conf
    rts

; ---------------------------------------------------------------- mercado da IA
; ate 2 transferencias entre clubes da IA por rodada (vira noticia)
AiTransfers:
    .a8
    .i16
    jsr CountAll
    lda #2
    sta tmp6+1
@t: lda #10
    sta tmp6                ; tentativas
@try:
    dec tmp6
    bne :+
    jmp @next
:   ; comprador: time da IA com vaga
    lda #64
    jsr RandBelow
    cmp g_user
    beq @try
    sta ai_buy
    A16
    and #$00FF
    tax
    A8
    lda tcnt,x
    cmp #24
    bcs @try
    ; vendedor: outro time da IA com elenco grande
    lda #64
    jsr RandBelow
    cmp g_user
    beq @try
    cmp ai_buy
    beq @try
    sta ai_sell
    A16
    and #$00FF
    tax
    A8
    lda tcnt,x
    cmp #19
    bcc @try
    ; so compra quem esta na mesma serie ou acima
    lda ai_buy
    jsr TeamDiv
    sta tmp
    lda ai_sell
    jsr TeamDiv
    cmp tmp
    bcc @try
    ; jogador sorteado do vendedor
    lda ai_sell
    jsr SetTeam
    lda #SQ
    jsr RandBelow
    A16
    and #$00FF
    clc
    adc pbase
    sta pid
    tax
    A8
    lda f:P_STR,x
    beq @try
    ldx pid
    jsr GetValue
    A16
    sta ai_val
    A8
    lda ai_buy
    jsr MovePlayer
    bcs :+
    jmp @try
:   ; noticia (pid novo = vaga no comprador, guardada em tmp5 por MovePlayer)
    jsr AddNews
    lda ai_buy
    A16
    and #$00FF
    tax
    A8
    inc tcnt,x
    lda ai_sell
    A16
    and #$00FF
    tax
    A8
    dec tcnt,x
@next:
    dec tmp6+1
    beq :+
    jmp @t
:   rts

; guarda a noticia (desloca as antigas): jogador tmp5, comprador ai_buy, vendedor ai_sell, valor ai_val
AddNews:
    .a8
    .i16
    ; desloca 3 noticias (18 bytes) para frente
    ldx #17
@sh:
    lda f:NEWS,x
    sta f:NEWS+6,x
    dex
    bpl @sh
    A16
    lda tmp5
    sta f:NEWS
    lda ai_val
    sta f:NEWS+4
    A8
    lda ai_buy
    sta f:NEWS+2
    lda ai_sell
    sta f:NEWS+3
    lda news_n
    cmp #4
    bcs :+
    inc news_n
:   rts

; ---------------------------------------------------------------- historico
; guarda a temporada que acabou no topo do historico (16 temporadas)
HistPush:
    .a8
    .i16
    ldx #(HIST_N*10 - 11)
@sh:
    lda f:HIST,x
    sta f:HIST+10,x
    dex
    bpl @sh
    A16
    lda g_season
    sta f:HIST
    A8
    lda champ
    sta f:HIST+2
    lda champ+1
    sta f:HIST+3
    lda champ+2
    sta f:HIST+4
    lda champ+3
    sta f:HIST+5
    lda cup_champ
    sta f:HIST+6
    lda g_user
    sta f:HIST+7
    lda u_div
    sta f:HIST+8
    lda u_pos
    sta f:HIST+9
    lda hist_n
    cmp #HIST_N
    bcs :+
    inc hist_n
:   rts

; ---------------------------------------------------------------- contratos
; fim de temporada: contratos diminuem; a IA renova; jogador do usuario
; com contrato vencido vai para outro clube (con_out = quantos sairam)
ContractsEnd:
    .a8
    .i16
    stz con_out
    jsr CountAll
    ldx #0
@p: stx tmp6
    lda f:P_STR,x
    bne :+
    jmp @n
:   lda f:P_CON,x
    beq @venc
    dec a
    sta f:P_CON,x
    bne @n
@venc:
    ; de quem e?
    A16
    stx d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    cmp g_user
    beq @user
    lda #3
    jsr RandBelow
    clc
    adc #2
    ldx tmp6
    sta f:P_CON,x
    bra @n
@user:
    ; procura um clube da IA com vaga
    ldx tmp6
    stx pid
    lda #20
    sta tmp5+1
@try:
    dec tmp5+1
    beq @fica
    lda #64
    jsr RandBelow
    cmp g_user
    beq @try
    sta tmp4
    A16
    and #$00FF
    tax
    A8
    lda tcnt,x
    cmp #MAX_ELENCO
    bcs @try
    inc tcnt,x
    lda tmp4
    jsr MovePlayer
    bcc @fica
    inc con_out
    bra @n
@fica:
    ldx tmp6
    lda #1
    sta f:P_CON,x
@n: ldx tmp6
    inx
    cpx #NP
    beq :+
    jmp @p
:   rts

; renova o contrato do jogador pid por 3 anos (max 5). Luvas = valor/4.
; carry=1 se renovou
Renew:
    .a8
    .i16
    ldx pid
    lda f:P_CON,x
    cmp #3
    bcs @no
    jsr GetValue
    A16
    lsr a
    lsr a
    bne :+
    lda #1
:   sta offer_val
    A8
    jsr MoneyHas
    bcc @no
    A16
    lda offer_val
    A8
    jsr MoneySub
    ldx pid
    lda f:P_CON,x
    clc
    adc #3
    sta f:P_CON,x
    lda f:P_MOR,x
    clc
    adc #10
    cmp #96
    bcc :+
    lda #95
:   sta f:P_MOR,x
    sec
    rts
@no:
    clc
    rts
