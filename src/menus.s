; =====================================================================
;  Fluxo do jogo e menus do clube
; =====================================================================

GameMain:
    .a8
    .i16
@title:
    jsr TitleScreen
    sta gm_mode
    jsr SlotScreen
    bcc @title
    lda gm_mode
    bne @load
    ; novo jogo
    jsr NameEntry
    jsr NewWorld
    jsr PickTeam
    jsr CareerInit
    jsr StartJob
    jsr SaveGame
    bra @hub
@load:
    jsr LoadGame
    bcc @title
    ; jogo salvo de versao anterior: cria a carreira e a meta
    lda c_clubs
    bne @hub
    jsr CareerInit
    inc c_clubs
    jsr CalcGoal
@hub:
    jsr Hub
    bra @title

; ---------------------------------------------------------------- menu do clube
Hub:
    .a8
    .i16
    lda #SONG_MENU
    jsr PlaySong
    stz hub_sel
@redraw:
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    jsr DrawHub
    SCR 5
    jsr ShowScreen
    ; botoes em grade: JOGAR em destaque, 8 atalhos e SALVAR E SAIR
    lda hub_sel
    jsr HubSelect
@m: jsr NextFrame
    lda pad_new+1
    bit #KH_UP
    beq :+
    ldx #.loword(HubUp)
    jsr HubMove
    bra @m
:   bit #KH_DOWN
    beq :+
    ldx #.loword(HubDown)
    jsr HubMove
    bra @m
:   bit #KH_LEFT
    beq :+
    ldx #.loword(HubLeft)
    jsr HubMove
    bra @m
:   bit #KH_RIGHT
    beq :+
    ldx #.loword(HubRight)
    jsr HubMove
    bra @m
:   bit #KH_SEL
    beq :+
    ; SELECT: liga/desliga a musica
    jsr ToggleMusic
    jsr DrawMusicOpt
    bra @m
:   bit #KH_START
    bne @ok
    lda pad_new
    bit #KL_A
    beq @m
@ok:
    SFX SFX_OK
    lda sel
    sta hub_sel
@esc:
    lda sel
    cmp #9
    bne :+
    jmp SaveGame            ; salvar e sair
:   A16
    and #$00FF
    asl a
    tax
    A8
    jsr (HubJump,x)
    jmp @redraw

HubJump: .word HubPlay, SquadScreen, TrainScreen, TableScreen, ResultsScreen
         .word CupScreen, MarketScreen, FinanceScreen, HistoryScreen

; jogar a proxima data (ou encerrar a temporada)
HubPlay:
    .a8
    .i16
    lda g_date
    cmp #CAL_N
    bcc :+
    jmp SeasonFlow
:   jsr StopMusic
    jsr PlayRound
    jsr AfterRound
    lda #SONG_MENU
    jmp PlaySong

DrawHub:
    .a8
    .i16
    lda #216
    sta tmp5
    lda #24
    sta tmp5+1
    stz shd_slot
    lda g_user
    jsr DrawShield
    ldx #(1*32+2)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    lda g_user
    jsr PrintTeam
    lda #$20
    sta txt_attr
    ldx #.loword(TXT_SERIE_SP)
    jsr PrintStr
    lda g_user
    jsr TeamDiv
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_TECNICO, 2, 2, 4
    lda #<g_coach
    sta txt_ptr
    lda #>g_coach
    sta txt_ptr+1
    stz txt_ptr+2
    ldy #10
    jsr PrintFixed
    PRINT TXT_TEMPORADA, 2, 3, 0
    A16
    lda g_season
    sta num
    stz num+2
    A8
    lda #4
    sta num_w
    jsr PrintNum
    ldx #.loword(TXT_ROD_CURTA)
    jsr PrintStr
    lda g_round
    inc a
    cmp #31
    bcc :+
    lda #30
:   ldy #2
    jsr PrintN8
    ldx #.loword(TXT_DE30)
    jsr PrintStr
    PRINT TXT_CAIXA, 2, 4, 0
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_POSICAO, 2, 5, 0
    lda g_user
    jsr TeamRank
    ldy #2
    jsr PrintN8
    lda #FONT_ORD
    jsr PrintChar
    ldx #.loword(TXT_META)
    jsr PrintStr
    lda g_goal
    ldy #2
    jsr PrintN8
    lda #FONT_ORD
    jsr PrintChar
    ; proximo jogo
    lda g_date
    cmp #CAL_N
    bcc :+
    PRINT TXT_FIM_TEMP, 2, 6, 1
    bra @copa
:   jsr IsCupDate
    bcs @pcopa
    PRINT TXT_PROXIMO, 2, 6, 0
    jsr NextOpp
    bra @adv
@pcopa:
    PRINT TXT_PROX_COPA, 2, 6, 1
    jsr UserInCup
    bcs :+
    ldx #.loword(TXT_SEM_JOGO_C)
    jsr PrintStr
    bra @copa
:   ; adversario na chave e mando
    sta tmp
    eor #1
    A16
    and #$00FF
    tax
    A8
    lda f:CUP_LIST,x
    sta fx_h
    lda tmp
    and #1
    eor cup_leg
    eor #1
    sta fx_a                ; 1 = em casa
@adv:
    lda fx_h
    jsr PrintTeam
    lda fx_a
    beq :+
    ldx #.loword(TXT_CASA)
    bra :++
:   ldx #.loword(TXT_FORA_C)
:   jsr PrintStr
@copa:
    ; situacao na copa
    PRINT TXT_COPA_SIT, 2, 7, 0
    lda cup_champ
    cmp g_user
    bne :+
    ldx #.loword(TXT_CAMPEAO_C)
    bra @cs
:   jsr UserInCup
    bcs :+
    ldx #.loword(TXT_ELIMINADO)
    bra @cs
:   lda cup_phase
    A16
    and #$00FF
    asl a
    tax
    lda CupPhaseTxt,x
    tax
    A8
@cs:
    jsr PrintStr
    ; confianca da diretoria
    PRINT TXT_DIRETORIA, 2, 8, 0
    jsr DrawConfBar
    ; botoes e icones
    ldx #0
@bt:
    phx
    txa
    jsr HubPos
    plx
    phx
    lda #STY_NORMAL
    cpx #0
    bne :+
    lda #STY_PRI
