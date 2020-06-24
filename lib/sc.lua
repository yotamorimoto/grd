local sc = {}

local function mod(x,y) return ((x%y)+y)%y end
function sc.fold(x,lo,hi)
  x = x - lo
  r = hi - lo
  w = mod(x,r)
  if mod(x/r,2) > 1 then 
    return hi - w 
    else 
    return lo + w 
  end
end
function sc.fold2(x) return sc.fold(x,-1,1) end
function sc.midiratio(n) return math.pow(2,n*(1/12)) end
function sc.midicps(n) return 440*math.pow(2,(n-69)*(1/12)) end
local M_LN2 = 0.69314718055994530942 -- log_e 2
local function log2(x) return math.log(x) / M_LN2 end
function sc.cpsmidi(n) return log2(n*(1/440))*12+69 end
function sc.dbamp(db) return math.pow(10, db*0.05) end
function sc.ampdb(amp) return math.log10(amp)*20 end
function sc.clip(x,lo,hi) return math.min(math.max(x,lo),hi) end
function sc.round(x,a)
  local mul = 10^(a or 0)
  return math.floor(x * mul + 0.5) / mul
end
function sc.linlin(x,a,b,c,d)
  if x <= a then return c end
  if x >= b then return d end
  return (x - a) / (b - a) * (d - c) + c;
end
function sc.lin1(x,lo,hi) return sc.linlin(x,0,1,lo,hi) end
function sc.lin2(x,lo,hi) return sc.linlin(x,-1,1,lo,hi) end
function sc.linexp(x,a,b,c,d)
  if x <= a then return c end
  if x >= b then return d end
  return math.pow(d / c, (x - a) / (b - a)) * c
end
function sc.linexp(x,a,b,c,d)
  if x <= a then return c end
  if x >= b then return d end
  return math.pow(d / c, (x - a) / (b - a)) * c
end

return sc