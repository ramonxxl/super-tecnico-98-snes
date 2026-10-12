-- tira as fotos do manual: roda o robo (bot.lua) e salva telas escolhidas
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/"
local L = {}
for line in io.lines(dir .. "gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n) return emu.read(L[n] & 0xFFFF, emu.memType.snesMemory) end
dofile(dir .. "teste/botcfg.lua")
local NOMES = FOTO_NOMES
local tirada, last, since = {}, -1, 0
dofile(dir .. "teste/bot.lua")
emu.addEventCallback(function()
  local sc = r8("scr")
  if sc ~= last then last = sc; since = 0 end
  since = since + 1
  local nome = NOMES[sc]
  if nome and not tirada[nome] and since == (FOTO_ESPERA[sc] or 45) and (FOTO_COND == nil or FOTO_COND(sc, r8)) then
    tirada[nome] = true
    local fh = io.open(dir .. "cartucho/fotos/foto_" .. nome .. ".png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
  end
end, emu.eventType.inputPolled)
