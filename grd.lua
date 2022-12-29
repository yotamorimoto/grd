-- grd
--
-- :::..
--
-- k3 start/stop
-- k2 page
-- enc1 section 
-- enc2,3 params

local sc = include('lib/sc')

engine.name = 'Grd'
screen.font_face(1)
screen.font_size(8)

local playing = false
local section = 0
local nsections = 2
local page = 0
local npages = 4
local nsounds = 11
local nsample = 3
local random_mode = {1,2,3,4,5,6,7}

local metro_draw

-- see https://monome.org/docs/norns/reference/lib/lfo
_lfos = require 'lfo'


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

function randomize_mode()
  for i = 1, 7 do
    random_mode[i] = math.random(0, 13)
  end
  params:set('_mode', 0)
  engine.update_mode(0,
        random_mode[1],
        random_mode[2],
        random_mode[3],
        random_mode[4],
        random_mode[5],
        random_mode[6],
        random_mode[7]
        )
end

function init()
  params:add_group('LFOs', 15*6)   -- rows * #lfo
  r_lfo = _lfos:add{min = 0, max = 1}
  r_lfo:add_params('r_lfo', 'R')
  r_lfo:set('action', function(s) params:set('_r', s) end)
  g_lfo = _lfos:add{min = 0, max = 1}
  g_lfo:add_params('g_lfo', 'G')
  g_lfo:set('action', function(s) params:set('_g', s) end)
  delta_lfo = _lfos:add{min = 0.02, max = 2}
  delta_lfo:add_params('delta_lfo', 'delta')
  delta_lfo:set('action', function(s) params:set('_delta', s) end)
  duration_lfo = _lfos:add{min = 0.05, max = 23}
  duration_lfo:add_params('duration_lfo', 'duration')
  duration_lfo:set('action', function(s) params:set('_duration', s) end)
  root_lfo = _lfos:add{min = 20, max = 90}
  root_lfo:add_params('root_lfo', 'root')
  root_lfo:set('action', function(s) params:set('_root', s) end)
  mode_lfo = _lfos:add{min = 0, max = 7}
  mode_lfo:add_params('mode_lfo', 'mode')
  mode_lfo:set('action', function(s) params:set('_mode', s) end)

  params:add_control('_r','R',controlspec.new(0,1,'lin',0.001,0.7,'',0.001,false))
  params:add_control('_g','G',controlspec.new(0,1,'lin',0.001,0.1,'',0.001,false))
  params:add_control('_delta','delta',controlspec.new(0.02,2,'lin',0.01,0.3,'',0.01,false))
  params:add_control('_duration','dur',controlspec.new(0.05,23,'exp',0.05,0.6,'',0.05,false))
  params:set_action('_duration', function(duration) engine.pong(duration) end)
  params:add_control('_root','root',controlspec.new(0,127,'lin',1,50,'',0.005, false))
  params:set_action('_root', function(root) engine.set_root(root) end)
  params:add_control('_mode','mode',controlspec.new(0,7,'lin',1,0,''))
  params:set_action('_mode', function(mode) engine.set_mode(mode) end)
  params:add_control('_sound','sound',controlspec.new(0,nsounds,'lin',1,0,'',0.005, false))
  params:set_action('_sound', function(sound) engine.set_sound(sound) end)
  params:add_control('_sample','sample',controlspec.new(1,nsample,'lin',1,1,''),0.005, false)
  params:set_action('_sample', function(sample) engine.set_sample(sample) end)

  metro_draw = metro.init(function() redraw() end, 1/60)
  metro_draw:start()

end

redraw_pages = {} -- page, section, element
for i = 0, npages-1 do
  redraw_pages[i] = {}
  for j = 0, nsections-1 do
    redraw_pages[i][j] = {}
  end
end

redraw_pages[0][0][1] = function() screen.text('R: ' .. sc.round(params:get('_r'),3)) end
redraw_pages[0][0][2] = function() screen.text('G: ' .. sc.round(params:get('_g'),3)) end
redraw_pages[1][0][1] = function() screen.text('delta: ' .. sc.round(params:get('_delta'),3)) end
redraw_pages[1][0][2] = function() screen.text('dur: ' .. sc.round(params:get('_duration'),3)) end
redraw_pages[2][0][1] = function() screen.text('root: ' .. params:get('_root')) end
redraw_pages[2][0][2] = function() screen.text('mode: ' .. params:get('_mode')) end
redraw_pages[3][0][1] = function()
    local _sound = params:get('_sound')
    if _sound >= (nsounds) then screen.text('sound: *') else screen.text('sound: ' .. _sound) end
  end
