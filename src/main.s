; =====================================================================
;  SUPER TECNICO 98  -  gerenciador de futebol para Super Nintendo
;  (homenagem ao Elifoot 98)
;  Montador: ca65 (cc65).  Mapa: LoROM, 256 KB, 64 KB de SRAM
;  Convencao: A 8 bits / X,Y 16 bits, DBR = $80, D = $0000
;  Dados do mundo (jogadores e times) ficam na WRAM $7F0000 (acesso longo)
; =====================================================================
.p816
.smart -

; ---------------------------------------------------------------- registradores
INIDISP  = $2100
OBSEL    = $2101
OAMADDL  = $2102
BGMODE   = $2105
BG1SC    = $2107
BG3SC    = $2109
BG12NBA  = $210B
BG34NBA  = $210C
BG1HOFS  = $210D
BG1VOFS  = $210E
BG3HOFS  = $2111
BG3VOFS  = $2112
VMAIN    = $2115
VMADDL   = $2116
CGADD    = $2121
TM       = $212C
APUIO0   = $2140
APUIO1   = $2141
APUIO2   = $2142
APUIO3   = $2143
NMITIMEN = $4200
WRMPYA   = $4202
WRMPYB   = $4203
WRDIVL   = $4204
WRDIVB   = $4206
MDMAEN   = $420B
MEMSEL   = $420D
RDNMI    = $4210
HVBJOY   = $4212
RDDIVL   = $4214
RDMPYL   = $4216
JOY1L    = $4218

; VRAM (enderecos em palavras)
VRAM_BG1TILES = $0000
VRAM_BG3TILES = $4000
VRAM_BG1MAP   = $5000
VRAM_BG3MAP   = $5400
VRAM_OBJ      = $6000

; botoes (byte alto de pad)
KH_B     = $80
KH_Y     = $40
KH_SEL   = $20
KH_START = $10
KH_UP    = $08
KH_DOWN  = $04
KH_LEFT  = $02
KH_RIGHT = $01
; botoes (byte baixo)
KL_A     = $80
KL_X     = $40
KL_L     = $20
KL_R     = $10

.include "src/macros.inc"
.include "gen/assets.inc"
.include "src/vars.inc"

; =====================================================================
.segment "CODE"

EmptyHandler:
    rti

ResetHandler:
    sei
    clc
    xce
    jml FastReset
FastReset:
    rep #$38
    .a16
    .i16
    ldx #$1FFF
    txs
    lda #$0000
    tcd
    A8
    lda #$80
    pha
    plb
    stz MEMSEL
    lda #$8F
    sta INIDISP
    stz NMITIMEN
    ; zera a RAM baixa ($0000-$1EFF)
    ldx #0
@clr:
    stz $0000,x
    inx
    cpx #$1F00
    bne @clr
    jsr InitHardware
    jsr ClearVram
    jsr ApuUpload
    jsr AudioInit
    lda #1
    sta aud_on
    A16
    lda #$ACE1
    sta rng
    A8
    lda #$FF
    sta cur_song
    jsr LoadMusicOpt
    ; graficos permanentes: fonte
    lda #$80
    sta VMAIN
    VRAM_LOAD FontTiles, VRAM_BG3TILES, (FontTiles_end - FontTiles)
    VRAM_LOAD ShieldTiles, VRAM_OBJ, 2048
    VRAM_LOAD IconTiles, (VRAM_OBJ + $400), 2048
    VRAM_LOAD CrestTiles, (VRAM_OBJ + $800), 224
    VRAM_LOAD UiTiles, $3C00, (UiTiles_end - UiTiles)
    ; registradores de video
    lda #$09                ; modo 1, BG3 com prioridade alta
    sta BGMODE
    lda #(VRAM_BG1MAP >> 8)
    sta BG1SC
    lda #(VRAM_BG3MAP >> 8)
    sta BG3SC
    lda #(VRAM_BG1TILES >> 12)
    sta BG12NBA
    lda #(VRAM_BG3TILES >> 12)
    sta BG34NBA
    lda #(VRAM_OBJ >> 13)
    sta OBSEL
    lda #$03                ; BG1 4 px acima do texto (botoes centrados na linha)
    sta BG1VOFS
    stz BG1VOFS
    lda #$FF
    sta BG3VOFS
    lda #$03
    sta BG3VOFS
    lda #$15                ; BG1 + BG3 + sprites
    sta TM
    jsr OamClear
    jsr ClearBg3
    jsr LoadBasePalettes
    stz bright
    lda #$81                ; NMI + leitura automatica do controle
    sta NMITIMEN
    jmp GameMain

