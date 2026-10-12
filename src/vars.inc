; ---------------------------------------------------------------- constantes do mundo
NT       = 64           ; times
SQ       = 26           ; vagas de elenco por time
NP       = NT*SQ        ; 1664 vagas de jogador
NM       = 32           ; jogos por rodada (4 divisoes x 8)
MIN_ELENCO = 16
MAX_ELENCO = 26

; WRAM $7F: bloco salvo (jogadores + tabela)
W        = $7F0000
P_POS    = W + 0*NP     ; bits0-1 posicao (0 G,1 D,2 M,3 A); bits4-5 amarelos; bit7 a venda
P_STR    = W + 1*NP     ; forca 1..50 (0 = vaga vazia)
P_AGE    = W + 2*NP
P_NML    = W + 3*NP     ; indice do nome (byte baixo)
P_NMH    = W + 4*NP
P_OUT    = W + 5*NP     ; bits0-3 jogos fora, bit6 novo nesta rodada, bit7 lesao
P_GOL    = W + 6*NP     ; gols na temporada
P_MOR    = W + 7*NP     ; moral 0..99 (50 = normal)
P_CON    = W + 8*NP     ; anos de contrato
DIVT     = W + 9*NP     ; 64: time em cada posicao (divisao*16 + i)
T_PTS    = DIVT + 64
T_J      = DIVT + 128
T_V      = DIVT + 192
T_E      = DIVT + 256
T_D      = DIVT + 320
T_GP     = DIVT + 384
T_GC     = DIVT + 448
RES      = DIVT + 512   ; 64: placares da ultima rodada (jogo*2: mandante, visitante)
T_CAP    = DIVT + 576   ; 64 palavras: capacidade do estadio
CUP_LIST = DIVT + 704   ; 64: times vivos na copa, em ordem de chave (jogo k = 2k x 2k+1)
CUP_G1   = DIVT + 768   ; 64: gols do jogo de ida (por time da chave)
CUP_RES  = DIVT + 832   ; 64: gols da ultima data da copa (por time da chave)
CUP_PEN  = DIVT + 896   ; 32: penaltis do jogo k (alto = 2k, baixo = 2k+1), 0 = sem
HIST     = DIVT + 928   ; 16 x 10: temporada(2) campeoes A-D(4) copa(1) time(1) serie(1) posicao(1)
NEWS     = DIVT + 1088  ; 4 x 6: jogador(2) comprador(1) vendedor(1) valor(2)
W_END    = DIVT + 1112
W_SIZE   = W_END - W
HIST_N   = 16
; WRAM $7F: area de trabalho (nao salva)
PLAY     = $7F8000      ; NP: 0 = fora, 1 = em campo, 2 = saiu, 3 = em campo com amarelo

; posicoes
POS_G = 0
POS_D = 1
POS_M = 2
POS_A = 3

; ---------------------------------------------------------------- variaveis
.segment "ZEROPAGE"
tmp:        .res 2
tmp2:       .res 2
tmp3:       .res 2
tmp4:       .res 2
tmp5:       .res 2
tmp6:       .res 2
dma_src:    .res 3
dma_len:    .res 2
frame:      .res 2
nmi_ready:  .res 1
bright:     .res 1
bg3_dirty:  .res 1
pal_dirty:  .res 1
pad:        .res 2
pad_old:    .res 2
pad_new:    .res 2
rep_cnt:    .res 1
rng:        .res 2
scr:        .res 1      ; tela atual (para testes automaticos)
txt_pos:    .res 2
txt_attr:   .res 1
txt_attr0:  .res 1
bg1_dirty:  .res 1
bg_map:     .res 3      ; mapa original do fundo atual (ROM)
ui_t:       .res 2
txt_ptr:    .res 3
num:        .res 4
num_w:      .res 2
mptr:       .res 3
ch_x:       .res 2
ch_x2:      .res 2
tmp_note:   .res 2
tmp_vreg:   .res 1
tmp_pitch:  .res 2
apu_cnt:    .res 1
kon_pend:   .res 1
kof_pend:   .res 1
cur_song:   .res 1
sfx_next:   .res 1
echo_on:    .res 1
opt_music:  .res 1
aud_on:     .res 1
aud_lock:   .res 1
crowd_v:    .res 1
crowd_on:   .res 1
crowd_t:    .res 1
menu_selok: .res 1
lag_count:  .res 2
lptr:       .res 3      ; ponteiro longo de uso geral
lptr2:      .res 3
; aritmetica
m_a:        .res 2
m_b:        .res 2
m_r:        .res 4
mt_a:       .res 4
mt_b:       .res 2
d_n:        .res 4
d_d:        .res 2
d_q:        .res 4
d_r:        .res 2
; listas / menus
sel:        .res 2
top:        .res 2
cnt:        .res 2
team:       .res 2      ; time em uso (16 bits, byte alto 0)
pid:        .res 2      ; jogador em uso (indice absoluto)
pbase:      .res 2      ; time*26
div:        .res 2
rt_atk:     .res 2
rt_mid:     .res 2
rt_def:     .res 2
rt_gk:      .res 2

