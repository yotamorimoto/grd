Engine_Grd : CroneEngine {

	var group, d2k;
	var duration, root, mode, mindex;
	var confetti, sound;

	*new { |context, doneCallback| ^super.new(context, doneCallback) }

	alloc {
		var p = thisMethod.filenameSymbol.asString.dirname +/+ "confetti";
		var s;
		Server.default = context.server;
		s = Server.default;
		sound = 0;
		confetti = [
			[Buffer.read(s, p +/+ "cel_65.wav"), 65],
			[Buffer.read(s, p +/+ "hrp_59.wav"), 59],
			[Buffer.read(s, p +/+ "kba_58.wav"), 58],
			[Buffer.read(s, p +/+ "mba_59.wav"), 59],
			[Buffer.read(s, p +/+ "gtr_63.wav"), 63],
			[Buffer.read(s, p +/+ "toy_84.wav"), 84],
			[Buffer.read(s, p +/+ "pe_66.wav"), 66],
			[Buffer.read(s, p +/+ "wah_79.wav"), 79],
			[Buffer.read(s, p +/+ "gml_52.wav"), 52],
		];
		duration = 1;
		root = 50;
		group  = ParGroup.tail(context.xg);
		mode   = [
			[0,2,4,6,7,9,11], // lydian
			[0,2,4,5,7,9,11], // ionian
			[0,2,4,5,7,9,10], // mixolydian
			[0,2,3,5,7,9,10], // dorian
			[0,2,3,5,7,8,10], // aeolean
			[0,1,3,5,7,8,10], // phrygian
			[0,1,3,5,6,8,10], // locrian
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
				Synth.grain([\sine,\line,\line,\perc][((m[i*8+2].abs*6)%3).asInteger], [
					buf:  confetti[sound][0],
					rate: midiratio(base+key-confetti[sound][1]),
					pos:  m[i*8+3].linlin(-1,1,0,0.1),
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
		this.addCommand(\set_mode, "i", { |m|
			mindex = m[1].asInteger
		});
		this.addCommand(\set_sound, "i", { |m|
			sound = m[1]
		});
	}
	free { confetti.do(_.do(_.free)); }
}