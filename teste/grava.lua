-- grava quadros (30 fps) enquanto um roteiro de robo joga. Indice: n tela minuto
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/"
dofile(dir .. "teste/gravacfg.lua")
local L = {}
for line in io.lines(dir .. "gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n) return emu.read(L[n] & 0xFFFF, emu.memType.snesMemory) end
local out = dir .. "trailer/quadros/" .. GRAVA_NOME .. "_"
local idx = io.open(dir .. "trailer/quadros/" .. GRAVA_NOME .. ".txt", "w")
local ef, n = 0, 0
dofile(dir .. "teste/" .. GRAVA_SCRIPT)
emu.addEventCallback(function()
  ef = ef + 1
  if ef % 2 ~= 0 then return end
  local sc = r8("scr")
  if GRAVA_TELAS[sc] then
    n = n + 1
    local fh = io.open(out .. string.format("%05d", n) .. ".png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
    idx:write(string.format("%d %d %d %d\n", n, sc, r8("m_minute"), r8("bright"))); idx:flush()
  end
end, emu.eventType.endFrame)