:   sta ui_style
    jsr UiBtn
    ; icone dentro do botao
    lda ui_col
    inc a
    asl a
    asl a
    asl a
    sta tmp5
    lda ui_w
    cmp #30
    bne :+
    lda tmp5
    clc
    adc #24
    sta tmp5
:   lda ui_row
    asl a
    asl a
    asl a
    sec
    sbc #4
    sta tmp5+1
    pla
    pha
    jsr DrawIcon
    plx
    inx
    cpx #10
    bne @bt
    lda g_date
    cmp #CAL_N
    bcc :+
    PRINT TXT_M_ENCERRAR, 8, 10, 0
    bra :++
:   PRINT TXT_M_JOGAR, 8, 10, 0
:   PRINT TXT_M_ESCALACAO, 5, 12, 0
    PRINT TXT_M_TREINO, 20, 12, 0
    PRINT TXT_M_TABELA, 5, 14, 0
    PRINT TXT_M_RESULTADOS, 20, 14, 0
    PRINT TXT_M_COPA, 5, 16, 0
    PRINT TXT_M_MERCADO, 20, 16, 0
    PRINT TXT_M_FINANCAS, 5, 18, 0
    PRINT TXT_M_HISTORICO, 20, 18, 0
    PRINT TXT_M_SAIR, 8, 20, 0
    jsr DrawMusicOpt
    ; avisos
    lda g_conf
    cmp #25
    bcs :+
    PRINT TXT_ALERTA_DIR, 1, 22, 3
    rts
:   lda g_money+3
    bpl :+
    PRINT TXT_ALERTA_CX, 2, 22, 3
:   rts

; posicao do botao A do menu do clube -> ui_row, ui_col, ui_w
HubPos:
    .a8
    .i16
    cmp #0
    bne :+
    lda #10
    bra @cheio
:   cmp #9
    bne @grade
    lda #20
@cheio:
    sta ui_row
    lda #1
    sta ui_col
    lda #30
    sta ui_w
    rts
@grade:
    dec a
    pha
    and #$FE                ; (i-1) sem o bit da coluna = 2 * linha da grade
    clc
    adc #12
    sta ui_row
    pla
    and #1
    beq :+
    lda #15
:   inc a
    sta ui_col              ; coluna 1 ou 16
    lda #15
    sta ui_w
    rts

; marca o botao A como selecionado (sel = A)
HubSelect:
    .a8
    .i16
    sta sel
    stz sel+1
    jsr HubPos
    lda #STY_SEL
    sta ui_style
    jmp UiBtn

; move a selecao pela tabela X (cima, baixo, esquerda ou direita)
HubMove:
    .a8
    .i16
    stx tmp
    ldy sel
    lda (tmp),y
    cmp sel
    bne :+
    rts
:   pha
    ; botao antigo volta ao estilo de repouso
    lda sel
    jsr HubPos
    lda #STY_NORMAL
    ldx sel
    bne :+
    lda #STY_PRI
:   sta ui_style
    jsr UiBtn
    SFX SFX_CURSOR
    pla
    jmp HubSelect

HubUp:    .byte 0, 0, 0, 1, 2, 3, 4, 5, 6, 7
HubDown:  .byte 1, 3, 4, 5, 6, 7, 8, 9, 9, 9
HubLeft:  .byte 0, 1, 1, 3, 3, 5, 5, 7, 7, 9
HubRight: .byte 0, 2, 2, 4, 4, 6, 6, 8, 8, 9

; barra de 10 quadrados com a confianca (verde, amarelo ou vermelho) + numero
DrawConfBar:
    .a8
    .i16
    lda g_conf
    cmp #50
    bcc :+
    lda #($20 | (2<<2))
    bra @c
:   cmp #25
    bcc :+
    lda #($20 | (1<<2))
    bra @c
:   lda #($20 | (3<<2))
@c: sta tmp3
    ; quadrados cheios = (conf + 5) / 10
    lda g_conf
    clc
    adc #5
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
    lda RDDIVL
    sta tmp4
    ldy #0
@l: tya
    cmp tmp4
    bcs @vz
    lda tmp3
    sta txt_attr
    lda #FONT_SQ
    bra @p
@vz:
    lda #($20 | (4<<2))
    sta txt_attr
    lda #FONT_MINUS
@p: jsr PrintChar
    iny
    cpy #10
    bne @l
    lda #$20
    sta txt_attr
    lda #FONT_SPACE
    jsr PrintChar
    lda g_conf
    ldy #3
    jsr PrintN8
    lda #FONT_PCT
    jmp PrintChar

; indicador da musica no rodape do menu do clube
DrawMusicOpt:
    .a8
    .i16
    PRINT TXT_MUSICA, 2, 26, 4
    lda opt_music
    beq :+
    ldx #.loword(TXT_LIGADA)
    jmp PrintStr
:   ldx #.loword(TXT_DESLIGADA)
    jmp PrintStr

; adversario do usuario na rodada g_round -> fx_h = time, fx_a = 1 se em casa
NextOpp:
    .a8
    .i16
    lda g_round
    sta cal_r
; idem, na rodada cal_r
NextOppR:
    lda g_user
    jsr TeamDiv
    sta div
    stz div+1
    ldy #0
@l: phy
    lda cal_r
    jsr GetFixture
    ply
    lda fx_h
    cmp g_user
    beq @casa
    lda fx_a
    cmp g_user
    beq @fora
    iny
    cpy #8
    bne @l
@fora:
    lda fx_h
    stz fx_a
    sta fx_h
    rts
@casa:
    lda fx_a
    sta fx_h
    lda #1
    sta fx_a
    rts

; jogo Y (0..7) da divisao div na rodada A -> fx_h, fx_a (times)
GetFixture:
    .a8
    .i16
    sta fx_r
    cmp #15
    bcc :+
    sbc #15
:   A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    sta tmp
    tya
    and #$0007
    asl a
    clc
    adc tmp
    tax
    A8
    lda FixTab,x
    sta fx_h
    lda FixTab+1,x
    sta fx_a
    lda fx_r
    cmp #15
    bcc :+
    lda fx_h
    pha
    lda fx_a
    sta fx_h
    pla
    sta fx_a