; ---------------------------------------------------------------- NMI
NmiHandler:
    jml NmiFast
NmiFast:
    rep #$30
    .a16
    .i16
    pha
    phx
    phy
    phb
    phd
    lda #$0000
    tcd
    A8
    lda #$80
    pha
    plb
    lda RDNMI
    lda nmi_ready
    bne :+
    jmp @late
:   ; OAM
    ldx #0
    stx OAMADDL
    stz $4300
    lda #$04
    sta $4301
    ldx #.loword(oam_buf)
    stx $4302
    lda #$80
    sta $4304
    ldx #544
    stx $4305
    lda #$01
    sta MDMAEN
    ; mapa BG3
    lda bg3_dirty
    beq @nobg3
    stz bg3_dirty
    lda #$80
    sta VMAIN
    ldx #VRAM_BG3MAP
    stx VMADDL
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    ldx #.loword(bg3_buf)
    stx $4302
    lda #$80
    sta $4304
    ldx #2048
    stx $4305
    lda #$01
    sta MDMAEN
@nobg3:
    ; mapa BG1 (botoes e faixa de selecao)
    lda bg1_dirty
    beq @nobg1
    stz bg1_dirty
    lda #$80
    sta VMAIN
    ldx #VRAM_BG1MAP
    stx VMADDL
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    ldx #$2000
    stx $4302
    lda #$7E
    sta $4304
    ldx #2048
    stx $4305
    lda #$01
    sta MDMAEN
@nobg1:
    lda pal_dirty
    beq @nopal
    stz pal_dirty
    stz CGADD
    stz $4300
    lda #$22
    sta $4301
    ldx #.loword(cgram_buf)
    stx $4302
    lda #$80
    sta $4304
    ldx #512
    stx $4305
    lda #$01
    sta MDMAEN
@nopal:
    stz nmi_ready
    bra @upd
@late:
    A16
    inc lag_count
    A8
@upd:
    lda bright
    sta INIDISP
    ; musica e efeitos: um passo por quadro, aqui no vblank
    lda aud_on
    beq @na
    lda aud_lock
    bne @na
    jsr AudioUpdate
@na:
    A16
    inc frame
    rep #$30
    pld
    plb
    ply
    plx
    pla
    rti

; ---------------------------------------------------------------- hardware
InitHardware:
    .a8
    .i16
    ldx #$2101
@a: stz $0000,x
    inx
    cpx #$210D
    bne @a
@b: stz $0000,x
    stz $0000,x
    inx
    cpx #$2115
    bne @b
    lda #$80
    sta VMAIN
    stz $2116
    stz $2117
    stz $211A
    stz $211B
    lda #$01
    sta $211B
    stz $211C
    stz $211C
    stz $211D
    stz $211D
    stz $211E
    sta $211E
    stz $211F
    stz $211F
    stz $2120
    stz $2120
    ldx #$2121
@c: stz $0000,x
    inx
    cpx #$2134
    bne @c
    lda #$30
    sta $2130
    lda #$E0
    sta $2132
    lda #$FF
    sta $4201
    ldx #$4202
@d: stz $0000,x
    inx
    cpx #$420D
    bne @d
    rts

ClearVram:
    .a8
    .i16
    lda #$80
    sta VMAIN
    ldx #0
    stx VMADDL
    lda #$09
    sta $4300
    lda #$18
    sta $4301
    ldx #.loword(ZeroWord)
    stx $4302
    lda #^ZeroWord
    sta $4304
    ldx #0
    stx $4305
    lda #$01
    sta MDMAEN
    rts

; DMA: dma_src -> VRAM (endereco ja definido em VMADDL)
DmaVram:
    .a8
    .i16
    lda #$01
    sta $4300
    lda #$18
    sta $4301
    ldx dma_src
    stx $4302
    lda dma_src+2
    sta $4304
    ldx dma_len
    stx $4305
    lda #$01
    sta MDMAEN
    rts

