-- Robo que joga Super Tecnico 98 lendo a RAM (teste automatico no Mesen)
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/teste/"
dofile(dir .. "botcfg.lua")
local L = {}
for line in io.lines("C:/Users/ramon/Desktop/elifoot98/snes/gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local log = io.open(dir .. "bot.txt", "w")
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local function r16(n, i) return r8(n, i) + 256 * r8(n, (i or 0) + 1) end
local function rw(a) return emu.read(a, emu.memType.snesMemory) end
local NP = 1664
local DIVT = 0x7F0000 + 9 * NP
local function s32(n) local v = r16(n) + 65536 * r16(n, 2); if v >= 0x80000000 then v = v - 0x100000000 end return v end
visit_i = 1
VISITS = VISITLIST or {1, 2, 3, 4, 5, 7, 8}
-- menu do clube em grade: 0 no topo, 1..8 em duas colunas, 9 embaixo
function hubkey(sel, alvo)
  if sel == alvo then return nil end
  local function lin(i) if i == 0 then return -1 elseif i == 9 then return 4 else return (i - 1) // 2 end end
  if lin(sel) < lin(alvo) then return "down" elseif lin(sel) > lin(alvo) then return "up"
  elseif sel < alvo then return "right" else return "left" end
end
local f, last, since, shots, rounds, lastround = 0, -1, 0, {}, 0, -1
local function shot(tag)
  local fh = io.open(dir .. "fotos/" .. string.format("%05d_%s.png", f, tag), "wb")
  fh:write(emu.takeScreenshot()) fh:close()
end
local function team_line()
  local s = ""
  for d = 0, 3 do
    local best, bt = -1, 0
    for i = 0, 15 do local t = rw(DIVT + d * 16 + i); local p = rw(DIVT + 64 + t); if p > best then best, bt = p, t end end
    s = s .. string.format(" %s:%d(%d)", ("ABCD"):sub(d + 1, d + 1), bt, best)
  end
  return s
end
emu.addEventCallback(function()
  f = f + 1
  local sc = r8("scr")
  local inp = {}
  local tick = (f % 2 == 0)
  if sc ~= last then
    log:write(string.format("f=%d tela=%d data=%d rodada=%d temporada=%d time=%d caixa=%d conf=%d copa=%d/%d lag=%d\n", f, sc, r8("g_date"), r8("g_round"), r16("g_season"), r8("g_user"), s32("g_money"), r8("g_conf"), r8("cup_phase"), r8("cup_n"), r16("lag_count")))
    last = sc; since = 0
    if not shots[sc] or SHOTALL then shots[sc] = true; WANT = f + 40 end
  end
  since = since + 1
  if WANT and f == WANT then shot("tela" .. sc) WANT = nil end
  if since > 3000 then log:write("TRAVOU? tela=" .. sc .. "\n") shot("travou") log:close() emu.stop(1) return end
  if sc == 1 then
    if SAVETEST and saved then
      wentTitle = true
      if since > 60 and since < 70 then inp.start = true end
      if since > 100 and r8("sel") == 0 and f % 8 == 0 then inp.down = true end
      if since > 130 and r8("sel") == 1 and f % 16 == 0 then inp.a = true end
    elseif f % 20 == 0 and since > (TITLEWAIT or 0) then inp.start = true end
  elseif sc == 2 then if since == 40 then shot("slots") end
    if since > 50 and f % 16 == 0 then inp.a = true end
  elseif sc == 3 then if since < 100 then if f % 12 == 0 then inp.a = true elseif f % 12 == 6 then inp.right = true end elseif f % 16 == 0 then inp.start = true end
  elseif sc == 4 then
    if since > 60 and since < 60 + 6 * DIVSTEPS and since % 6 == 0 then inp.left = true end
    if since > 120 and f % 16 == 0 then inp.a = true end
  elseif sc == 5 then
    if r8("g_round") ~= lastround then lastround = r8("g_round"); rounds = rounds + 1 end
    if rounds > ROUNDS then log:write(string.format("fim do teste  media de gols %.2f em %d jogos\n", (gols or 0) / math.max(1, jogos or 0), jogos or 0) .. team_line() .. "\n") shot("final") log:close() emu.stop(0) return end
    if VISIT and since > 30 and since < 34 then shot("hub") end
    local alvo = 0
    if SAVETEST and rounds == 3 and not saved then alvo = 9 end
    if SAVETEST and saved and wentTitle and not loaded and since > 30 then
      loaded = true
      log:write(string.format("CARREGADO: rodada=%d caixa=%d time=%d temporada=%d (salvo: rodada=%d caixa=%d)\n", r8("g_round"), s32("g_money"), r8("g_user"), r16("g_season"), sv_round, sv_money))
      shot("carregado")
    end
    if VISIT and rounds == (VISITROUND or 2) and visit_i <= #VISITS then alvo = VISITS[visit_i] end
    local tecla = hubkey(r8("sel"), alvo)
    if tecla then if f % 8 == 0 then inp[tecla] = true end
    elseif f % 16 == 0 and since > 20 then inp.a = true
      if alvo == 9 then saved = true; sv_round = r8("g_round"); sv_money = s32("g_money") end
      if alvo > 0 and alvo < 9 then visit_i = visit_i + 1 end end
  elseif sc == 6 then inp.a = tick and (not SLOWMATCH or r8("m_minute") == 45 or r8("m_minute") == 90)
    if SUBTEST and rounds == 1 and r8("m_minute") == 50 and not subdone then inp.a = false; inp.start = true; subdone = true end
    if r8("m_minute") == 30 and not shots.mid then shots.mid = true; shot("jogo30") end
    if PAGETEST and r8("m_minute") == 90 and not pagedone then
      pg = (pg or 0) + 1; inp.a = false
      if pg == 10 then inp.l = true end
      if pg == 30 then shot("pagina_l") end
      if pg == 40 or pg == 50 then inp.r = true end
      if pg == 70 then shot("pagina_r") pagedone = true end
    end
  elseif sc == 7 then if f % 16 == 0 then inp.a = true end
    if since == 2 and r8("m_iscup") == 0 then
      for m = 0, 31 do gols = (gols or 0) + rw(DIVT + 512 + m * 2) + rw(DIVT + 513 + m * 2); jogos = (jogos or 0) + 1 end
    end
    if r8("g_round") % 10 == 0 and since == 30 then log:write(string.format("  rodada %d caixa %d negativo %d pos? %s\n", r8("g_round"), s32("g_money"), r8("g_negrnd"), team_line())) end
  elseif sc == 8 then if f % 16 == 0 then inp.a = true end
  elseif sc == 9 or sc == 10 then
    if SHOTSEASON and since == 60 then shot("temporada" .. sc) end
    if since > 70 and f % 16 == 0 then inp.a = true end
  elseif sc == 16 then
    if since == 30 then shot("subst") end
    if since == 40 then inp.a = true end
    if since == 60 then inp.a = true end
    if since == 80 then shot("subst2") end
    if since > 100 and f % 16 == 0 then inp.b = true end
  else
    if since == 50 then shot("tela" .. sc .. "_v") end
    if sc == 11 and since == 60 then inp.down = true end
    if sc == 11 and since == 70 then inp.a = true end
    if sc == 11 and since == 80 then shot("tela11_toggle") end
    if sc == 11 and since == 84 then inp.l = true end
    if sc == 11 and since == 96 then shot("tela11_tatica") end
    if sc == 13 and since == 60 then inp.x = true end
    if sc == 13 and since == 80 then shot("calendario") end
    if sc == 24 and since == 60 then shot("premios") end
    if sc == 23 and RESIGNTEST and since == 60 then inp.x = true end
    if sc == 23 and RESIGNTEST and since == 80 then shot("demissao") end
    if sc == 23 and RESIGNYES and since == 90 then inp.a = true end
    if sc == 14 and since == 60 then inp.right = true end
    if sc == 14 and since == 90 then shot("tela14_g") end
    if sc == 14 and since == 95 then inp.left = true end
    if sc == 14 and since == 110 then inp.down = true end
    if sc == 14 and since == 120 then inp.a = true end
    if sc == 14 and since == 140 then shot("compra") end
    if sc == 14 and since == 150 then inp.a = true end
    if sc == 14 and since == 175 then shot("comprou") log:write(string.format("caixa apos compra=%d\n", s32("g_money"))) end
    local lim = 100
    if since > lim and f % 16 == 0 then inp.b = true end
  end
  emu.setInput(inp, 0)
end, emu.eventType.inputPolled)
