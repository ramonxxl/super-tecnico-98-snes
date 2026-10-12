-- auditoria de enquadramento: enquanto um robo joga, confere o mapa de texto (bg3_buf) de cada tela
-- e aponta letras fora da area segura (colunas 1..30, linhas 1..26) ou linhas cheias demais
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/"
dofile(dir .. "teste/auditcfg.lua")
local L = {}
for line in io.lines(dir .. "gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local out = io.open(dir .. "teste/auditoria_" .. AUDIT_NOME .. ".txt", "w")
local visto, fotos, ef = {}, {}, 0
dofile(dir .. "teste/" .. AUDIT_SCRIPT)
emu.addEventCallback(function()
  ef = ef + 1
  if ef % 10 ~= 0 then return end
  if r8("bright") < 15 then return end
  local sc = r8("scr")
  if sc ~= ultima then ultima = sc; desde = 0 end
  desde = (desde or 0) + 1
  if desde < 5 then return end      -- a tela anterior ainda esta saindo
  for row = 0, 27 do
    for _, col in ipairs({0, 31}) do
      local t = r8("bg3_buf", (row * 32 + col) * 2)
      if t ~= AUDIT_VAZIO then
        local k = sc .. ":" .. row .. ":" .. col
        if not visto[k] then
          visto[k] = true
          out:write(string.format("tela %d linha %d coluna %d tile %d\n", sc, row, col, t)); out:flush()
          if not fotos[sc .. ":" .. row] then
            fotos[sc .. ":" .. row] = true
            local fh = io.open(dir .. "teste/fotos/audit_" .. AUDIT_NOME .. "_" .. sc .. "_" .. row .. ".png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
          end
        end
      end
    end
  end
  for _, row in ipairs({0, 27}) do
    for col = 0, 31 do
      local t = r8("bg3_buf", (row * 32 + col) * 2)
      if t ~= AUDIT_VAZIO then
        local k = sc .. ":L" .. row
        if not visto[k] then visto[k] = true; out:write(string.format("tela %d texto na linha %d\n", sc, row)); out:flush() end
      end
    end
  end
end, emu.eventType.endFrame)