; copia Y bytes de [dma_src] para cgram_buf+X
CopyPal:
    .a8
    .i16
    sty tmp
    ldy #0
@l: lda [dma_src],y
    sta cgram_buf,x
    inx
    iny
    cpy tmp
    bne @l
    lda #1
    sta pal_dirty
    rts

; espera o proximo quadro (o NMI envia os buffers)
WaitFrame:
    .a8
    .i16
    lda #1
    sta nmi_ready
@w: lda nmi_ready
    bne @w
    rts

; le o controle; pad_new recebe repeticao automatica nas setas
ReadPad:
    .a8
    .i16
@w: lda HVBJOY
    and #$01
    bne @w
    A16
    lda JOY1L
    sta pad
    lda pad_old
    eor #$FFFF
    and pad
    sta pad_new
    lda pad
    sta pad_old
    ; repeticao: setas seguradas por 16 quadros repetem a cada 4
    and #$0F00
    beq @norep
    lda pad_new
    bne @rst
    A8
    inc rep_cnt
    lda rep_cnt
    cmp #16
    bcc @done8
    lda #12
    sta rep_cnt
    A16
    lda pad
    and #$0F00
    ora pad_new
    sta pad_new
    A8
    rts
@norep:
    .a16
    A8
    stz rep_cnt
    rts
@rst:
    A8
    stz rep_cnt
@done8:
    rts

; um quadro: musica, espera o vblank e le o controle
NextFrame:
    .a8
    .i16
    jsr Rand                ; a sorte depende do tempo que o jogador leva
    jsr UiPulse
    jsr WaitFrame
    jmp ReadPad

FadeIn:
    .a8
    .i16
    stz bright
@l: jsr WaitFrame
    lda bright
    inc a
    inc a
    inc a
    cmp #$0F
    bcc :+
    lda #$0F
:   sta bright
    cmp #$0F
    bne @l
    jmp ReadPad
FadeOut:
    .a8
    .i16
    lda bright
    and #$0F
    sta bright
@l: jsr WaitFrame
    lda bright
    beq @done
    sec
    sbc #3
    bcs :+
    lda #0
:   sta bright
    bra @l
@done:
    rts

; espera A quadros
Delay:
    .a8
    .i16
    sta tmp4
@l: jsr NextFrame
    dec tmp4
    bne @l
    rts

; ---------------------------------------------------------------- aleatorio
Rand:
    .a8
    .i16
    A16
    lda rng
    lsr a
    bcc :+
    eor #$B400
:   sta rng
    A8
    rts
; A = n (1..255) -> A = 0..n-1
RandBelow:
    .a8
    .i16
    pha
    jsr Rand
    jsr Rand
    sta WRMPYA
    pla
    sta WRMPYB
    nop
    nop
    nop
    nop
    lda RDMPYL+1
    rts
; A(16) = 0..4095
Rand4096:
    .a8
    .i16
    jsr Rand
    A16
    lda rng
    and #$0FFF
    A8
    rts

; ---------------------------------------------------------------- texto (BG3)
ClearBg3:
    .a8
    .i16
    ldx #0
@l: stz bg3_buf,x
    inx
    cpx #2048
    bne @l
    lda #1
    sta bg3_dirty
    rts

; apaga a linha A (0..31) da camada de texto
ClearRow:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    ldy #32
@l: stz bg3_buf,x
    stz bg3_buf+1,x
    inx
    inx
    dey
    bne @l
    lda #1
    sta bg3_dirty
    rts

; X = endereco do texto (banco 0); txt_pos = linha*32+coluna; txt_attr
PrintStr:
    .a8
    .i16
    lda #^TextBank          ; os textos do jogo ficam num banco proprio
; X = endereco, A = banco
PrintStrB:
    .a8
    .i16
    sta txt_ptr+2
    stx txt_ptr
    lda txt_attr
    sta txt_attr0
    A16
    lda txt_pos
    asl a
    tax
    sta tmp2
    A8
    ldy #0
@lp:
    lda [txt_ptr],y
    cmp #$F0
    bcc @ch
    cmp #$FF
    beq @done
    cmp #$FE
    beq @nl
    cmp #$F8
    beq @rest
    ; F0..F7: muda a cor do texto
    and #$07
    asl a
    asl a
    ora #$20
    sta txt_attr
    iny
    bra @lp
