; =====================================================================
;  Utilitarios: aritmetica, impressao de times/jogadores, valores
; =====================================================================

; m_r(32) = m_a(16) * m_b(16) sem sinal
Mul16:
    .a8
    .i16
    A16
    stz m_r
    stz m_r+2
    lda m_a
    sta mt_a
    stz mt_a+2
    lda m_b
    sta mt_b
@l: lda mt_b
    beq @d
    lsr mt_b
    bcc @s
    lda m_r
    clc
    adc mt_a
    sta m_r
    lda m_r+2
    adc mt_a+2
    sta m_r+2
@s: asl mt_a
    rol mt_a+2
    bra @l
@d: A8
    rts

; d_q(32) = d_n(32) / d_d(16), d_r = resto (sem sinal)
Div32:
    .a8
    .i16
    A16
    lda d_n
    sta d_q
    lda d_n+2
    sta d_q+2
    stz d_r
    ldx #32
@l: asl d_q
    rol d_q+2
    rol d_r
    bcs @sub                ; resto passou de 16 bits: sempre cabe
    lda d_r
    cmp d_d
    bcc @n
@sub:
    lda d_r
    sec
    sbc d_d
    sta d_r
    inc d_q
@n: dex
    bne @l
    A8
    rts

; A(16) = A(16) * B(8 em m_b) / 100  (porcentagem) - resultado 16 bits
Percent:
    .a8
    .i16
    A16
    sta m_a
    A8
    jsr Mul16
    A16
    lda m_r
    sta d_n
    lda m_r+2
    sta d_n+2
    lda #100
    sta d_d
    A8
    jsr Div32
    A16
    lda d_q
    A8
    rts

; ---------------------------------------------------------------- times
; A = time -> team, pbase
SetTeam:
    .a8
    .i16
    A16
    and #$00FF
    sta team
    asl a
    tax
    lda TeamBase,x
    sta pbase
    A8
    rts

; A = numero de jogadores do time (team/pbase)
TeamCount:
    .a8
    .i16
    ldx pbase
    ldy #SQ
    stz tmp
@l: lda f:P_STR,x
    beq :+
    inc tmp
:   inx
    dey
    bne @l
    lda tmp
    rts

; A = time -> A = divisao (0..3), X = posicao em DIVT
TeamDiv:
    .a8
    .i16
    ldx #0
@l: cmp f:DIVT,x
    beq @f
    inx
    cpx #64
    bne @l
    ldx #0
@f: A16
    txa
    lsr a
    lsr a
    lsr a
    lsr a
    A8
    rts

; imprime nome do time A (12 letras)
PrintTeam:
    .a8
    .i16
    A16
    and #$00FF
    sta tmp
    asl a
    clc
    adc tmp                 ; *3
    asl a
    asl a                   ; *12
    clc
    adc #.loword(TeamName)
    sta txt_ptr
    A8
    lda #^TeamName
    sta txt_ptr+2
    ldy #12
    jmp PrintFixed

; imprime sigla do time A (3 letras)
PrintAbbr:
    .a8
    .i16
    A16
    and #$00FF
    sta tmp
    asl a
    clc
    adc tmp
    clc
    adc #.loword(TeamAbbr)
    sta txt_ptr
    A8
    lda #^TeamAbbr
    sta txt_ptr+2
    ldy #3
    jmp PrintFixed

; ---------------------------------------------------------------- jogadores
; imprime o nome (12 letras) do jogador X
PrintPName:
    .a8
    .i16
    lda f:P_NMH,x
    xba
    lda f:P_NML,x
    A16
    sta tmp
    asl a
    clc
    adc tmp
    asl a
    asl a
    clc
    adc #.loword(NameTab)
    sta txt_ptr
    A8
    lda #^NameTab
    sta txt_ptr+2
    ldy #12
    jmp PrintFixed

; imprime a letra da posicao do jogador X
PrintPos:
    .a8
    .i16
    lda f:P_POS,x
    and #$03
    A16
    and #$00FF
    tax
    A8
    lda PosChar,x
    jmp PrintChar

; imprime numero 8 bits A com largura Y
PrintN8:
    .a8
    .i16
    sty num_w
    A16
    and #$00FF
    sta num
    stz num+2
    A8
    jmp PrintNum

; imprime numero 16 bits A com largura Y
PrintN16:
    .a8
    .i16
    sty num_w
    A16
    sta num
    stz num+2
    A8
    jmp PrintNum

; imprime numero 32 bits com sinal em [X] (ponteiro baixo) com largura Y
PrintS32:
    .a8
    .i16
    sty num_w
    A16
    lda $0000,x
    sta num
    lda $0002,x
    sta num+2
    A8
    jmp PrintSigned

; A(16) = valor de mercado (R$ mil) do jogador X
GetValue:
    .a8
    .i16
    phx
    lda f:P_STR,x
    A16
    and #$00FF
    asl a
    tay
    lda ValueTab,y
    sta tmp
    A8
    lda f:P_AGE,x
    cmp #22
    bcc @young
    cmp #30
    bcc @prime
    cmp #33
    bcc @vet
    A16
    lda tmp
    lsr a
    lsr a
    bra @done
@vet:
    A16
    lda tmp
    lsr a
    sta tmp2
    lsr a
    lsr a
    clc
    adc tmp2
    bra @done
@young:
    A16
    lda tmp
    lsr a
    clc
    adc tmp
    bra @done
@prime:
    A16
    lda tmp
@done:
    bne :+
    lda #1
:   A8
    plx
    rts

; A(16) = salario por rodada (R$ mil) do jogador X
GetSalary:
    .a8
    .i16
    lda f:P_STR,x
    A16
    and #$00FF
    asl a
    tay
    lda SalTab,y
    A8
    rts

; A(16) = soma dos salarios do time (team/pbase)
TeamSalaries:
    .a8
    .i16
    A16
    stz tmp4
    A8
    ldx pbase
    ldy #SQ
@l: phy
    jsr GetSalary
    A16
    clc
    adc tmp4
    sta tmp4
    A8
    ply
    inx
    dey
    bne @l
    A16
    lda tmp4
    A8
    rts

; g_money += A(16) com sinal estendido (A = valor positivo, carry de A16)
MoneyAdd:
    .a8
    .i16
    A16
    clc
    adc g_money
    sta g_money
    lda g_money+2
    adc #0
    sta g_money+2
    A8
    rts
MoneySub:
    .a8
    .i16
    A16
    sta tmp
    lda g_money
    sec
    sbc tmp
    sta g_money
    lda g_money+2
    sbc #0
    sta g_money+2
    A8
    rts

; carry = 1 se g_money >= A(16)
MoneyHas:
    .a8
    .i16
    A16
    sta tmp
    lda g_money+2
    bmi @no
    bne @yes
    lda g_money
    cmp tmp
    bcc @no
@yes:
    A8
    sec
    rts
@no:
    A8
    clc
    rts

; espera A ou B (A = 1 se A/START, 0 se B)
WaitAB:
    .a8
    .i16
@l: jsr NextFrame
    lda pad_new
    bit #KL_A
    bne @a
    lda pad_new+1
    bit #KH_START
    bne @a
    bit #KH_B
    beq @l
    lda #0
    rts
@a: lda #1
    rts
