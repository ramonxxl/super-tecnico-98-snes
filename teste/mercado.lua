local dir = "C:/Users/ramon/Desktop/elifoot98/snes/teste/"
local L = {}
for line in io.lines(dir .. "../gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local function r16(n) return r8(n) + 256 * r8(n, 1) end
local function s32(n) local v = r16(n) + 65536 * (r8(n,2) + 256*r8(n,3)); if v >= 0x80000000 then v = v - 0x100000000 end return v end
local log = io.open(dir .. "mercado.txt", "w")
local f, last, since, passo = 0, -1, 0, 0
local function shot(t) local fh = io.open(dir .. "fotos/m_" .. string.format("%05d_", f) .. t .. ".png", "wb") fh:write(emu.takeScreenshot()) fh:close() end
emu.addEventCallback(function()
  f = f + 1
  local sc = r8("scr")
  if sc ~= last then log:write(string.format("f=%d tela=%d caixa=%d\n", f, sc, s32("g_money"))) last = sc since = 0 end
  since = since + 1
  local i = {}
  if sc == 1 then if f % 20 == 0 then i.start = true end
  elseif sc == 2 then if since > 30 and f % 16 == 0 then i.a = true end
  elseif sc == 3 then if since > 20 and f % 16 == 0 then i.start = true end
  elseif sc == 4 then
    if since == 60 or since == 70 or since == 80 then i.left = true end
    if since == 120 then i.a = true end
  elseif sc == 5 then
    if since == 60 then shot("hub") end
    if since > 60 and r8("sel") ~= 6 and f % 8 == 0 then
      local sl = r8("sel")
      if sl == 0 or sl == 1 or sl == 3 then i.down = true else i.right = true end
    end
    if since > 100 and r8("sel") == 6 and f % 16 == 0 then i.a = true end
  elseif sc == 14 then
    if since == 30 then shot("menu") end
    if passo == 0 and since == 40 then i.a = true passo = 1 end
    if passo == 2 and since == 40 then i.down = true end
    if passo == 2 and since == 50 then i.a = true passo = 3 end
    if passo == 4 and since == 40 then i.b = true end
  elseif sc == 17 then
    if since == 30 then shot("lista") end
    if passo == 1 and since == 40 then i.a = true end
    if passo == 2 and since == 30 then shot("lista_depois") end
    if passo == 2 and since == 40 then i.b = true end
  elseif sc == 20 then
    if since == 30 then shot("negocia") end
    if passo == 1 then
      if since == 40 then i.a = true end
      if since == 60 then shot("compra_lista") log:write(string.format("comprou da lista, caixa=%d\n", s32("g_money"))) end
      if since == 70 then i.a = true passo = 2 end
    elseif passo == 3 then
      if since == 40 then i.a = true end
      if since == 55 then shot("oferta_valor") end
      if since == 60 then i.up = true end
      if since == 70 then i.up = true end
      if since == 80 then i.a = true end
      if since == 95 then shot("contra") end
      if since == 100 then i.a = true end
      if since == 120 then shot("aceita") log:write(string.format("comprou do clube, caixa=%d\n", s32("g_money"))) end
      if since == 130 then i.a = true passo = 4 end
    end
  elseif sc == 18 then
    if since == 30 then shot("clubes") end
    if since == 40 then i.down = true end
    if since == 50 then i.a = true end
    if passo == 4 and since == 60 then i.b = true end
  elseif sc == 19 then
    if since == 30 then shot("elenco") end
    if passo == 3 and since == 40 then i.a = true end
    if passo == 4 and since == 40 then shot("elenco_depois") end
    if passo == 4 and since == 50 then i.b = true end
  end
  if passo == 4 and sc == 5 and since > 40 then log:close() emu.stop(0) end
  if f > 6000 then log:write("tempo esgotado\n") log:close() emu.stop(1) end
  emu.setInput(i, 0)
end, emu.eventType.inputPolled)
