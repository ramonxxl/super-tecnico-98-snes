-- carrega o jogo salvo do espaco 1 (formato anterior) e confere se a carreira e a meta foram criadas
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/teste/"
local L = {}
for line in io.lines("C:/Users/ramon/Desktop/elifoot98/snes/gen/labels.txt") do
  local a, n = string.match(line, "al (%x+) %.([%w_]+)")
  if a then L[n] = tonumber(a, 16) end
end
local log = io.open(dir .. "saveantigo.txt", "w")
local function r8(n, i) return emu.read((L[n] & 0xFFFF) + (i or 0), emu.memType.snesMemory) end
local f, last, since = 0, -1, 0
emu.addEventCallback(function()
  f = f + 1
  local sc = r8("scr")
  if sc ~= last then last = sc; since = 0 end
  since = since + 1
  local inp = {}
  if sc == 1 then
    if since > 150 and since < 160 then inp.start = true end
    if since > 200 and r8("sel") == 0 and f % 8 == 0 then inp.down = true end
    if since > 230 and r8("sel") == 1 and f % 16 == 0 then inp.a = true end
  elseif sc == 2 then
    if since > 50 and f % 16 == 0 then inp.a = true end
  elseif sc == 5 and since == 60 then
    log:write(string.format("CARREGOU time=%d rodada=%d temporada=%d antigo=%d reputacao=%d clubes=%d meta=%d tatica=%d\n",
      r8("g_user"), r8("g_round"), r8("g_season") + 256 * r8("g_season", 1), r8("sv_old"), r8("c_rep"), r8("c_clubs"), r8("g_goal"), r8("g_form")))
    local fh = io.open(dir .. "fotos/saveantigo.png", "wb"); fh:write(emu.takeScreenshot()); fh:close()
    log:close(); emu.stop(0); return
  end
  if f > 3000 then log:write("NAO CARREGOU tela=" .. sc .. "\n"); log:close(); emu.stop(1); return end
  emu.setInput(inp, 0)
end, emu.eventType.inputPolled)
