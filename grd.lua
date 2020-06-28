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
local npages = 2
local _r = 0.4
local _g = 0.3
local _delta = 0.01
local _duration = 0

local metro_draw
local metro_send

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
local map = function(r) return sc.lin1(r,1.45,2) end

grd1:fill()

local function sendsc()
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
    print("ch:".. d.ch .. " " .. d.type .. ":".. d.cc.. " ".. d.val)
  end
end

-- CLOCK coroutines
local clock_default = sc.linexp(_delta, 0, 1, 0.016, 3)
local clock_speed = clock_default

function pulse()
  while true do
    clock.sync(clock_speed)
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
  metro_draw = metro.init(function() redraw() end, 1/60)
  metro_draw:start()
  --metro_send = metro.init(sendsc, sc.linexp(_delta, 0, 1, 0.016, 3))

  -- START CLOCK on INIT?
  --clock.transport.start()
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
  screen.level(page == 0 and 15 or 2)
  screen.move(64,12)
  screen.text('r: ' .. sc.round(_r,4))
  screen.move(64,20)
  screen.text('g: ' .. sc.round(_g,4))
  screen.level(page == 1 and 15 or 2)
  screen.move(64,28)
  screen.text('delta: ' .. sc.round(_delta,4))
  screen.move(64,36)
  screen.text('duration: ' .. sc.round(_duration,4))
  screen.update()
end

function key(n,z)
  -- print('key' .. n .. " is " .. z)
  if n == 3 and z == 1 then
    if not playing then
      clock.transport.start()
      --metro_send:start()
      --playing = true
    else
      clock.transport.stop()
      --metro_send:stop()
      --playing = false
    end
  elseif n == 2 and z == 1 then
    page = (page+1)%npages
  end
end

function enc(n,d)
  -- print('enc ' .. n .. ' is ' .. d)
  if page == 0 then
    if n == 2 then _r = sc.clip(_r+(d*0.001),0,1) end
    if n == 3 then _g = sc.clip(_g+(d*0.001),0,1.05) end
  elseif page == 1 then
    if n == 2 then
      _delta    = sc.clip(d*0.01 + _delta, 0.01,1)
      --metro_send.time = _delta
      clock_speed = _delta
    end
    if n == 3 then
      _duration = sc.clip(d*0.01 + _duration, 0,1)
      engine.pong(sc.linexp(_duration, 0,1, 0.2,23))
    end
  end
end

function cleanup()
  m_draw:stop()
  --m_send:stop()
  metro.free_all()
end