.segment "BSS"
oam_buf:    .res 544
bg3_buf:    .res 2048
cgram_buf:  .res 512
numdig:     .res 8
numstr:     .res 12
ch_ptr:     .res 16
ch_loop:    .res 16
ch_wait:    .res 8
ch_on:      .res 8
ch_tr:      .res 8

; --- estado do jogo salvo (bloco G)
g_start:
g_season:   .res 2
g_round:    .res 1      ; 0..29 (30 = temporada encerrada)
g_user:     .res 1
g_coach:    .res 10
g_money:    .res 4      ; R$ mil, com sinal
g_style:    .res 1      ; 0 defensivo, 1 equilibrado, 2 ofensivo
g_lineup:   .res 16     ; vagas (0..25) - 11 titulares + 5 reservas, $FF = vazio
g_ticket:   .res 1      ; preco do ingresso (R$)
g_negrnd:   .res 1      ; rodadas seguidas com caixa negativo
g_att:      .res 2      ; publico do ultimo jogo em casa
g_f_tv:     .res 2      ; ultima rodada: cota de TV
g_f_bil:    .res 2      ;                bilheteria
g_f_sal:    .res 2      ;                salarios
g_f_trans:  .res 4      ; temporada: vendas - compras (com sinal)
g_titles:   .res 1      ; titulos conquistados
g_seasons:  .res 1      ; temporadas jogadas
g_prize:    .res 2      ; premio da ultima temporada
g_date:     .res 1      ; data do calendario 0..41 (42 = fim)
g_conf:     .res 1      ; confianca da diretoria 0..100
g_loan:     .res 2      ; emprestimo (R$ mil)
g_train:    .res 1      ; treino: 0 equilibrado, 1 ataque, 2 defesa, 3 fisico
cup_n:      .res 1      ; times vivos na copa
cup_phase:  .res 1      ; 0..5 (6 = encerrada)
cup_leg:    .res 1      ; 0 ida, 1 volta
cup_champ:  .res 1      ; campeao da copa ($FF = ainda nao)
g_cups:     .res 1      ; copas ganhas pelo usuario
hist_n:     .res 1      ; temporadas no historico
news_n:     .res 1      ; noticias (0..4)
g_juros:    .res 2      ; juros pagos na ultima data
g_cupprize: .res 2      ; premio da copa na ultima data
g_form:     .res 1      ; esquema tatico 0..5
g_goal:     .res 1      ; meta da diretoria (posicao final)
c_rep:      .res 1      ; reputacao do tecnico 0..100
c_j:        .res 2      ; carreira: jogos
c_v:        .res 2      ;           vitorias
c_e:        .res 2      ;           empates
c_d:        .res 2      ;           derrotas
c_up:       .res 1      ;           acessos
c_down:     .res 1      ;           rebaixamentos
c_fired:    .res 1      ;           demissoes
c_clubs:    .res 1      ;           clubes dirigidos
g_end:
G_SIZE = g_end - g_start

