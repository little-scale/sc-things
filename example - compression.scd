(
s.boot;
s.options.memSize = 8192 * 32;
s.options.numBuffers = 2048;

~filepath = PathName.new(thisProcess.nowExecutingPath).pathOnly;
~b0 = Buffer.read(s, ~filepath ++ "WN_160_Break_01.wav");
~b1 = Buffer.read(s, ~filepath ++ "WN_160_Break_02.wav");
~b2 = Buffer.read(s, ~filepath ++ "WN_160_Break_03.wav");
~b3 = Buffer.read(s, ~filepath ++ "WN_160_Break_04.wav");
)

(
SynthDef.new(\kick, {
	arg out = 0, side = 24, amp = 0.1, clipamp = 2.0, f = 40, peak = 100, decay = 0.1, amp_decay = 5, curve = -40, t_gate = 1, click = 1;
	var env, snd, ampenv, impact;

	env = EnvGen.ar(Env.perc(0.01, decay, 1, curve), t_gate, doneAction: 0);
	ampenv = EnvGen.ar(Env.perc(0.001, amp_decay, 1, curve), t_gate, doneAction: 2);
	impact = WhiteNoise.ar(click) * EnvGen.ar(Env.perc(0.001, 0.02, 1, -10), doneAction: 0);

	snd = SinOsc.ar(f + (env * peak), 0, 1);
	snd = snd + impact;
	snd = MiMu.ar(snd, clipamp) * amp * ampenv ! 2; // apply distortion

	Out.ar(out, snd);
	Out.ar(side, ampenv ! 2);
}
).add;
)

(
SynthDef.new(\hat, {
	arg out = 0, pan = 0.3, amp = 0.1, lfoin = 20, side = 24;
	var snd, lfo, in;

	lfo = InFeedback.ar(lfoin, 1).range(-1000, 1000);
	in = InFeedback.ar(side, 2).range(0, 1);
	snd = WhiteNoise.ar(amp) * EnvGen.ar(Env.perc(0.001, 0.1, 1, -10), doneAction: 2);
	snd = BPF.ar(snd, 10000 + lfo, 0.1);
	Out.ar(out, Pan2.ar(snd, pan));
}).add;
)

(
SynthDef.new(\rings, {
	arg struct = 0.5, bright = 0.2, damp = 0.5, pos = 0.3, model = 0, dur, midinote = 60, amp = 0.1, out = 0;
	var snd;

	Line.ar(0, 0, dur, doneAction: 2);
	snd = MiRings.ar( pit: midinote, struct: struct, bright: bright, damp: damp, pos: pos, model: model) * amp ! 2;

	Out.ar(out, snd);
}).add;
)

(
SynthDef.new(\bass, {
	arg freq, amp, fmul = 80, decay = 3, side = 24, out = 0,t_gate = 1, att = 0.01, rel = 1, clipamp = 10, lfoin = 20;
	var env, snd, in, fcontrol, lfo;

	env = EnvGen.ar(Env.perc(releaseTime: rel), t_gate, doneAction: 2);
	in = InFeedback.ar(side, 2).range(0, 1);

	lfo = InFeedback.ar(lfoin, 1).range(-10, 50);

	fcontrol = (freq + lfo) * (fmul * (1 - in)) * env;
	snd = Saw.ar(freq) + Formant.ar(freq, 400, 300);
	snd = MoogLadder.ar(snd, fcontrol, 0.5);
	snd = MiMu.ar(snd, clipamp);
	snd = MoogFF.ar(snd, fcontrol, 1);
	snd = snd.distort;
	snd = RLPF.ar(snd, fcontrol * 1, 0.2);
	snd = Clip.ar(snd, 0.02, 1);
	snd = BHiShelf.ar(snd, 1000 + (lfo * 10), 0.5, 12);
	snd = BLowShelf.ar(snd, 400 + (lfo * 1), 0.5, 12);
	snd = snd * env * amp;

	Out.ar(out, snd);
}).add;
)