redraw_pages[3][0][2] = function() screen.text('sample: ' .. params:get('_sample')) end

for i = 1,3 do
  for j = 1,2 do
    redraw_pages[i][1][j] = function() end
  end
end
redraw_pages[0][1][1] = function() screen.text('tempo: ' .. params:get('clock_tempo')) end
redraw_pages[0][1][2] = function() screen.text('reverb: ' .. params:string('reverb')) end
redraw_pages[1][1][2] = function() end
redraw_pages[1][1][2] = function()
    local m = random_mode[1]
    for i=2,7 do m = m ..'.'.. random_mode[i] end
    screen.text('? ' .. m)
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
  row = 8 + offset
  if section == 0 then
    for i = 0,3 do
      screen.level(page == i and 15 or 2)
      screen.move(64, row)
      redraw_pages[i][0][1]()
      row = row + 6
      screen.move(64,row)
      redraw_pages[i][0][2]()    
      row = row + 6
    end
  elseif section == 1 then
    if page > 1 then page = 0 end
    for i = 0,1 do
      screen.level(page == i and 15 or 2)
      screen.move(64,row)
      redraw_pages[i][1][1]()
      row = row + 6
      screen.move(64,row)
      redraw_pages[i][1][2]()
      row = row + 6
    end
  end

  screen.update()
end

function key(n,z)
  -- print('key' .. n .. " is " .. z)
  if n == 1 then
    alt = z==1
  elseif n == 3 and z == 1 then
    if not playing then
      clock.transport.start()
    else
      clock.transport.stop()
    end
  elseif n == 2 and z == 1 then
    if not alt==true then
      local pdiv = section==0 and npages or 2
      page = (page+1)%pdiv
    else
      params:set('_r', sc.round(math.random(), 3));
      params:set('_g', sc.round(math.random(), 3));
      params:set('_delta', sc.round(math.random(), 2));
      params:set('_duration', sc.round(math.random()*7, 2));
      params:set('_root', math.random(40,55));
      params:set('_mode', math.random(0,7));
    end
  end
end

enc_update = {}  -- page, section, enc
for i = 0, npages-1 do
  enc_update[i] = {}
  for j = 0, nsections-1 do
    enc_update[i][j] = {}
  end
end

enc_update[0][0][2] = function(d) params:delta('_r', d) end
enc_update[0][0][3] = function(d) params:delta('_g', d) end
enc_update[1][0][2] = function(d) params:delta('_delta', d) end 
enc_update[1][0][3] = function(d) params:delta('_duration', d); engine.pong(params:get('_duration')) end
enc_update[2][0][2] = function(d) params:delta('_root', d); engine.set_root(params:get('_root')) end
enc_update[2][0][3] = function(d) params:delta('_mode', d); engine.set_mode(params:get('_mode')) end
enc_update[3][0][2] = function(d) params:delta('_sound', d); engine.set_sound(params:get('_sound')) end
enc_update[3][0][3] = function(d) params:delta('_sample', d); engine.set_sample(params:get('_sample')) end

enc_update[0][1][2] = function(d) params:delta('clock_tempo', d) end
enc_update[0][1][3] = function(d)
    local rev = d > 0 and 2 or 1
    params:set('reverb', rev)
    if rev == 1 then audio.rev_off() else audio.rev_on() end
    norns.state.mix.aux = rev
end
enc_update[1][1][2] = function(d)
  if d > 0 then randomize_mode() end
end
enc_update[1][1][3] = function(d) end
for i=2,3 do
  enc_update[i][1][2] = function(d) end
  enc_update[i][1][3] = function(d) end
end

function enc(n,d)
  if n == 1 then
    section = util.clamp(section + d, 0, nsections-1)
  else
    enc_update[page][section][n](d)
  end
end

function cleanup()
  m_draw:stop()
  metro.free_all()
end
