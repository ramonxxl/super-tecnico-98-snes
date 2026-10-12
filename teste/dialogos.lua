-- testa caixas de confirmacao e avisos: ampliar estadio (financas) e renovar contrato (escalacao)
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/"
local L = {}
for line in io.lines(dir .. "gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local function s32(n) local v = r8(n) + 256 * r8(n, 1) + 65536 * r8(n, 2) + 16777216 * r8(n, 3); if v >= 0x80000000 then v = v - 0x100000000 end return v end
local log = io.open(dir .. "teste/dialogos.txt", "w")
local f, last, since, passo = 0, -1, 0, 0
local function shot(t) local fh = io.open(dir .. "teste/fotos/d_" .. t .. ".png", "wb") fh:write(emu.takeScreenshot()) fh:close() end
local function hub(alvo)
  local sel = r8("sel")
  if sel == alvo then return "a" end
  local function lin(i) if i == 0 then return -1 elseif i == 9 then return 4 else return (i - 1) // 2 end end
  if lin(sel) < lin(alvo) then return "down" elseif lin(sel) > lin(alvo) then return "up" elseif sel < alvo then return "right" else return "left" end
end
emu.addEventCallback(function()
  f = f + 1
  local sc = r8("scr")
  if sc ~= last then last = sc since = 0 end
  since = since + 1
  local i = {}
  if sc == 1 then if f % 20 == 0 then i.start = true end
    if since == 15 and passo == 0 then end
  elseif sc == 2 then if since > 30 and f % 16 == 0 then i.a = true end
  elseif sc == 3 then if since > 20 and f % 16 == 0 then i.start = true end
  elseif sc == 4 then
    if since == 60 or since == 70 then i.left = true end
    if since == 90 then i.down = true end
    if since == 120 then i.a = true end
  elseif sc == 5 then
    if since == 50 and passo == 0 then shot("hub") end
    local alvo = (passo == 0) and 7 or ((passo == 1) and 1 or 9)
    if since > 60 and f % 10 == 0 then i[hub(alvo)] = true end
    if passo == 2 and since > 60 then log:close() emu.stop(0) end
  elseif sc == 15 then
    if since == 40 then i.down = true end
    if since == 50 then log:write("caixa antes " .. s32("g_money") .. "\n") i.a = true end
    if since == 70 then shot("confirma") end
    if since == 80 then i.a = true end
    if since == 100 then shot("aviso") log:write("caixa depois de ampliar " .. s32("g_money") .. "\n") end
    if since == 170 then i.down = true end
    if since == 180 then i.a = true end
    if since == 200 then shot("confirma_emprestimo") end
    if since == 210 then i.b = true end
    if since == 240 then log:write("caixa depois de cancelar emprestimo " .. s32("g_money") .. "\n") i.b = true passo = 1 end
  elseif sc == 11 then
    if since == 40 then i.r = true end
    if since == 60 then shot("renovar") end
    if since == 70 then i.a = true end
    if since == 90 then shot("renovar_aviso") log:write("caixa depois de renovar " .. s32("g_money") .. "\n") end
    if since == 170 then i.b = true passo = 2 end
  end
  if f > 5000 then log:write("tempo esgotado\n") log:close() emu.stop(1) end
  emu.setInput(i, 0)
end, emu.eventType.inputPolled)
