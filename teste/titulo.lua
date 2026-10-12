local f = 0
local dir = "C:/Users/ramon/Desktop/elifoot98/snes/teste/fotos/"
local function shot(n) local fh = io.open(dir .. n .. ".png", "wb") fh:write(emu.takeScreenshot()) fh:close() end
emu.addEventCallback(function()
  f = f + 1
  local inp = {}
  if f == 90 then shot("t_titulo") end
  if f == 100 then inp.start = true end
  if f == 130 then shot("t_menu") end
  if f == 140 then inp.a = true end
  if f == 200 then inp.a = true end
  if f >= 260 and f < 330 and f % 10 == 0 then inp.a = true end
  if f >= 260 and f < 330 and f % 10 == 5 then inp.right = true end
  if f == 340 then shot("t_nome") end
  if f == 350 then inp.start = true end
  if f == 420 then shot("t_time_d") end
  if f == 430 then inp.left = true end
  if f == 440 then inp.left = true end
  if f == 450 then inp.left = true end
  if f == 470 then shot("t_time_a") end
  if f == 480 then inp.down = true end
  if f == 490 then inp.a = true end
  if f == 600 then shot("t_hub") emu.stop(0) end
  emu.setInput(inp, 0)
end, emu.eventType.inputPolled)
