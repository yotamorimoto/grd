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
local _r = 0.7
local _g = 0.1
local _delta = 0.3
local _duration = 0.6
local _dur
local _root = 50
local _mode = 0
local _sound = 0

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

-- clock
function pulse()
  while true do
    clock.sync(_delta)
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
  _dur = sc.linexp(_duration, 0,1, 0.05,23)
  engine.pong(_dur)
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
  screen.text('R: ' .. sc.round(_r,3))
  screen.move(64,14+offset)
  screen.text('G: ' .. sc.round(_g,3))
  screen.level(page == 1 and 15 or 2)
  screen.move(64,20+offset)
  screen.text('delta: ' .. sc.round(_delta,3))
  screen.move(64,26+offset)
  screen.text('dur: ' .. sc.round(_dur,3))
  screen.level(page == 2 and 15 or 2)
  screen.move(64,32+offset)
  screen.text('root: ' .. _root)
  screen.move(64,38+offset)
  screen.text('mode: ' .. _mode)
  screen.level(page == 3 and 15 or 2)
  screen.move(64,44+offset)
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
    if n == 2 then _r = sc.clip(_r+(d*0.001),0,1) end
    if n == 3 then _g = sc.clip(_g+(d*0.001),0,1) end
  elseif page == 1 then
    if n == 2 then
      _delta = sc.clip(d*0.01 + _delta, 0.02,2)
    end
    if n == 3 then
      _duration = sc.clip(d*0.01 + _duration, 0,1)
      _dur = sc.linexp(_duration, 0,1, 0.05,23)
      engine.pong(_dur)
    end
  elseif page == 2 then
    if n == 2 then
      _root = sc.clip(d + _root, 0,127)
      engine.set_root(_root)
    end
    if n == 3 then
      _mode = sc.clip(d + _mode, 0,6)
      engine.set_mode(_mode)
    end
  elseif page == 3 then
    if n == 2 then
      _sound = sc.clip(d + _sound, 0, nsounds)
      engine.set_sound(_sound)
    end
  end
end

function cleanup()
  m_draw:stop()
  metro.free_all()
end