-- grd
--
-- :::..
--
-- k3 start/stop
-- k2 page
-- enc1,2 params

local sc = include('lib/sc')

engine.name = 'Grd'
screen.font_face(1)
screen.font_size(8)

local playing = false
local page = 0
local npages = 4
local nsounds = 11

local metro_draw

local grd1 = {}
grd1['xn'] = {}
grd1['n']  = 64
grd1.fill = function(self)
  for i=1,self.n do self.xn[i] = math.random()*2-1 end
end

grd1.next = function(self,r,g,fx,map)
  local prev = { table.unpack(self.xn) }
  local halfG = g * 0.5
  local rx = map(r)
  local n = self.n
  for i=1,n do
    self.xn[i] = sc.fold2(
      ((1.0 - g) * fx(rx, prev[i]))
      +
      (halfG * (fx(rx, prev[(i+1)%n+1]) + fx(rx, prev[(i-1)%n+1])))
    )
  end
end

local fx  = function(r,x) return 1 - (r*(x*x)) end
local map = function(r) return sc.lin1(r,1,2) end

grd1:fill()

local function sendsc()
  local _r = params:get('_r')
  local _g = params:get('_g')
  grd1:next(_r, _g, fx, map)
  engine.ping(table.unpack(grd1.xn))
end

-- MIDI SETUP
local clk_midi = midi.connect()
clk_midi.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "start" then
    if not playing then
      clock.transport.reset()
      clock.transport.start()
    end
  elseif d.type == "continue" then
    if playing then
      clock.transport.stop()
    else
      clock.transport.start()
    end
  end
  if d.type == "stop" then
    clock.transport.stop()
  end

  -- placeholder for MIDI CC messages
  if d.type == "cc" then
    -- print("ch:".. d.ch .. " " .. d.type .. ":".. d.cc.. " ".. d.val)
  end
end

-- clock
function pulse()
  while true do
    clock.sync(params:get('_delta'))
    sendsc()
  end
end
function clock.transport.start()
  print("transport.start")
  id = clock.run(pulse)
  playing = true
end
function clock.transport.stop()
  print("transport.stop")
  clock.cancel(id)
  playing = false
end
function clock.transport.reset()
  print("transport.reset")
end

function init()
  params:add_control('_r','R',controlspec.new(0,1,'lin',0.001,0.7,'',0.001,false))
  params:add_control('_g','G',controlspec.new(0,1,'lin',0.001,0.1,'',0.001,false))
  params:add_control('_delta','delta',controlspec.new(0.02,2,'lin',0.01,0.3,'',0.01,false))

  params:add_control('_duration','dur',controlspec.new(0.05,23,'exp',0.05,0.6,'',0.05,false))
  params:set_action('_duration', function(duration) engine.pong(duration) end)

  params:add_number('_root', 'root', 0, 127, 50)
  params:set_action('_root', function(root) engine.set_root(root) end)

  params:add_number('_mode','mode', 0, 6, 1)
  params:set_action('_mode', function(mode) engine.set_mode(mode) end)

  params:add_number('_sound','sound', 0, nsounds, 0)
  params:set_action('_sound', function(sound) engine.set_sound(sound) end)

  metro_draw = metro.init(function() redraw() end, 1/60)
  metro_draw:start()
end

-- should be global
function redraw()
  local index = 1
  screen.clear()
  for i=1,8 do
    for j=1,8 do
      screen.level(math.floor(sc.lin2(grd1.xn[index],0,15)))
      screen.rect(i*6, j*6, 5, 5)
      screen.fill()
      index = index + 1
    end
  end
  offset = 3
  screen.level(page == 0 and 15 or 2)
  screen.move(64,8+offset)
  screen.text('R: ' .. sc.round(params:get('_r'),3))
  screen.move(64,14+offset)
  screen.text('G: ' .. sc.round(params:get('_g'),3))
  screen.level(page == 1 and 15 or 2)
  screen.move(64,20+offset)
  screen.text('delta: ' .. sc.round(params:get('_delta'),3))
  screen.move(64,26+offset)
  screen.text('dur: ' .. sc.round(params:get('_duration'),3))
  screen.level(page == 2 and 15 or 2)
  screen.move(64,32+offset)
  screen.text('root: ' .. params:get('_root'))
  screen.move(64,38+offset)
  screen.text('mode: ' .. params:get('_mode'))
  screen.level(page == 3 and 15 or 2)
  screen.move(64,44+offset)
  local _sound = params:get('_sound')
  if _sound >= (nsounds) then screen.text('sound: *') else screen.text('sound: ' .. _sound) end
  screen.update()
end

function key(n,z)
  -- print('key' .. n .. " is " .. z)
  if n == 3 and z == 1 then
    if not playing then
      clock.transport.start()
    else
      clock.transport.stop()
    end
  elseif n == 2 and z == 1 then
    page = (page+1)%npages
  end
end

function enc(n,d)
  -- print('enc ' .. n .. ' is ' .. d)
  if page == 0 then
    if n == 2 then params:delta('_r', d) end
    if n == 3 then params:delta('_g', d) end
  elseif page == 1 then
    if n == 2 then params:delta('_delta', d) end
    if n == 3 then
      params:delta('_duration', d)
      engine.pong(params:get('_duration'))
    end
  elseif page == 2 then
    if n == 2 then
      params:delta('_root', d)
    end
    if n == 3 then
      params:delta('_mode', d)
    end
  elseif page == 3 then
    if n == 2 then
      params:delta('_sound', d)
    end
  end
end

function cleanup()
  m_draw:stop()
  metro.free_all()
end