:   lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp
    clc
    adc fx_h
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    sta fx_h
    lda tmp
    clc
    adc fx_a
    A16
    and #$00FF
    tax
    A8
    lda f:DIVT,x
    sta fx_a
    rts

; ---------------------------------------------------------------- depois da rodada
AfterRound:
    .a8
    .i16
    ; convocacoes para a selecao depois das rodadas 8, 16 e 24
    stz sel_n
    lda m_iscup
    bne @sum
    lda g_round
    cmp #8
    beq :+
    cmp #16
    beq :+
    cmp #24
    bne @sum
:   jsr Convoca
@sum:
    jsr RoundSummary
    jsr RoundOffers
    ldx offer_pid
    cpx #$FFFF
    beq :+
    jsr OfferScreen
:   ; diretoria perdeu a paciencia?
    lda g_conf
    bne @ok
    lda #1
    sta job_fired
    inc c_fired
    lda #$F8
    jsr RepAdd
    lda g_user
    jsr TeamDiv
    inc a
    cmp #4
    bcc :+
    lda #3
:   jsr MakeJobs
    jsr JobScreen
    bra @sv
@ok:
    jsr MidInvite
@sv:
    jsr SaveGame
    rts

; resumo: resultado do usuario e dinheiro da rodada
RoundSummary:
    .a8
    .i16
    SCR 7
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    lda m_iscup
    beq :+
    PRINT TXT_COPA_T, 2, 1, 1
    bra :++
:   PRINT TXT_RODADA_FIM, 2, 1, 1
:   lda m_userm+1
    beq :+
    PRINT TXT_NAO_JOGOU, 1, 3, 4
    jmp @din
:   ; placar do usuario
    A16
    lda m_userm
    and #$00FE
    sta dl_idx
    A8
    ldx #(3*32+1)
    stx txt_pos
    lda #$20
    sta txt_attr
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
    ldy #1
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    ldx dl_idx
    lda m_team+1,x
    jsr PrintTeam
    ; vitoria/empate/derrota
    ldx dl_idx
    lda m_goal,x
    sta tmp
    lda m_goal+1,x
    sta tmp+1
    lda m_userm
    and #1
    beq :+
    lda tmp
    xba
    lda tmp+1
    sta tmp
    xba
    sta tmp+1
:   lda tmp
    cmp tmp+1
    beq @emp
    bcc @der
    PRINT TXT_VITORIA, 2, 4, 2
    SFX SFX_GOL
    lda #2
    jsr CareerResult
    bra @cup
@emp:
    PRINT TXT_EMPATE, 2, 4, 0
    lda #1
    jsr CareerResult
    bra @cup
@der:
    PRINT TXT_DERROTA, 2, 4, 3
    lda #0
    jsr CareerResult
@cup:
    jsr MatchStats
    ; copa: resultado da volta
    lda m_iscup
    beq @gols
    lda cup_leg
    bne @gols               ; foi a ida
    jsr UserInCup
    bcc :+
    PRINT TXT_CLASSIFICADO, 14, 4, 2
    bra @gols
:   lda cup_champ
    cmp g_user
    bne :+
    PRINT TXT_CAMPEAO_C, 14, 4, 2
    bra @gols
:   PRINT TXT_ELIM_COPA, 14, 4, 3
@gols:
    jsr SummaryGoals
    jsr Destaque
@din:
    ; dinheiro
    PRINT TXT_CAIXA, 2, 12, 1
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_RS_ENTROU, 2, 13, 0
    A16
    lda g_f_tv
    clc
    adc g_f_bil
    clc
    adc g_cupprize
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_RS_SAIU)
    jsr PrintStr
    A16
    lda g_f_sal
    clc
    adc g_juros
    A8
    ldy #6
    jsr PrintN16
    lda m_userm+1
    bne :+
    lda m_userm
    and #1
    bne :+
    PRINT TXT_PUBLICO, 2, 14, 4
    A16
    lda g_att
    A8
    ldy #6
    jsr PrintN16
:   ; posicao e diretoria
    PRINT TXT_POSICAO, 2, 15, 0
    lda g_user
    jsr TeamRank
    ldy #2
    jsr PrintN8
    lda #FONT_ORD
    jsr PrintChar
    PRINT TXT_DIRETORIA, 2, 16, 0
    jsr DrawConfBar
    ; treino
    lda train_n
    beq :+
    PRINT TXT_TR_ULT, 2, 18, 2
    ldx train_pid
    jsr PrintPName
:   lda sel_n
    beq :+
    PRINT TXT_CONVOC, 2, 19, 6
    lda sel_n
    ldy #2
    jsr PrintN8
:   ; noticias do mercado
    lda m_iscup
    bne @fim
    lda news_n
    beq @fim
    PRINT TXT_NOTICIAS, 2, 20, 4
    ldy #0
@n: cpy #2
    bcs @fim
    tya
    cmp news_n
    bcs @fim
    phy
    tya
    clc
    adc #21
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
    tya
    asl a
    sta tmp
    asl a
    clc
    adc tmp                 ; *6
    sta tmp5
    A8
    lda #$20
    sta txt_attr
    ldx tmp5
    lda f:NEWS+2,x
    jsr PrintAbbr
    lda #FONT_COLON
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    ldx tmp5
    A16
    lda f:NEWS,x
    tax
    A8
    jsr PrintPName
    ldx #.loword(TXT_DO)
    jsr PrintStr
    ldx tmp5
    lda f:NEWS+3,x
    jsr PrintAbbr
    ply
    iny
    bra @n
@fim:
    PRINT TXT_CONTINUAR_A, 2, 25, 4
    jsr ShowScreen
    jsr WaitAB
    rts

; lista os gols do jogo do usuario (ate 4) nas linhas 6..9 (titulo na linha 5)
SummaryGoals:
    .a8
    .i16
    lda u_ngols
    bne :+
    rts
:   PRINT TXT_GOLS_T, 2, 5, 4
    ldy #0
@g: cpy #4
    bcc :+
    rts
:   tya
    cmp u_ngols
    bcc :+
    rts
