; =====================================================================
;  Audio: envia o driver ao SPC700 e toca musicas/efeitos escrevendo
;  diretamente nos registradores do DSP (via driver "proxy").
;  Vozes 0,1,2,5,6,7 = musica (melodia, baixo, guitarra, cordas, bateria, pratos)
;  Vozes 3-4 = efeitos. Instrumentos sao amostras BRR geradas no build.
; =====================================================================

; envia o bloco SpcBlob para $0200 via IPL e executa
ApuUpload:
    .a8
    .i16
    ldx #$BBAA
@w1:
    cpx APUIO0
    bne @w1
    ldx #$0200
    stx APUIO2
    lda #$01
    sta APUIO1
    lda #$CC
    sta APUIO0
@w2:
    cmp APUIO0
    bne @w2
    ldx #0
@byte:
    lda f:SpcBlob,x
    sta APUIO1
    txa
    sta APUIO0
@w3:
    cmp APUIO0
    bne @w3
    inx
    cpx #SPC_SIZE
    bne @byte
    ldy #$0200
    sty APUIO2
    stz APUIO1
    txa
    inc a
    sta APUIO0
@w4:
    cmp APUIO0
    bne @w4
    sta apu_cnt
    rts

; X = (valor << 8) | registrador
DspWrite:
    .a8
    .i16
    stx APUIO1
    lda apu_cnt
    inc a
    sta apu_cnt
    sta APUIO0
@w: cmp APUIO0
    bne @w
    rts

.macro DSP reg, val
    ldx #(((val) << 8) | (reg))
    jsr DspWrite
.endmacro

AudioInit:
    .a8
    .i16
    DSP $6C, $20        ; FLG: eco desligado
    DSP $4C, $00        ; KON
    DSP $5C, $FF        ; KOF
    DSP $5C, $00
    DSP $0C, $60        ; volume mestre
    DSP $1C, $60
    DSP $2C, $00        ; volume do eco
    DSP $3C, $00
    DSP $2D, $00        ; PMON
    DSP $3D, $00        ; NON: sem ruido
    DSP $5D, $03        ; DIR = $0300
    DSP $6D, $D0        ; ESA = $D000 (buffer do eco)
    DSP $7D, $03        ; EDL = 48 ms
    DSP $0D, $30        ; feedback do eco
    DSP $4D, $25        ; eco na melodia (0), guitarra (2) e cordas (5)
    DSP $0F, $7F        ; filtro FIR
    DSP $1F, $00
    DSP $2F, $00
    DSP $3F, $00
    DSP $4F, $00
    DSP $5F, $00
    DSP $6F, $00
    DSP $7F, $00
    DSP $6C, $20
    ldx #0
@c: stz ch_on,x
    stz ch_tr,x
    inx
    cpx #8
    bne @c
    lda #3
    sta sfx_next
    rts

; canais da musica (= vozes)
MusChan: .byte 0, 1, 2, 5, 6, 7
MUS_VOICES = $E7
MUS_N = 6

; toca musica A (reinicia so se for diferente da atual)
; as rotinas chamadas pelo programa principal travam o tocador do NMI enquanto
; mexem nos canais e no DSP (evita duas escritas ao mesmo tempo no SPC)
PlaySong:
    .a8
    .i16
    inc aud_lock
    jsr PlaySongRaw
    dec aud_lock
    rts
StopMusic:
    .a8
    .i16
    inc aud_lock
    jsr StopMusicRaw
    dec aud_lock
    rts
PlaySfx:
    .a8
    .i16
    inc aud_lock
    jsr PlaySfxRaw
    dec aud_lock
    rts

PlaySongRaw:
    .a8
    .i16
    cmp cur_song
    bne :+
    rts
:   sta cur_song
    jsr MusicOff
    lda opt_music
    bne :+
    rts
:   ; liga o eco na primeira musica (o buffer ja foi limpo pelo tempo)
    lda echo_on
    bne :+
    lda #1
    sta echo_on
    DSP $6C, $00        ; FLG: escrita do eco ligada
    DSP $2C, $18        ; volume do eco
    DSP $3C, $18
:   ; tabela: 5 trilhas por musica
    lda cur_song
    A16
    and #$00FF
    asl a
    asl a
    sta tmp                 ; *4
    asl a
    clc
    adc tmp                 ; *12 bytes (6 trilhas)
    tay
    A8
    ldx #0
@l: phx
    lda MusChan,x
    A16
    and #$00FF
    tax
    asl a
    sta ch_x2
    A8
    lda #1
    sta ch_on,x
    stz ch_wait,x
    A16
    ldx ch_x2
    lda SongTable,y
    sta ch_ptr,x
    sta ch_loop,x
    A8
    iny
    iny
    plx
    inx
    cpx #MUS_N
    bne @l
    rts

; para os canais da musica
MusicOff:
    .a8
    .i16
    ldx #0
@l: phx
    lda MusChan,x
    A16
    and #$00FF
    tax
    A8
    stz ch_on,x
    plx
    inx
    cpx #MUS_N
    bne @l
    DSP $5C, MUS_VOICES
    rts

StopMusicRaw:
    .a8
    .i16
    jsr MusicOff
    lda #$FF
    sta cur_song
    rts

; efeito sonoro A (vozes 3-5 em rodizio)
PlaySfxRaw:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    tay
    lda sfx_next
    and #$00FF
    sta ch_x
    asl a
    tax
    lda SfxTable,y
    sta ch_ptr,x
    sta ch_loop,x
    A8
    ldx ch_x
    lda #1
    sta ch_on,x
    stz ch_wait,x
    lda sfx_next
    inc a
    cmp #5
    bcc :+
    lda #3
