-- mede o andamento da musica (eventos da bateria por 100 quadros) no menu e na escalacao com o direcional apertado
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/"
local L = {}
for line in io.lines(dir .. "gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local log = io.open(dir .. "teste/ritmo.txt", "w")
local f, fase, cont, ini, ultimo = 0, 0, 0, 0, -1
emu.addEventCallback(function()
  f = f + 1
  local sc = r8("scr")
  local inp = {}
  -- conta mudancas no ponteiro do canal 6 (bateria)
  local p = r8("ch_ptr", 12) + 256 * r8("ch_ptr", 13)
  if p ~= ultimo then cont = cont + 1; ultimo = p end
  if sc == 1 then if f % 20 == 0 then inp.start = true end
  elseif sc == 2 or sc == 4 then if f % 16 == 0 then inp.a = true end
  elseif sc == 3 then if f % 16 == 0 then inp.start = true end
  elseif sc == 5 then
    if fase == 0 then fase = 1; ini = f; cont = 0 end
    if fase == 1 and f - ini == 300 then log:write(string.format("menu do clube: %d eventos em 300 quadros\n", cont)); fase = 2 end
    if fase == 2 then if r8("sel") < 1 then if f % 8 == 0 then inp.down = true end elseif f % 16 == 0 then inp.a = true end end
  elseif sc == 11 then
    if fase == 2 then fase = 3; ini = f; cont = 0 end
    if fase == 3 then
      if f % 6 == 0 then if (f // 60) % 2 == 0 then inp.down = true else inp.up = true end end
      if f - ini == 300 then log:write(string.format("escalacao com o direcional: %d eventos em 300 quadros, atrasos %d\n", cont, r8("lag_count"))) log:close() emu.stop(0) end
    end
  end
  emu.setInput(inp, 0)
end, emu.eventType.inputPolled)