:   phy
    ; linha 6+i, coluna 8
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
    adc #2
    sta txt_pos
    tya
    sta tmp
    asl a
    clc
    adc tmp                 ; *3
    sta tmp5
    tax
    A8
    ; cor: gol do usuario verde, do adversario vermelho
    lda u_gols,x
    and #$80
    beq :+
    lda #1
:   cmp #0
    beq :+
    lda #1
:   eor m_userm
    and #1
    beq :+
    lda #($20 | (3<<2))
    bra :++
:   lda #($20 | (2<<2))
:   sta txt_attr
    ldx tmp5
    lda u_gols,x
    and #$7F
    ldy #2
    jsr PrintN8
    lda #FONT_APOS
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    ldx tmp5
    lda u_gols+2,x
    bpl :+
    ldx #.loword(TXT_EV_CON)
    jsr PrintStr
    ldx tmp5
:   A16
    lda u_gols+1,x
    and #$7FFF
    cmp #$7FFF
    beq :+
    tax
    A8
    jsr PrintPName
    bra :++
:   A8
:   ply
    iny
    jmp @g

; destaque do time do usuario: quem fez mais gols; senao o mais forte em campo
Destaque:
    .a8
    .i16
    ldx #$FFFF
    stx pid
    stz tmp6                ; melhor contagem
    ldy #0
@a: tya
    cmp u_ngols
    bcs @fim
    phy
    jsr DestCount           ; A = gols do jogador do gol Y (0 se nao conta)
    ply
    cmp tmp6
    beq @nx
    bcc @nx
    sta tmp6
    A16
    lda tmp3
    sta pid
    A8
@nx:
    iny
    bra @a
@fim:
    ldx pid
    cpx #$FFFF
    bne @mostra
    ; ninguem marcou: o mais forte em campo
    lda g_user
    jsr SetTeam
    stz tmp6
    ldx pbase
    ldy #SQ
@f: lda f:PLAY,x
    beq @fn
    lda f:P_STR,x
    cmp tmp6
    bcc @fn
    sta tmp6
    stx pid
@fn:
    inx
    dey
    bne @f
    ldx pid
    cpx #$FFFF
    bne @mostra
    rts
@mostra:
    PRINT TXT_DESTAQUE, 2, 10, 1
    ldx pid
    jmp PrintPName

; gol Y: se for do usuario (lado certo, nao contra), conta quantos gols o mesmo jogador fez
; A = contagem, tmp3 = jogador
DestCount:
    .a8
    .i16
    tya
    A16
    and #$00FF
    sta tmp
    asl a
    clc
    adc tmp
    tax
    A8
    lda u_gols,x
    rol a
    rol a
    and #1                  ; lado de quem fez
    eor m_userm
    and #1
    bne @no
    lda u_gols+2,x
    bmi @no                 ; gol contra
    A16
    lda u_gols+1,x
    sta tmp3
    A8
    ; conta
    stz tmp4
    ldy #0
@c: tya
    cmp u_ngols
    bcs @r
    A16
    and #$00FF
    sta tmp
    asl a
    clc
    adc tmp
    tax
    lda u_gols+1,x
    cmp tmp3
    A8
    bne :+
    inc tmp4
:   iny
    bra @c
@r: lda tmp4
    rts
@no:
    lda #0
    rts

; proposta por jogador do usuario
OfferScreen:
    .a8
    .i16
    SCR 8
    jsr BeginScreen
    PRINT TXT_PROPOSTA, 2, 3, 1
    ldx #(6*32+2)
    stx txt_pos
    lda #$20
    sta txt_attr
    lda offer_team
    jsr PrintTeam
    PRINT TXT_OFERECE, 2, 8, 0
    A16
    lda offer_val
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL_POR)
    jsr PrintStr
    ldx #(10*32+2)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    ldx offer_pid
    jsr PrintPos
    lda #FONT_SPACE
    jsr PrintChar
    ldx offer_pid
    jsr PrintPName
    PRINT TXT_FORCA, 2, 12, 0
    ldx offer_pid
    lda f:P_STR,x
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_IDADE_SP)
    jsr PrintStr
    ldx offer_pid
    lda f:P_AGE,x
    ldy #2
    jsr PrintN8
    PRINT TXT_VALOR, 2, 13, 0
    ldx offer_pid
    jsr GetValue
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    lda #20
    sta ui_row
    lda #2
    sta ui_col
    lda #13
    sta ui_w
    lda #STY_OK
    sta ui_style
    jsr UiBtn
    lda #17
    sta ui_col
    lda #STY_BAD
    sta ui_style
    jsr UiBtn
    PRINT TXT_BT_ACEITAR, 4, 20, 0
    PRINT TXT_BT_RECUSAR, 19, 20, 0
    jsr ShowScreen
    jsr WaitAB
    cmp #0
    beq @no
    A16
    lda offer_pid
    sta pid
    A8
    lda offer_team
    jsr MovePlayer
    bcc @no
    A16
    lda offer_val
    A8
    jsr MoneyAdd
    A16
    lda offer_val
    clc
    adc g_f_trans
    sta g_f_trans
    lda g_f_trans+2
    adc #0
    sta g_f_trans+2
    A8
    SFX SFX_MOEDA
    rts
@no:
    ; recusou: o jogador sai da lista de venda? continua a venda
    rts

; ---------------------------------------------------------------- temporada
SeasonFlow:
    .a8
    .i16
    jsr AwardsScreen
    SCR 9
    jsr SeasonEnd
    jsr FillSquads
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_FIM_TEMPORADA, 2, 2, 1
    A16
    lda g_season
    dec a
    sta num
    stz num+2
    A8
    lda #4
    sta num_w
    jsr PrintNum
    PRINT TXT_CAMPEOES, 2, 5, 2
    ldy #0
@c: phy
    tya
    asl a
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
    ldx #.loword(TXT_SERIE)
    jsr PrintStr
    pla
    pha
    clc
    adc #FONT_LA
    jsr PrintChar
    lda #FONT_COLON
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    ply
    phy
    lda champ,y
    jsr PrintTeam
    ply
    iny
    cpy #4
    bne @c
    ; campeao da copa (guardado no historico)
    lda f:HIST+6
    cmp #$FF
    beq :+
    PRINT TXT_COPA_CAMP, 4, 15, 2
    lda f:HIST+6
    jsr PrintTeam