:   sta sfx_next
    rts

; chamada uma vez por quadro
AudioUpdate:
    .a8
    .i16
    stz kon_pend
    stz kof_pend
    ldx #0
@ch:
    lda ch_on,x
    beq @next
    lda ch_wait,x
    beq @read
    dec ch_wait,x
    bne @next
@read:
    phx
    jsr ChannelRead
    plx
@next:
    inx
    cpx #8
    bne @ch
    lda kof_pend
    xba
    lda #$5C
    tax
    jsr DspWrite
    lda kon_pend
    beq @nokon
    xba
    lda #$4C
    tax
    jsr DspWrite
@nokon:
    rts

; le eventos do canal X ate encontrar nota/pausa
; formato: nota(1..72)/0 pausa + duracao | F0 inst | F1 vol | F2 esq dir
;          FD ponto de repeticao | FE repete | FF fim
ChannelRead:
    .a8
    .i16
    stx ch_x
    A16
    txa
    asl a
    sta ch_x2
    tax
    lda ch_ptr,x
    sta mptr
    A8
    lda #^MusBank           ; as trilhas ficam num banco proprio
    sta mptr+2
    ldy #0
@cmd:
    lda [mptr],y
    iny
    cmp #$F0
    bcc @note
    beq @inst
    cmp #$F1
    beq @vol
    cmp #$F2
    beq @pan
    cmp #$FD
    beq @mark
    cmp #$FE
    beq @loop
    ; $FF = fim
    ldx ch_x
    stz ch_on,x
    lda VoiceBit,x
    tsb kof_pend
    rts
@mark:
    ; a repeticao volta para ca (a introducao toca uma vez so)
    A16
    tya
    clc
    adc mptr
    ldx ch_x2
    sta ch_loop,x
    A8
    bra @cmd
@loop:
    ldx ch_x2
    A16
    lda ch_loop,x
    sta mptr
    A8
    ldy #0
    bra @cmd
@inst:
    lda [mptr],y
    iny
    phy
    jsr SetInstrument
    ply
    bra @cmd
@vol:
    lda [mptr],y
    iny
    sta tmp_note
    sta tmp_note+1
    phy
    jsr SetVolume
    ply
    bra @cmd
@pan:
    lda [mptr],y
    iny
    sta tmp_note
    lda [mptr],y
    iny
    sta tmp_note+1
    phy
    jsr SetVolume
    ply
    bra @cmd
@note:
    sta tmp_note
    lda [mptr],y
    iny
    ldx ch_x
    sta ch_wait,x
    A16
    tya
    clc
    adc mptr
    ldx ch_x2
    sta ch_ptr,x
    A8
    lda tmp_note
    beq @rest
    jmp NoteOn
@rest:
    ldx ch_x
    lda VoiceBit,x
    tsb kof_pend
    rts

VoiceReg:
    .a8
    .i16
    lda ch_x
    asl a
    asl a
    asl a
    asl a
    sta tmp_vreg
    rts

; A = nota. Transposicao do instrumento: $80 = altura fixa 32 kHz, $81 = 16 kHz
NoteOn:
    .a8
    .i16
    ldx ch_x
    sta tmp_note
    lda ch_tr,x
    bpl @tr
    and #$01
    beq :+
    ldx #$0800
    bra @fix
:   ldx #$1000
@fix:
    stx tmp_pitch
    bra @set
@tr:
    clc
    adc tmp_note
    A16
    and #$00FF
    asl a
    tax
    lda PitchTable,x
    sta tmp_pitch
    A8
@set:
    jsr VoiceReg
    lda tmp_pitch
    xba
    lda tmp_vreg
    ora #$02
    tax
    jsr DspWrite
    lda tmp_pitch+1
    xba
    lda tmp_vreg
    ora #$03
    tax
    jsr DspWrite
    ldx ch_x
    lda VoiceBit,x
    tsb kon_pend
    trb kof_pend
    rts

; A = instrumento (4 bytes: amostra, ADSR1, ADSR2, transposicao)
SetInstrument:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    asl a
    tay
    A8
    jsr VoiceReg
    lda InstTable,y
    xba
    lda tmp_vreg
    ora #$04
    tax
    jsr DspWrite
    lda InstTable+1,y
    xba
    lda tmp_vreg
    ora #$05
    tax
    jsr DspWrite
    lda InstTable+2,y
    xba
    lda tmp_vreg
    ora #$06
    tax
    jsr DspWrite
    lda InstTable+3,y
    ldx ch_x
    sta ch_tr,x
    rts

; volume esquerdo tmp_note, direito tmp_note+1
SetVolume:
    .a8
    .i16
    jsr VoiceReg
    lda tmp_note
    xba
    lda tmp_vreg
    tax
    jsr DspWrite
    lda tmp_note+1
    xba
    lda tmp_vreg
    ora #$01
    tax
    jsr DspWrite
    rts

VoiceBit: .byte $01, $02, $04, $08, $10, $20, $40, $80

; liga/desliga a musica (guardado na SRAM)
ToggleMusic:
    .a8
    .i16
    lda opt_music
    eor #1
    sta opt_music
    sta f:$717FF1
    lda #'M'
    sta f:$717FF0
    lda opt_music
    beq :+
    lda #$FF
    sta cur_song
    lda #SONG_MENU
    jmp PlaySong
:   jmp StopMusic

; le a opcao de musica salva (padrao: ligada)
LoadMusicOpt:
    .a8
    .i16
    lda #1
    sta opt_music
    lda f:$717FF0
    cmp #'M'
    bne :+
    lda f:$717FF1
    and #1
    sta opt_music
:   rts