@rest:
    lda txt_attr0
    sta txt_attr
    iny
    bra @lp
@nl:
    A16
    lda tmp2
    clc
    adc #64
    sta tmp2
    tax
    A8
    iny
    bra @lp
@ch:
    sta bg3_buf,x
    lda txt_attr
    sta bg3_buf+1,x
    inx
    inx
    iny
    bra @lp
@done:
    lda txt_attr0
    sta txt_attr
    A16
    txa
    lsr a
    sta txt_pos
    A8
    lda #1
    sta bg3_dirty
    rts

; imprime Y caracteres de [txt_ptr] em txt_pos (avanca txt_pos)
PrintFixed:
    .a8
    .i16
    sty tmp3
    A16
    lda txt_pos
    asl a
    tax
    A8
    ldy #0
@l: lda [txt_ptr],y
    sta bg3_buf,x
    lda txt_attr
    sta bg3_buf+1,x
    inx
    inx
    iny
    cpy tmp3
    bne @l
    A16
    txa
    lsr a
    sta txt_pos
    A8
    lda #1
    sta bg3_dirty
    rts

; imprime o caractere A em txt_pos (avanca)
PrintChar:
    .a8
    .i16
    pha
    A16
    lda txt_pos
    asl a
    tax
    inc txt_pos
    A8
    pla
    sta bg3_buf,x
    pha
    lda txt_attr
    sta bg3_buf+1,x
    lda #1
    sta bg3_dirty
    pla
    rts

; imprime A espacos
PrintSpaces:
    .a8
    .i16
    sta tmp4
@l: lda tmp4
    beq @d
    lda #FONT_SPACE
    jsr PrintChar
    dec tmp4
    bra @l
@d: rts

; muda a paleta de toda a linha A (txt_attr)
RowAttr:
    .a8
    .i16
    A16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    tax
    A8
    ldy #32
@l: lda txt_attr
    sta bg3_buf+1,x
    inx
    inx
    dey
    bne @l
    lda #1
    sta bg3_dirty
    rts

; num (32 bits) -> numdig[8]
NumConv:
    .a8
    .i16
    ldx #0
    ldy #0
@digit:
    lda #0
    sta numdig,y
    A16
@sub:
    lda num
    sec
    sbc Pow10,x
    sta tmp
    lda num+2
    sbc Pow10+2,x
    bcc @next
    sta num+2
    lda tmp
    sta num
    A8
    lda numdig,y
    inc a
    sta numdig,y
    A16
    bra @sub
@next:
    A8
    inx
    inx
    inx
    inx
    iny
    cpy #8
    bne @digit
    rts

; imprime num (sem sinal) com largura num_w (espacos a esquerda)
PrintNum:
    .a8
    .i16
    jsr NumConv
    A16
    lda num_w
    and #$00FF
    sta tmp3
    lda #8
    sec
    sbc tmp3
    tax
    A8
    ldy #0
    stz tmp3
@lp:
    lda numdig,x
    bne @nz
    lda tmp3
    bne @dig
    cpx #7
    beq @dig
    lda #FONT_SPACE
    bra @put
@nz:
    inc tmp3
@dig:
    lda numdig,x
    clc
    adc #FONT_0
@put:
    sta numstr,y
    iny
    inx
    cpx #8
    bne @lp
    lda #$FF
    sta numstr,y
    ldx #numstr
    lda #0                  ; numero montado na RAM
    jmp PrintStrB

; imprime num (32 bits COM sinal) com largura num_w (sinal de - colado)
PrintSigned:
    .a8
    .i16
    lda num+3
    bpl PrintNum
    A16
    lda num
    eor #$FFFF
    clc
    adc #1
    sta num
    lda num+2
    eor #$FFFF
    adc #0
    sta num+2
    A8
    jsr NumConv
    ; acha o primeiro digito nao zero e coloca o '-' antes
    A16
    lda num_w
    and #$00FF
    sta tmp3
    lda #8
    sec
    sbc tmp3
    tax
    A8
    ldy #0
    stz tmp3
@lp:
    lda tmp3
    bne @dig
    lda numdig,x
    bne @first
    cpx #7
    beq @first
    ; ainda zero a esquerda: se o proximo for o primeiro digito, poe '-'
    lda numdig+1,x
    bne @minus
    cpx #6
    beq @minus
    lda #FONT_SPACE
    bra @put