:   ; resultado do usuario
    PRINT TXT_SEU_TIME, 2, 17, 0
    lda u_pos
    ldy #2
    jsr PrintN8
    lda #FONT_ORD
    jsr PrintChar
    ldx #.loword(TXT_NA_SERIE)
    jsr PrintStr
    lda u_div
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_PREMIO, 2, 20, 1
    A16
    lda g_prize
    A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    lda con_out
    beq :+
    PRINT TXT_CONTRATO_FIM, 2, 22, 5
    lda con_out
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_CONTRATO_FIM2)
    jsr PrintStr
:
    stz job_fired
    lda g_user
    jsr TeamDiv
    sta tmp6
    cmp u_div
    beq @mesma
    bcc @subiu
    ; rebaixado: demitido
    PRINT TXT_REBAIXADO, 2, 19, 3
    lda #1
    sta job_fired
    lda #SONG_DERROTA
    jsr PlaySong
    bra @w
@subiu:
    lda g_conf
    clc
    adc #25
    jsr SetConfU
    PRINT TXT_ACESSO, 2, 19, 2
    lda #SONG_VITORIA
    jsr PlaySong
    bra @w
@mesma:
    lda u_pos
    cmp #1
    bne @w
    lda #100
    sta g_conf
    PRINT TXT_CAMPEAO, 2, 19, 2
    lda #SONG_VITORIA
    jsr PlaySong
@w: jsr SeasonCareer
    PRINT TXT_CONTINUAR_A, 2, 25, 4
    jsr ShowScreen
    jsr WaitAB
    ; emprego
    lda job_fired
    beq @boa
    lda tmp6
    jsr MakeJobs
    jsr JobScreen
    bra @fim
@boa:
    ; campanha boa: proposta de um clube maior
    lda u_pos
    cmp #3
    bcs @fim
    lda tmp6
    beq @fim
    dec a
    jsr MakeJobs
    jsr JobScreen
@fim:
    jsr CalcGoal
    lda g_user
    jsr SetTeam
    jsr FixUserLineup
    lda #SONG_MENU
    jsr PlaySong
    jmp SaveGame

; ofertas de emprego (job_list); job_fired = sem opcao de ficar
JobScreen:
    .a8
    .i16
    SCR 10
    jsr BeginScreen
    lda #BG_MENU
    jsr LoadBg
    lda job_fired
    beq :+
    PRINT TXT_DEMITIDO, 2, 3, 3
    PRINT TXT_DEMITIDO2, 2, 5, 0
    bra :++
:   PRINT TXT_CONVITE, 2, 3, 2
    PRINT TXT_CONVITE2, 2, 5, 0
:   ldy #0
@l: phy
    tya
    asl a
    clc
    adc #9
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    clc
    adc #6
    sta txt_pos
    A8
    lda #$20
    sta txt_attr
    lda job_list,y
    pha
    jsr PrintTeam
    ldx #.loword(TXT_SERIE_SP)
    jsr PrintStr
    pla
    jsr TeamDiv
    clc
    adc #FONT_LA
    jsr PrintChar
    ply
    iny
    cpy #3
    bne @l
    lda #3
    sta menu_n
    lda job_fired
    bne :+
    PRINT TXT_FICAR, 6, 15, 0
    lda #4
    sta menu_n
:   jsr ShowScreen
    lda #9
    sta menu_row0
    lda #2
    sta menu_step
    ldx #4
    stx arr_col
    stz sel
    stz sel+1
    lda #4
    sta bm_col
    lda #26
    sta bm_w
    lda #$FF
    sta bm_pri
    sta bm_bad
    jsr MenuButtons
@m: jsr RunMenu
    bcc @m
    lda sel
    cmp #3
    bcs @stay
    A16
    and #$00FF
    tax
    A8
    lda job_list,x
    sta g_user
    jsr StartJob
@stay:
    rts

; ---------------------------------------------------------------- escalacao
SquadScreen:
    .a8
    .i16
    SCR 11
    jsr BeginScreen
    jsr SquadList
    stz sel
    stz sel+1
    stz top
    stz top+1
    jsr SquadDraw
    jsr ShowScreen
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
    jsr SquadScroll
    bra @l
:   bit #KH_DOWN
    beq :+
    lda sel
    inc a
    cmp sq_n
    bcs @l
    sta sel
    jsr SquadScroll
    bra @l
:   bit #KH_SEL
    beq :+
    lda g_style
    inc a
    cmp #3
    bcc @s
    lda #0
@s: sta g_style
    jsr SquadDraw
    bra @l
:   bit #KH_Y
    beq :+
    jsr SquadSell
    jsr SquadDraw
    bra @l
:   lda pad_new
    bit #KL_X
    beq :+
    jsr UserAutoPick
    SFX SFX_OK
    jsr SquadDraw
    jmp @l
:   bit #KL_L
    beq :+
    lda g_form
    inc a
    cmp #FORM_N
    bcc @fm
    lda #0
@fm:
    sta g_form
    jsr UserAutoPick
    SFX SFX_CURSOR
    jsr SquadDraw
    jmp @l
:   bit #KL_R
    beq :+
    jsr SquadRenew
    jsr SquadDraw
    jmp @l
:   bit #KL_A
    bne :+
    jmp @l
:   jsr SquadToggle
    jsr SquadDraw
    jmp @l

; mantem o cursor visivel (18 linhas) e redesenha
SquadScroll:
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
:   jmp SquadDraw

; lista do elenco ordenada por posicao -> sq_list / sq_n
SquadList:
    .a8
    .i16
    lda g_user
; A = time
SquadListT:
    jsr SetTeam
    stz sq_n
    lda #0
@p: sta tmp4
    ldy #0
@s: A16
    tya
    clc
    adc pbase
    tax
    A8
    lda f:P_STR,x
    beq @n
    lda f:P_POS,x
    and #$03
    cmp tmp4
    bne @n
    phy
    lda sq_n
    A16
    and #$00FF
    tax
    A8
    pla
    pha
    sta sq_list,x
    inc sq_n
    ply
@n: iny
    cpy #SQ
    bne @s
    lda tmp4
    inc a
    cmp #4
    bne @p
    rts

