Engine_Grd : CroneEngine {

	var group,sample,map,d2k;
	var duration, root, mode, mindex;

	*new { |context, doneCallback| ^super.new(context, doneCallback) }

	alloc {
		Server.default = context.server;
		duration = 1;
		root = 50;
		group  = ParGroup.tail(context.xg);
		sample = Sample.celesta;
		map    = sample.map;
		mode   = [
		  [0,2,4,6,7,9,11],
		  [0,2,4,5,7,9,11],
		  [0,2,4,5,7,9,10],
		  [0,2,3,5,7,9,10],
		  [0,2,3,5,7,8,10],
		  [0,1,3,5,7,8,10],
		  [0,1,3,5,6,8,10],
		];
		mindex = 0;
		d2k = { |degree, mode|
			var size = mode.size;
			var deg = degree.round;
			12 * deg.div(size) + mode[deg%size];
		};
		(
			line: { |dur| Env.linen(0.005,0,dur).kr(2) },
			sine: { |dur| Env.sine(dur).kr(2) },
			perc: { |dur| Env.perc(dur,0.01,1,6).kr(2) }
		).keysValuesDo { |n,e|
			SynthDef(n, { |buf,rate=1,pos=0,amp=1,dur=1,pan=0|
				var sig, env;
				sig = PlayBuf.ar(
					1, buf,
					rate*BufRateScale.ir(buf)*if(n==\perc,{-1},{1}),
					1,
					pos*BufFrames.ir(buf)
				);
				env = SynthDef.wrap(e,prependArgs:[dur]);
				sig = sig * env * amp;
				sig = LinPan2.ar(sig, pan);
				Out.ar(0, sig);
			}).add;
		};
		this.addCommand(\ping, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", { |m|
			var key;
			([0,12,24]+root).do { |base,i|
				key = d2k.((m[i*8+1]*8).asInteger, mode[mindex]);
				Synth.grain([\sine,\line,\perc][((m[i*8+2].abs*6)%3).asInteger], [
					buf:  map[base+key][0],
					rate: map[base+key][1],
					pos:  m[i*8+3].linlin(-1,1,0.1,0.3),
					amp:  dbamp(m[i*8+4].linlin(-1,1,-12,-3)-(i*1.5)),
					dur:  duration*[m[i*8+5].linlin(-1,1,0.05,0.3),2].wchoose([0.9,0.1]),
					pan:  m[i*8+6],
				], group);
			};
		});
		this.addCommand(\pong, "f", { |m|
		  duration = m[1]
		});
		this.addCommand(\set_root, "f", { |m|
		  root = m[1].asInteger
		});
		this.addCommand(\set_mode, "f", { |m|
		  mindex = m[1].asInteger
		});
	}
	free { sample.free }
}