(
SynthDef.new(\playloop, {
	arg amp = 0.5, bufnum, out = 0, rate = 1, start = 0, dur, att = 0.01;
	var snd;

	Line.ar(0, 0, dur, doneAction: 2);
	snd = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * rate, startPos: start, doneAction: 2);
	snd = RHPF.ar(snd, 700, 1.0);
	snd = snd * amp * Line.ar(0, 1, att);

	Out.ar(out, snd);
}).add;
)

(
SynthDef.new(\sidechain, {
	arg in = 22, side = 24, out = 0, thresh = 0.3, ratio = 1/10, attack = 0.02, release = 0.25;
	Out.ar(out, Compander.ar(In.ar(in, 2), In.ar(side, 2), thresh, 1, ratio, attack, release));
}).add;
)

(
SynthDef.new(\lfo, { arg out = 20, freq = 0.1, amp = 1; Out.ar(out, SinOsc.ar(freq, 0, amp)); }).add;
)

(
SynthDef.new(\verb, {
	arg wet = 0.1, in = 16, out = 0, dt = 0.25, da = 0.2;
	var snd;
	snd = In.ar(in, 2);
	snd = snd + (CombC.ar(snd, 2, dt, 2) * da);
	snd = LeakDC.ar(MiVerb.ar(snd, 0.9, Lag.kr(wet, 5)));
	Out.ar(out, snd)
}).add
);

(
Bus.new(\audio, 20, 2);
~lfo = Synth.new(\lfo);

Bus.new(\audio, 22, 2);
~sidechain = Synth.new(\sidechain);

Bus.new(\audio, 16, 2);
~verb = Synth.new(\verb, [\out, 22]);
)

~sidechain.set(\thresh, 0.2, \ratio, 1/5, \attack, 0.01, \release, 0.4);
~verb.set(\wet, 0.4, \dt, TempoClock.tempo / 2.5, \da, 0.4);
TempoClock.tempo = 80 / 60;

(
Pbindef(
	\kickbind,
	\instrument, \kick,
	\amp, 0.5,
	\dur, Pseq([(Pbjorklund2(5, 16, 4) / 4) ++ (Pbjorklund2(6, 16, 3) / 4) ++ (Pbjorklund2(4, 16, 1) / 4)], inf);
).play(quant: 4);
)

(
Pbindef(
	\ringsbind,
	\instrument, \rings,
	\delta, 1/2,
	\octave, Prand([3, 4, 5], inf),
	\degree, Pn(Pser([0, 3, 4, 7, 8, 9, 11], 32) ++ Pser([0, 5, 10, 16, 5], 32), inf),
	\amp, 1,
	\model, Prand([0, 1, 2], inf),
	\struct, Pwhite(0.2, 0.5),
	\bright, Pwhite(0.2, 0.5),
	\damp, Pwhite(0.2, 0.5),
	\out, 16,
).play(quant: 4);
)

(
Pbindef(
	\bassbind,
	\instrument, \bass,
	\degree, 0,
	\octave, 2,
	\dur, 1/4,
	\amp, 0.1,
	\out, 0
).play(quant: 4)
)

(
Pbindef(
	\hatbind,
	\instrument, \hat,
	\dur, Pwrand([1/8, 1/16],[10, 5].normalizeSum, inf),
	\out, 22,
	\amp, 0.3
).play(quant: 4);
)

(
Pbindef(
	\loopbind,
	\instrument, \playloop,
	\bufnum, Prand([~b0.bufnum, ~b1.bufnum, ~b2.bufnum, ~b3.bufnum], inf),
	\dur, Prand([1/4], inf),
	\delta, 1/4,
	\start, Pn(Pseries(0, 1, 8) * (~b0.numFrames / 8), inf),
	\rate, 1,
	\amp, 0.6,
	\out, 22
).play(quant: 4);
)

Pbindef(\kickbind).stop;
Pbindef(\ringsbind).stop;
Pbindef(\bassbind).stop;
Pbindef(\hatbind).stop;
Pbindef(\loopbind).stop;