; posicao de A (vaga) em g_lineup -> A (0..15) ou $FF
LineupIdx:
    .a8
    .i16
    ldx #0
@l: cmp g_lineup,x
    beq @f
    inx
    cpx #16
    bne @l
    lda #$FF
    rts
@f: txa
    rts

SquadDraw:
    .a8
    .i16
    jsr ClearBg3
    lda #BG_MENU
    jsr LoadBg
    ldx #(1*32+2)
    stx txt_pos
    lda #($20 | (1<<2))
    sta txt_attr
    lda g_user
    jsr PrintTeam
    ; esquema (D-M-A dos titulares)
    stz pick_need
    stz pick_need+1
    stz pick_need+2
    stz pick_need+3
    ldx #0
@f: lda g_lineup,x
    cmp #$FF
    beq :+
    jsr SlotPos
    phx
    A16
    and #$00FF
    tax
    A8
    inc pick_need,x
    plx
:   inx
    cpx #11
    bne @f
    ldx #(2*32+2)
    stx txt_pos
    lda #$20
    sta txt_attr
    lda pick_need+1
    ldy #1
    jsr PrintN8
    lda #FONT_MINUS
    jsr PrintChar
    lda pick_need+2
    ldy #1
    jsr PrintN8
    lda #FONT_MINUS
    jsr PrintChar
    lda pick_need+3
    ldy #1
    jsr PrintN8
    ldx #.loword(TXT_ESTILO_SP)
    jsr PrintStr
    lda g_style
    A16
    and #$00FF
    asl a
    tax
    lda StyleTxt,x
    tax
    A8
    jsr PrintStr
    PRINT TXT_SQ_COLS, 2, 4, 4
    ; linhas
    ldy #0
@r: phy
    tya
    clc
    adc top
    cmp sq_n
    bcc :+
    jmp @skip
:   sta tmp6                ; item
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
    sta sq_rowpos
    A8
    ; cor: cursor amarelo
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
    lda tmp6
    A16
    and #$00FF
    tax
    A8
    lda sq_list,x
    sta tmp6+1              ; vaga
    jsr LineupIdx
    cmp #11
    bcc @tit
    cmp #$FF
    bne @res
    lda #FONT_SPACE
    bra @mk
@tit:
    lda #FONT_LT
    bra @mk
@res:
    lda #FONT_LR
@mk:
    jsr PrintChar
    lda #FONT_SPACE
    jsr PrintChar
    lda tmp6+1
    A16
    and #$00FF
    clc
    adc pbase
    sta pid
    tax
    A8
    jsr PrintPos
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    jsr PrintPName
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    lda f:P_STR,x
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    lda f:P_AGE,x
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    jsr PrintStatus
    ; contrato (anos) e moral
    A16
    lda sq_rowpos
    clc
    adc #28
    sta txt_pos
    A8
    ldx pid
    lda f:P_CON,x
    cmp #2
    lda #$20
    bcs :+
    lda #($20 | (5<<2))
:   sta txt_attr
    lda f:P_CON,x
    ldy #1
    jsr PrintN8
    ldx pid
    lda f:P_MOR,x
    cmp #65
    bcc :+
    lda #($20 | (2<<2))
    sta txt_attr
    lda #FONT_UP
    bra @mor
:   cmp #35
    bcs :+
    lda #($20 | (3<<2))
    sta txt_attr
    lda #FONT_DN
    bra @mor
:   lda #($20 | (4<<2))
    sta txt_attr
    lda #FONT_MINUS
@mor:
    jsr PrintChar
@skip:
    ply
    iny
    cpy #17
    beq :+
    jmp @r
:   ; detalhes do selecionado
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
    PRINT TXT_SQ_MORAL, 2, 22, 4
    ldx pid
    lda f:P_MOR,x
    ldy #2
    jsr PrintN8
    ldx #.loword(TXT_SQ_CONT)
    jsr PrintStr
    ldx pid
    lda f:P_CON,x
    ldy #1
    jsr PrintN8
    ldx #.loword(TXT_SQ_ANOS)
    jsr PrintStr
    PRINT TXT_VALOR, 2, 23, 0
    ldx pid
    jsr GetValue
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_SAL_SP)
    jsr PrintStr
    ldx pid
    jsr GetSalary
    ldy #4
    jsr PrintN16
    ldx #.loword(TXT_GOLS_SP)
    jsr PrintStr
    ldx pid
    lda f:P_GOL,x
    ldy #2
    jsr PrintN8
    ; faixa na linha do cursor
    lda sel
    sec
    sbc top
    clc
    adc #5
    jsr UiBarOn
    PRINT TXT_SQ_H, 1, 25, 4
    PRINT TXT_SQ_H2, 1, 26, 4
    rts

; situacao do jogador X (3 letras)
PrintStatus:
    .a8
    .i16
    lda f:P_OUT,x
    and #$0F
    beq @ok
    lda f:P_OUT,x
    bmi @les
    bit #$20
    beq :+
    lda #($20 | (6<<2))
    sta txt_attr
    ldx #.loword(TXT_SEL)
    jmp PrintStr
:   lda #($20 | (3<<2))
    sta txt_attr
    ldx #.loword(TXT_SUS)
    jmp PrintStr
@les:
    lda #($20 | (5<<2))
    sta txt_attr
    ldx #.loword(TXT_LES)
    jmp PrintStr
@ok:
    lda f:P_POS,x
    bpl :+
    lda #($20 | (2<<2))
    sta txt_attr
    ldx #.loword(TXT_VND)
    jmp PrintStr
:   rts

; A no jogador: fora -> titular -> reserva -> fora
SquadToggle:
    .a8
    .i16
    lda sel
    A16
    and #$00FF
    tax
    A8
    lda sq_list,x
    sta tmp6+1
    jsr LineupIdx
    cmp #$FF
    beq @add
    cmp #11
    bcs @rem
    ; titular -> reserva (se houver vaga)
    sta tmp4
    jsr FreeRes
    cmp #$FF
    beq :+
    A16
    and #$00FF
    tay
    A8
    lda tmp6+1
    sta g_lineup,y