; --- partida (trabalho)
m_team:     .res 64     ; por lado (jogo*2 + 0 mandante / 1 visitante)
m_goal:     .res 64
m_subs:     .res 64
m_q:        .res 128    ; chance de gol por minuto (palavra)
m_atk:      .res 128
m_def:      .res 128
m_on:       .res 64*11  ; vagas em campo (0..25, $FF vazio)
m_minute:   .res 1
m_userm:    .res 2      ; lado do usuario (jogo*2+lado)
m_speed:    .res 1
m_evrow:    .res 1
m_ticks:    .res 1
m_side:     .res 2
m_halt:     .res 1

; --- listas
lst:        .res 128    ; ate 64 palavras (ids de jogador / times)
sorted:     .res 16     ; times da divisao ordenados
skey:       .res 32
picked:     .res 26
pick_need:  .res 4
new_name:   .res 10
slot_cur:   .res 1
slot_ok:    .res 3
offer_pid:  .res 2
offer_team: .res 1
offer_val:  .res 4
job_list:   .res 3
job_n:      .res 1
job_fired:  .res 1
yn_res:     .res 1
fin_tmp:    .res 4
season_msg: .res 1
pick_out:   .res 16
tcnt:       .res 64
srt_all:    .res 64
skey_hi:    .res 16
skey_lo:    .res 32
champ:      .res 4
u_pos:      .res 1      ; posicao final do usuario na temporada
u_div:      .res 1
cand:       .res 12
ev_type:    .res 1
ev_pid:     .res 2
ev_side:    .res 1
ev_pid2:    .res 2
pk_pos:     .res 1
cur_bg:     .res 1
arr_col:    .res 2
menu_n:     .res 1
menu_row0:  .res 1
menu_step:  .res 1
si_team:    .res 1
si_season:  .res 2
si_round:   .res 1
fx_r:       .res 1
fx_h:       .res 1
fx_a:       .res 1
sq_list:    .res 26
sq_n:       .res 1
mk_pos:     .res 1
gm_mode:    .res 1
dl_idx:     .res 2
mk_menu:    .res 1
ng_listed:  .res 1
ng_team:    .res 1
ng_tit:     .res 1
ng_val:     .res 2
ng_ask:     .res 2
ng_off:     .res 2
ng_step:    .res 2
cs_team:    .res 1
train_pid:  .res 2
train_n:    .res 1
ai_buy:     .res 1
ai_sell:    .res 1
ai_val:     .res 2
m_disp:     .res 1      ; primeiro jogo mostrado na tela da partida
m_iscup:    .res 1
u_gols:     .res 24     ; gols do jogo do usuario: minuto, jogador(2)
u_ngols:    .res 1
con_out:    .res 1
ev_team:    .res 1
shd_slot:   .res 1
bn_col:     .res 2
sq_rowpos:  .res 2
cs_cnt:     .res 1
ui_col:     .res 1
ui_row:     .res 1
ui_w:       .res 1
ui_h:       .res 1
ui_style:   .res 1
ui_hi:      .res 1
ui_tl:      .res 1
ui_tm:      .res 1
ui_n:       .res 1
bar_row:    .res 1
menu_kind:  .res 1      ; 0 = faixa na linha, 1 = botoes
bm_col:     .res 1
bm_w:       .res 1
bm_pri:     .res 1      ; item principal ($FF = nenhum)
bm_bad:     .res 1      ; item critico ($FF = nenhum)
hub_sel:    .res 1
ap_form:    .res 1
need_buf:   .res 16
m_shots:    .res 2      ; finalizacoes do jogo do usuario (mandante, visitante)
sel_n:      .res 1      ; convocados do usuario na ultima convocacao
cal_r:      .res 1
aw_pid:     .res 2
aw_prize:   .res 1
jg_modo:    .res 1
crest_n:    .res 1
sv_old:     .res 1      ; jogo salvo no formato anterior
