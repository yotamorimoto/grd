MIDIIn.connectAll;
p = thisProcess.nowExecutingPath.dirname;
b.do(_.do(_.free));
(
b = [
	[Buffer.read(s, p +/+ "kba_58.wav"), 58],
	[Buffer.read(s, p +/+ "gml_52.wav"), 52],
	[Buffer.read(s, p +/+ "gml_32.wav"), 32],
	[Buffer.read(s, p +/+ "hrp_59.wav"), 59],
	[Buffer.read(s, p +/+ "pan_74.wav"), 74],
	[Buffer.read(s, p +/+ "gtr_63.wav"), 63],
	[Buffer.read(s, p +/+ "oud_52.wav"), 52],
	[Buffer.read(s, p +/+ "mba_59.wav"), 59],
	[Buffer.read(s, p +/+ "cel_65.wav"), 65],
	[Buffer.read(s, p +/+ "toy_84.wav"), 84],
	[Buffer.read(s, p +/+ "pf_95.wav"), 95],
	[Buffer.read(s, p +/+ "pe_66.wav"), 66],
	[Buffer.read(s, p +/+ "plt_74.wav"), 74],
	[Buffer.read(s, p +/+ "wah_79.wav"), 79],
];
)
(
~nodes = Array.newClear(128);
SynthDef(\simplay, { |gate=1, buf, ref, note, amp=1, pos=0|
    var sig, env;
	sig = PlayBuf.ar(1, buf, BufRateScale.ir(buf)*midiratio(note-ref), 1, pos);
    env = Env.adsr(0,0,3).kr(2,gate);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, Rand(-0.7, 0.7));
    Out.ar(0, sig);
}).add;
MIDIFunc.noteOn { |v,n|
	var index = b.size.rand;
	~nodes[n] = Synth(\simplay, [buf:b[index][0], ref:b[index][1], note:n, pos:v.linlin(0,127,40000,0), amp:v.linlin(0,127,-24,0).dbamp]);
};
MIDIFunc.noteOff { |v,n| ~nodes[n].release };
)
b.free;

(
SynthDef(\simplay, { |note, amp=1, pos=0|
    var sig, env;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b)*midiratio(note-58), 1, pos);
    env = Env.linen(0,1,3).kr(2);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, Rand(-0.7, 0.7));
    Out.ar(0, sig);
}).add;
w = Window.new;
w.front;
w.alwaysOnTop = true;
d = (
	z:0,x:2,c:4,v:5,b:7,n:9,m:11,',':12,'.':14,
	a:-1,s:1,d:3,f:4,g:6,h:8,j:10,k:11,l:13,
	q:12,w:14,e:16,r:17,t:19,y:21,u:23,i:24,o:26,p:28,
);
~octave = 60-24;
w.view.keyDownAction = { |...v|
	Synth.grain(\simplay, [note: ~octave + d[v[1].asSymbol], amp:0.9, pos:10000.rand])
};
CmdPeriod.doOnce { w.close };
)