:   lda tmp4
    A16
    and #$00FF
    tax
    A8
    lda #$FF
    sta g_lineup,x
    SFX SFX_CURSOR
    rts
@rem:
    A16
    and #$00FF
    tax
    A8
    lda #$FF
    sta g_lineup,x
    SFX SFX_CURSOR
    rts
@add:
    ; nao pode quem esta lesionado/suspenso
    lda tmp6+1
    A16
    and #$00FF
    clc
    adc pbase
    tax
    A8
    lda f:P_OUT,x
    and #$0F
    bne @err
    ldx #0
@t: lda g_lineup,x
    cmp #$FF
    beq @put
    inx
    cpx #11
    bne @t
    jsr FreeRes
    cmp #$FF
    beq @err
    A16
    and #$00FF
    tax
    A8
@put:
    lda tmp6+1
    sta g_lineup,x
    SFX SFX_OK
    rts
@err:
    SFX SFX_ERRO
    rts

; primeira vaga livre entre os reservas -> A (11..15) ou $FF
FreeRes:
    .a8
    .i16
    ldx #11
@l: lda g_lineup,x
    cmp #$FF
    beq @f
    inx
    cpx #16
    bne @l
    lda #$FF
    rts
@f: txa
    rts

; R: renova o contrato do jogador do cursor (3 anos, luvas = valor/4)
SquadRenew:
    .a8
    .i16
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
    tax
    A8
    lda f:P_CON,x
    cmp #3
    bcc :+
    ldx #.loword(TXT_T_CONTRATO)
    lda #STY_BAD
    jmp UiToast
:   ; caixa de confirmacao: nome, luvas e prazo
    jsr ConfirmOpen
    PRINT TXT_RENOVA, 5, 10, 1
    ldx #(11*32+5)
    stx txt_pos
    lda #$20
    sta txt_attr
    ldx pid
    jsr PrintPName
    PRINT TXT_LUVAS, 5, 12, 4
    ldx pid
    jsr GetValue
    A16
    lsr a
    lsr a
    bne :+
    lda #1
:   A8
    ldy #6
    jsr PrintN16
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    jsr ConfirmAsk
    cmp #0
    beq @r
    jsr Renew
    bcc :+
    SFX SFX_MOEDA
    ldx #.loword(TXT_T_RENOVADO)
    lda #STY_OK
    jmp UiToast
:   SFX SFX_ERRO
    ldx #.loword(TXT_SEM_DINHEIRO)
    lda #STY_BAD
    jmp UiToast
@r: rts

; Y: poe/tira da lista de venda
SquadSell:
    .a8
    .i16
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
    tax
    A8
    lda f:P_POS,x
    eor #$80
    sta f:P_POS,x
    SFX SFX_CURSOR
    rts

; ---------------------------------------------------------------- classificacao
TableScreen:
    .a8
    .i16
    SCR 12
    lda g_user
    jsr TeamDiv
    sta div
    stz div+1
    jsr BeginScreen
@redraw:
    jsr ClearBg3
    jsr TableDraw
    lda bright
    bpl :+
    jsr ShowScreen
:
@l: jsr NextFrame
    lda pad_new+1
    bit #KH_B
    bne @x
    bit #KH_LEFT
    beq :+
    lda div
    beq @l
    dec div
    bra @redraw
:   bit #KH_RIGHT
    beq @l
    lda div
    cmp #3
    bcs @l
    inc div
    bra @redraw
@x: rts

TableDraw:
    .a8
    .i16
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_CLASSIF, 1, 1, 1
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    PRINT TXT_TAB_COLS, 1, 3, 4
    lda div
    jsr SortDiv
    ldy #0
@r: phy
    tya
    clc
    adc #4
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
    ; cor: usuario amarelo, zona de acesso verde, rebaixamento vermelho
    lda #$20
    sta tmp
    lda sorted,y
    cmp g_user
    bne :+
    lda #($20 | (1<<2))
    sta tmp
    bra @c
:   cpy #4
    bcs :+
    lda div
    beq @c
    lda #($20 | (2<<2))
    sta tmp
    bra @c
:   cpy #12
    bcc @c
    lda div
    cmp #3
    beq @c
    lda #($20 | (3<<2))
    sta tmp
@c: lda tmp
    sta txt_attr
    tya
    inc a
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    ply
    phy
    lda sorted,y
    jsr TableCrest
    ply
    phy
    lda sorted,y
    sta tmp5
    jsr PrintTeam
    lda tmp5
    A16
    and #$00FF
    sta tmp5
    A8
    ldx tmp5
    lda f:T_PTS,x
    ldy #3
    jsr PrintN8
    ldx tmp5
    lda f:T_J,x
    ldy #3
    jsr PrintN8
    ldx tmp5
    lda f:T_V,x
    ldy #3
    jsr PrintN8
    ; saldo de gols
    ldx tmp5
    lda f:T_GP,x
    sec
    sbc f:T_GC,x
    A16
    and #$00FF
    cmp #$0080
    bcc :+
    ora #$FF00
:   sta num
    and #$8000
    beq :+
    lda #$FFFF
:   sta num+2
    A8
    lda #5
    sta num_w
    jsr PrintSigned
    ply
    iny
    cpy #16
    beq :+
    jmp @r
:   PRINT TXT_TAB_H, 1, 22, 4
    PRINT TXT_TAB_H2, 1, 25, 4
    rts

; ---------------------------------------------------------------- resultados
ResultsScreen:
    .a8
    .i16
    SCR 13
    lda g_user
    jsr TeamDiv
    sta div
    stz div+1
    jsr BeginScreen
    stz jg_modo
@redraw:
    jsr ClearBg3
    lda jg_modo
    beq :+
    lda #BG_MENU
    jsr LoadBg
    jsr CalendarDraw
    bra :++
:   jsr ResultsDraw
:   lda bright
    bpl :+
    jsr ShowScreen
:
@l: jsr NextFrame
    lda pad_new
    bit #KL_X
    beq :+
    lda jg_modo
    eor #1
    sta jg_modo
    SFX SFX_CURSOR
    bra @redraw
:   lda pad_new+1
    bit #KH_B
    bne @x
    bit #KH_LEFT
    beq :+
    lda div
    beq @l
    dec div
    bra @redraw