@minus:
    lda #FONT_MINUS
    bra @put
@first:
    inc tmp3
@dig:
    lda numdig,x
    clc
    adc #FONT_0
@put:
    sta numstr,y
    iny
    inx
    cpx #8
    bne @lp
    lda #$FF
    sta numstr,y
    ldx #numstr
    lda #0                  ; numero montado na RAM
    jmp PrintStrB

; ---------------------------------------------------------------- sprites
OamClear:
    .a8
    .i16
    ldx #0
    lda #$F0
@l: stz oam_buf,x
    sta oam_buf+1,x
    stz oam_buf+2,x
    stz oam_buf+3,x
    inx
    inx
    inx
    inx
    cpx #512
    bne @l
    ldx #0
@h: stz oam_buf+512,x
    inx
    cpx #32
    bne @h
    rts

; ---------------------------------------------------------------- paletas comuns
LoadBasePalettes:
    .a8
    .i16
    PAL_LOAD TextPal, 0, 64
    PAL_LOAD UiPal, 48, 160         ; estilos de botao: paletas 3..7 do BG1
    PAL_LOAD IconPal, 160, 128      ; icones: paletas 2..5 dos sprites
    rts

.include "src/audio.s"
.include "src/util.s"
.include "src/mundo.s"
.include "src/partida.s"
.include "src/ui.s"
.include "src/telas.s"
.include "src/menus.s"
.include "src/mercado.s"
.include "src/calendario.s"
.include "src/telas2.s"
.include "src/carreira.s"
.include "src/save.s"

; ---------------------------------------------------------------- dados
.segment "RODATA"
ZeroWord: .word 0
Pow10: .dword 10000000, 1000000, 100000, 10000, 1000, 100, 10, 1
.include "gen/data.inc"
.include "gen/icon_pal.inc"

.segment "BANK1"
FontTiles:  .incbin "gen/font.bin"
FontTiles_end:
TextPal:    .incbin "gen/text_pal.bin"
ShieldTiles: .incbin "gen/shield.bin"
IconTiles:  .incbin "gen/icon_tiles.bin"
IconPal:    .incbin "gen/icon_pal.bin"
CrestTiles: .incbin "gen/crest.bin"
UiTiles:    .incbin "gen/ui_tiles.bin"
UiTiles_end:
UiPal:      .incbin "gen/ui_pal.bin"
SpcBlob:    .incbin "gen/spc.bin"

.segment "BANK2"
NameTab:    .incbin "gen/nomes.bin"

.segment "BANK3"
.include "gen/clubes.inc"

.segment "BANK7"
MusBank:
.include "gen/musica.inc"

.segment "BANK6"
TextBank:
.include "gen/textos.inc"

.segment "BANK4"
TitleTiles: .incbin "gen/title_tiles.bin"
TitleTiles_end:
TitleMap:   .incbin "gen/title_map.bin"
TitlePal:   .incbin "gen/title_pal.bin"

.segment "BANK5"
MenuTiles:  .incbin "gen/menu_tiles.bin"
MenuTiles_end:
MenuMap:    .incbin "gen/menu_map.bin"
MenuPal:    .incbin "gen/menu_pal.bin"

; ---------------------------------------------------------------- cabecalho
.segment "HEADER"
    .byte "SUPER TECNICO 98     "
    .byte $20               ; LoROM
    .byte $02               ; ROM + RAM + bateria
    .byte $08               ; 256 KB
    .byte $06               ; 64 KB de SRAM
    .byte $01               ; America do Norte (NTSC)
    .byte $00
    .byte $00
    .word $FFFF
    .word $0000

.segment "VECTORS"
    .word 0, 0
    .word .loword(EmptyHandler)     ; COP
    .word .loword(EmptyHandler)     ; BRK
    .word .loword(EmptyHandler)     ; ABORT
    .word .loword(NmiHandler)       ; NMI
    .word 0
    .word .loword(EmptyHandler)     ; IRQ
    .word 0, 0
    .word .loword(EmptyHandler)     ; COP
    .word 0
    .word .loword(EmptyHandler)     ; ABORT
    .word .loword(EmptyHandler)     ; NMI
    .word .loword(ResetHandler)     ; RESET
    .word .loword(EmptyHandler)     ; IRQ/BRK