:   bit #KH_RIGHT
    beq @l
    lda div
    cmp #3
    bcs @l
    inc div
    bra @redraw
@x: rts

ResultsDraw:
    .a8
    .i16
    jsr CrestClear
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_RESULT_T, 1, 1, 1
    lda div
    clc
    adc #FONT_LA
    jsr PrintChar
    lda g_round
    bne :+
    PRINT TXT_SEM_JOGOS, 2, 4, 0
    jmp @art
:   ldx #.loword(TXT_ROD_CURTA)
    jsr PrintStr
    lda g_round
    ldy #2
    jsr PrintN8
    ldy #0
@m: phy
    lda g_round
    dec a
    jsr GetFixture
    ply
    phy
    tya
    clc
    adc #3
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
    lda #$20
    sta txt_attr
    lda fx_h
    cmp g_user
    beq :+
    lda fx_a
    cmp g_user
    bne :++
:   lda #($20 | (1<<2))
    sta txt_attr
:   lda fx_h
    jsr PrintTeam
    ; placar: RES[(div*8+i)*2]
    ply
    phy
    lda div
    asl a
    asl a
    asl a
    sta tmp
    tya
    clc
    adc tmp
    asl a
    A16
    and #$00FF
    sta tmp5
    tax
    A8
    lda f:RES,x
    ldy #2
    jsr PrintN8
    lda #FONT_X
    jsr PrintChar
    ldx tmp5
    lda f:RES+1,x
    ldy #1
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    lda fx_a
    jsr PrintTeam
    ply
    phy
    tya
    clc
    adc #3
    sta tmp6
    lda #17
    sta tmp4
    tya
    jsr RowCrests
    ply
    iny
    cpy #8
    beq @art
    jmp @m
@art:
    ; artilheiros da divisao
    PRINT TXT_ARTILHEIROS, 1, 12, 2
    jsr TopScorers
    ldy #0
@s: cpy cnt
    bcs @sx
    phy
    tya
    clc
    adc #13
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
    tya
    asl a
    tax
    lda lst,x
    sta pid
    A8
    lda #$20
    sta txt_attr
    ldx pid
    lda f:P_GOL,x
    ldy #2
    jsr PrintN8
    lda #FONT_SPACE
    jsr PrintChar
    ldx pid
    jsr PrintPName
    lda #FONT_SPACE
    jsr PrintChar
    ; time = pid / 26
    A16
    lda pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    jsr PrintTeam
    ply
    iny
    cpy #8
    bne @s
@sx:
    PRINT TXT_JG_H2, 1, 24, 4
    PRINT TXT_TAB_H2, 1, 25, 4
    rts

; os 8 maiores goleadores da divisao div -> lst / cnt
TopScorers:
    .a8
    .i16
    ldx #0
    stx cnt
@k: lda #0
    sta tmp3                ; melhor gols
    ldx #$FFFF
    stx tmp4                ; melhor pid
    ; percorre os 16 times
    lda div
    asl a
    asl a
    asl a
    asl a
    sta tmp6
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
    beq @n
    lda f:P_GOL,x
    beq @n
    cmp tmp3
    bcc @n
    beq @n
    ; ja escolhido?
    phy
    ldy #0
@c: cpy cnt
    bcs @new
    phy
    A16
    tya
    asl a
    tay
    txa
    cmp lst,y
    A8
    beq @dup1
    ply
    iny
    bra @c
@dup1:
    ply
    bra @dup
@new:
    ply
    lda f:P_GOL,x
    sta tmp3
    stx tmp4
    bra @n
@dup:
    ply
@n: inx
    dey
    bne @p
    ply
    iny
    cpy #16
    bne @t
    ldx tmp4
    cpx #$FFFF
    beq @fim
    A16
    lda cnt
    asl a
    tax
    lda tmp4
    sta lst,x
    inc cnt
    lda cnt
    cmp #8
    A8
    bcs @fim
    jmp @k
@fim:
    rts

; ---------------------------------------------------------------- mercado
MkScroll:
    .a8
    .i16
    SFX SFX_CURSOR
    lda sel
    cmp top
    bcs :+
    sta top
:   lda top
    clc
    adc #15
    cmp sel
    bcs :+
    lda sel
    sec
    sbc #15
    sta top
:   rts

MarketDraw:
    .a8
    .i16
    jsr ClearBg3
    lda #BG_MENU
    jsr LoadBg
    PRINT TXT_MERCADO_T, 1, 1, 1
    lda mk_pos
    A16
    and #$00FF
    asl a
    tax
    lda PosFilterTxt,x
    tax
    A8
    jsr PrintStr
    PRINT TXT_CAIXA, 1, 2, 0
    ldx #g_money
    ldy #7
    jsr PrintS32
    ldx #.loword(TXT_MIL)
    jsr PrintStr
    PRINT TXT_MK_COLS, 1, 4, 4
    lda cnt
    bne :+
    PRINT TXT_MK_VAZIO, 2, 6, 0
    jmp @h
:   ldy #0
@r: phy
    tya
    clc
    adc top
    cmp cnt
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
    asl a
    tax
    lda lst,x
    sta pid
    A8
    lda tmp6
    cmp sel
    bne :+
    lda #($20 | (1<<2))
    bra :++
:   lda #$20
:   sta txt_attr
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
    lda #FONT_SPACE
    jsr PrintChar
    ; sigla do time
    A16
    lda pid
    sta d_n
    stz d_n+2
    lda #SQ
    sta d_d
    A8
    jsr Div32
    lda d_q
    jsr PrintAbbr
    ldx pid
    jsr GetValue
    ldy #6
    jsr PrintN16
@skip:
    ply
    iny
    cpy #16
    beq @h
    jmp @r
@h: lda cnt
    bne :+
    jsr UiBarOff
    bra :++
:   lda sel
    sec
    sbc top
    clc
    adc #5
    jsr UiBarOn
:   PRINT TXT_MK_H, 1, 24, 4
    PRINT TXT_MK_H2, 1, 25, 4
    rts

PosFilterTxt: .word .loword(TXT_GOLEIROS), .loword(TXT_DEFENSORES), .loword(TXT_MEIAS), .loword(TXT_ATACANTES), .loword(TXT_TODOS)

