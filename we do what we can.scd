s.boot;
s.options.memSize = 8192 * 64;
s.record;

(
x = {
	arg gate = 1;
	var snd, env;
	env = EnvGen.ar(Env.new([0, 1, 0], [200, 200], \lin, 1), gate, doneAction: 2);
	snd = RLPF.ar(BrownNoise.ar(0.05) ! 2 * env, 100 * env, 0.8) + RLPF.ar(WhiteNoise.ar(0.025) ! 2 * env, env.range(20000, 18000), 0.8);
	Out.ar(0, snd);
}.play;
)

x.set(\gate, 0);

(
SynthDef.new(\sgong,{
	arg amp = 0.1, sus = 1, pan = 0, freq = 100, vib = 0, fmod = 0, rate = 0, bus = 0, blur = 1, beat_dur = 1, atk = 0.01, decay = 120, rel=0.01, peak=1, level=0.8, gate = 1, n = 10, dust = 0.1;
	var snd, env;

	sus = sus * blur;
	freq = [freq, freq+fmod];
	amp = (amp * 2.5);
	freq = (freq * 1);
	snd = Splay.arFill(10, {
		Klank.ar(
			`[
				[0.125 * Rand(0.95, 1.05), 1.0 * Rand(0.95, 1.05), 2.22 * Rand(0.95, 1.05), 2.002 * Rand(0.95, 1.05), 3* Rand(0.95, 1.05), 9.6* Rand(0.95, 1.05), 2.49* Rand(0.95, 1.05), 13* Rand(0.95, 1.05), 2.571* Rand(0.95, 1.05), 3.05* Rand(0.95, 1.05), 6.242* Rand(0.95, 1.05), 12.49* Rand(0.95, 1.05), 13* Rand(0.95, 1.05), 32* Rand(0.95, 1.05), 24* Rand(0.95, 1.05)],
				[0.002, 0.02, 0.01, 0.008, 0.02, 0.004, 0.02, 0.04, 0.02, 0.005, 0.5, 0.5, 0.02, 0.03, 0.4],
				[1.2, 1.2, 1.2, 0.9, 0.9, 0.9, 0.25, 0.25, 0.25, 0.14, 0.14, 0.14, 0.07, 0.07, 0.07]
			],
			SinOscFB.ar(20, 0.1, 10) * Dust.kr(0.1), freq, (freq * rate), decay) * amp / 30;
	});
	snd = HPF.ar(snd, 122);
	snd = Mix(snd);
	snd = snd * Line.kr(1, 0, decay, doneAction: 2);
	Out.ar(0, snd); // now can start multiple synths
}
).add;
)

Synth.new(\sgong, [\freq, 100, \dust, 0.1]);
Synth.new(\sgong, [\freq, 200, \dust, 0.25]);
Synth.new(\sgong, [\freq, 400, \dust, 1]);
Synth.new(\sgong, [\freq, 40, \dust, 1]);

(
SynthDef.new(\sticks, {
	arg freq = 440, scale = Scale.major, dr = 0.1, amp = 2, out = 0, length = 60;
	var snd;
	scale = Scale.major;

	snd = Splay.arFill(scale.ratios.size, {
		arg index;
		var fr, scale, pitch;

		scale = Scale.major;
		fr = scale.ratios.choose * freq;
		pitch = scale.ratios[index] * freq;

		BPF.ar(Decay.ar(Dust.ar(Rand(0.01, 0.01) + EnvGen.ar(Env.new([0, 1, 0], [length, length]), doneAction: 2)), Rand(0.01, dr)) * SinOsc.ar(pitch) * SinOsc.ar(Rand(220, 440)), fr, Rand(0.01, 0.3), 1);
	});

	snd = snd * amp;
	Out.ar(out, snd);
}
).add;
)

Synth.new(\sticks);
Synth.new(\sticks, [\freq, 200, \dr, 0.1]);
Synth.new(\sticks, [\freq, 440, \dr, 0.1]);
Synth.new(\sticks, [\freq, 100, \dr, 0.01]);

(
SynthDef.new(\long, {
	arg out = 0, freq = 440, amp = 0.5, att = 0.01, dec = 5, pan = 0, t_gate = 1, fmul = 0.5, rq = 0.5, oshift = 0;
	var snd, n = 20;

	Line.kr(dur: 25, doneAction: 2);

	snd = Splay.arFill(n, {
		var env, env2;
		env = EnvGen.ar(Env.perc(att + Rand(0.0, 15.0), dec + Rand(0.0, 12.0)), t_gate);
		env2 = EnvGen.ar(Env.perc(att + Rand(0.0, 15.0) + (dec / 2), (dec + Rand(0.0, 12.0)) / 2), t_gate);

		RLPF.ar(Saw.ar(Vibrato.ar((freq * (2**(IRand(0, oshift))))  + Rand(-10.0, 10.0), Rand(3.0, 6.0), Rand(0.01, 0.02), Rand(0.0, 2.0), Rand(0.0, 2.0), Rand(0.02, 0.1), Rand(0.05, 0.3) )), Rand(0.0, 0.5) + freq * (fmul + Rand(0.0, 1.5)) * env2, rq + Rand(-0.2, 0.2)) * env2 * Rand(0.8, 1.2) * amp / n;
	});

	Out.ar(out, Pan2.ar(snd, pan));
}).add;
)

(
Pbindef(
	\longBind,
	\instrument, \long,
	\degree, Pseq([
		[0, 3, 5],
		[0, 7, 10],
		[-2, 2, 3],
		[0, 4, 6]
	], inf),
	\dur, Pseq([Pbjorklund2(3, 16)], inf),
	\fmul, Pn(Pseries(0.0, 0.1, 50) ++ Pseries(5.0, -0.1, 50), inf),
	\oshift, Pdup(Pseq([4, 4, 4, 4], inf), Pseq([0, 1, 2, 1], inf)),
	\octave, Pdup(Pseq([16, 16, 16, 16], inf), Pseq([3, 4, 5, 4], inf)),
	\amp, 2,
	\rq, Pwhite(0.2, 0.9)
).play(quant: 4);
)

Pbindef(\longBind).stop;

(
SynthDef.new(\resbass, {
	arg out = 0, freq = 440, amp = 0.5, att = 0.01, dec = 5, pan = 0, t_gate = 1, fmul = 3.5, rq = 0.5;
	var snd, env;
	env = EnvGen.ar(Env.perc(0.01, dec), doneAction: 2);

	snd = Saw.ar(freq);
	snd = RLPF.ar(snd, freq * fmul * env, rq) * env * amp * 0.8;

	Out.ar(out, snd!2);
}).add;
)

(
Pbindef(
	\bassBind,
	\instrument, \resbass,
	\degree, Pn(Pdup(4, Pseq([0, 0, 1, 1, -2, -2, -2, -2]))),
	\dur, 0.5,
	\amp, 1.0,
	\dec, Pn(Pseries(0.3, 0.1, 32) ++ Pseries(0.3 + (0.1 * 32), -0.1, 32)),
	\rq, 0.5,
	\fmul, Pn(Pseries(2.5, 0.1, 32) ++ Pseries(5.7, -0.1, 32)),
	\octave, Pn(Pdup(64, Pseq([2, 3])));
).play(quant: 4);
)

Pbindef(\bassBind).stop;

(
SynthDef.new(\vibes, {
	arg out = 0, freq = 440, amp = 0.1, att = 4, dec = 10, pan = 0, t_gate = 1, fmul = 0.1, rq = 1;
	var snd, env;

	Line.kr(dur: dec + 2, doneAction: 2);
	env = EnvGen.ar(Env.perc(att, dec, 1, -7));

	snd = Saw.ar(freq * Rand(0.99, 1.01)) * SinOsc.ar(freq * Rand(0.99, 1.01) * 1.5003);
	snd = RLPF.ar(snd, freq * fmul * env, rq) * env * amp * 0.0;

	snd = snd;

	Out.ar(out, snd!2);
}).add;
)

(
Pbindef(
	\vibesBind,
	\instrument, \vibes,
	\degree, Pseq([0, 2, 3, 8, 7], inf),
	\dur, 0.25,
	\amp, 0.2,
	\pan, Pwhite(-0.5, 0.5)
).play(quant: 4);
)

Pbindef(\vibesBind, \degree, Pseq([0, 2, 3, 8, 7, 12, 5], inf));

(
Pbindef(
	\vibesBind2,
	\instrument, \vibes,
	\degree, Pseq([0, 2, 3, 8, 7], inf),
	\dur, 0.25,
	\amp, 0.2,
	\pan, Pwhite(-0.5, 0.5),
	\octave, 6
).play(quant: 4);
)

Pbindef(\vibesBind2, \degree, Pseq([0, 2, 3, 8, 7, 9, 16, 6], inf));

Pbindef(\vibesBind).stop;
Pbindef(\vibesBind2).stop;

(
SynthDef.new(\rings, {
	arg struct = 0.25, bright = 0.5,
	damp = 0.7, pos = 0.25, model = 0, poly = 1, intern_exciter = 0, dur,
	easteregg = 0, bypass = 0, mul = 1.0, add = 0, out = 0, midinote = 60, amp = 0.1;

	var snd;

	Line.ar(0, 0, dur * 4, doneAction: 2);

	snd = MiRings.ar(
		pit: midinote,
		struct: struct,
		bright: bright,
		damp: damp,
		pos: pos,
		model: model,
		poly: poly,
	);
	snd = MiMu.ar(snd, 1) * amp;

	Out.ar(out, snd);
}).add;
)

(SynthDef.new(\verb, { arg wet = 0.5; Out.ar(0, LeakDC.ar(MiVerb.ar(In.ar(16, 2), 0.99, Lag.kr(wet, 5))))}).add);

Bus.new(\audio, 16, 2);
~verb = Synth.new(\verb);

~verb.set(\wet, 0.9);

(
Pbindef(
	\ringsbind,
	\instrument, \rings,
	\octave, Pseq([5], inf),
	\degree, Pseq([0, 3, 4, 6, 2, 8, 11, 3, -2], inf),
	\delta, Pwhite(0.0, 5.0),
	\dur, 1,
	\bright, 0,
	\struct, 0,
	\damp, 0.5,
	\model, Prand([0], inf),
	\pos, Pwhite(0.1, 0.9),
	\amp, Pwhite(0.2, 0.3),
	\out, 16,
	\amp, 0.4
).play;
)

Pbindef(\ringsbind, \bright, Pwhite(0.4, 0.5));
Pbindef(\ringsbind, \struct, Pwhite(0.4, 0.5));
Pbindef(\ringsbind, \delta, Pwhite(0.5, 0.6) * 2.5);
Pbindef(\ringsbind, \model, Prand([1], inf));
Pbindef(\ringsbind, \octave, Pseq([3], inf) + 1);
Pbindef(\ringsbind, \degree, Pseq([0, 3, 4, 6, 2, 8, 11, 13, 7, 6, 3, -2], inf));
Pbindef(\ringsbind, \amp, Pwhite(0.1, 0.1));

Pbindef(\ringsbind).stop;


(
SynthDef.new(\long2, {
	arg out = 0, freq = 440, amp = 0.5, att = 10, dec = 20, pan = 0, t_gate = 1, fmul = 0.5, rq = 0.5, oshift = 0, det = 0.3,
	cfhzmin = 0.01, cfhzmax = 0.8, cfmin = 100, cfmax = 500, rqmin = 0.25, rqmax = 0.6, lsf = 200, ldb = 3;
	var snd, n = 10;

	Line.kr(dur: 25, doneAction: 2);

	snd = Splay.arFill(n, {
		var env, sig, tuning;

		env = EnvGen.ar(Env.perc(Rand(att / 10, att), Rand(dec / 10, dec)), t_gate);

		tuning = freq * LFNoise1.kr(LFNoise1.kr(0.3, 0.6),det).midiratio * (2**(IRand(0, 0)));

		sig = Saw.ar(tuning) + SinOsc.ar(tuning);

		sig = BPF.ar(sig, { LFNoise1.kr(LFNoise1.kr(4).exprange(cfhzmin,cfhzmax)).exprange(cfmin,cfmax) },
			{ LFNoise1.kr(0.2).exprange(rqmin,rqmax) });

		sig = BLowShelf.ar(sig, lsf, 0.5, ldb) * 0.6;

		sig = Decay2.ar(Impulse.ar(Rand(0.1, 0.2)), decayTime: 0.1) * sig;

		sig = sig * env / n * 3;


	});

	Out.ar(out, Pan2.ar(snd * amp, pan));
}).add;
)

(
Pbindef(
	\longBind2,
	\instrument, \long2,
	\degree, Pseq([
		[0, 3, 5],
		[0, 7, 10],
		[-2, 2, 3],
		[0, 4, 6]
	], inf),
	\dur, 5,
	\fmul, 2,
	\oshift, 2,
	\amp, 1,
	\rq, Pwhite(0.2, 0.9),
).play(quant: 4);
);

Pbindef(\longBind2).stop;

(
{
	EnvGen.ar(Env.new([0, 1, 0], [60, 60]), doneAction: 2) * Splay.arFill(50, {
		BPF.ar(CombC.ar(Formant.ar(LFNoise0.kr(0.1,5,9),LFNoise0.kr(0.1,8000,4000),200,0.3)), LFNoise0.kr(LFNoise0.kr(4).exprange(0.1,0.3)).exprange(50,1000) , Rand(0.01, 0.3)) * 3;
	});
}.play
);


(
SynthDef.new(\kick, {
	arg output = 0, amp = 0.1, clipamp = 1.5, freq = 100, peak = 100, decay = 1, curve = -100, gate = 1, click = 0.1;
	var env, snd, ampenv, clicky;

	env = EnvGen.ar(Env.perc(0.01, decay, 1, curve), doneAction: 0);
	ampenv = EnvGen.ar(Env.new([0, 1, 0], [0.001, 0.2], releaseNode: 1), gate, 1, 0, 1, doneAction: 2);
	clicky = WhiteNoise.ar(click) * EnvGen.ar(Env.perc(0.001, 0.01, 1, -8), doneAction: 0);

	snd = SinOsc.ar(freq + (env * peak), 0, 1);

	snd = snd + clicky;
	snd = snd * clipamp;
	snd = snd.softclip * amp * ampenv;

	Out.ar(output, [snd, snd]);
}
).add;
)


(
Pbindef(
	\kickBind,
	\instrument, \kick,
	\octave, 1,
	\dur, 0.1,
	\delta, Prand([Pseq(Bjorklund2(4, 8), 2) * 0.25], inf),
	\clipamp, 1.0,
	\amp, 0.3,
	\peak, Pwhite(100.0, 100),
	\decay, 0.5
).play(quant: 4);
)

Pbindef(\kickBind).stop;

(
SynthDef.new(\snare, {
	arg output = 0, amp = 0.1, freq = 180, decay = 0.1, noisy = 0.5, tuned = 0.3, res = 0.5, pan = 0.25, echotime = 3, dT = 4;
	var snd, e1, e2, f1, f2, f3, f4, noi;

	dT = 60 / (TempoClock.default.tempo * 60) / dT;

	f1 = freq; f2 = freq + 150; f3 = freq + 106; f4 = freq + 155;

	Line.ar(0, 0, echotime, doneAction: 2);

	e1 = EnvGen.ar(Env.perc(0.01, decay, curve: -10), doneAction: 0);
	e2 = EnvGen.ar(Env.perc(0.01, decay / 1.5), doneAction: 0);

	snd = (SinOsc.ar(f1) + SinOsc.ar(f2) + LFTri.ar(f3) + LFTri.ar(f4)) / 4;
	snd = snd * e2 * tuned;

	noi = WhiteNoise.ar(noisy);
	noi = BPF.ar(noi, 4000, res) * e1;

	snd = snd + noi * amp;

	snd = snd + RLPF.ar(CombC.ar(snd, dT, dT, echotime), 1000, 0.5, 0.5);

	Out.ar(output, Pan2.ar(snd, pan));
}
).add;
)

(
Pbindef(
	\snarebind,
	\instrument, \snare,
	\freq, Pseq([100, 200, 400, 800, 400, 200], inf),
	\dur, Pseq(Bjorklund2(5, 14), inf) * 0.125,
	\tuned, Pn(Pseries(0.0, 0.01, 100) ++ Pseries(1.0, -0.01, 100)),
	\decay, Pwhite(0.1, 0.15),
	\amp, Pseq([0.1, 0.05, 0.05, 0.05], inf) * 2,
	\dT, 2,
	\amp, 0.3
).play(quant: 4)
)

Pbindef(\snarebind, \dur, Pseq(Bjorklund2(5, 14), inf) * 0.125);

Pbindef(\snarebind).stop;

(
SynthDef.new(\hat,
	{
		arg output = 0, amp = 0.1, freq = 1000, pan = -0.25, decay = 0.05, res = 0.5, curve = -10;
		var env, snd;

		env = EnvGen.ar(Env.perc(0.001, decay, curve: curve), doneAction: 2);

		snd = WhiteNoise.ar(1);
		snd = BPF.ar(snd, freq, 0.1);
		snd = snd * amp * env;

		Out.ar(output, Pan2.ar(snd, pan));
	}
).add
)

(
Pbindef(
	\hatbind,
	\instrument, \hat,
	\octave, 11,
	\degree, 0,
	\dur, Pseq(Bjorklund2(4, 8), inf) * 1/16,
	\decay, Pseq([0.1, 0.01, 0.01, 0.01], inf),
	\amp, 0.5
).play(quant: 4);
)

Pbindef(\hatbind).stop;

(
SynthDef.new(\cowbell,
	{
		arg output = 0, amp = 0.1, freq = 587, pan = 0.5, res = 0.5, curve = -10, width = 0.5, decay = 0.45, rev = 3;
		var snd, env;

		Line.ar(0, 0, rev, doneAction: 2);

		env = EnvGen.ar(Env.perc(0.01, decay, curve: curve), doneAction: 0);

		snd = Pulse.ar(freq, width, 0.5) + Pulse.ar(freq * 1.44, width, 0.5);

		snd = BPF.ar(snd, 1000, 0.5);
		snd = snd * env * amp;

		snd = snd + GVerb.ar(snd, roomsize: 10, revtime: 1, drylevel: 0, mul: 0.3);

		Out.ar(output, Pan2.ar(snd, pan));
}).add
)

(
Pbindef(
	\cowbellbind,
	\instrument, \cowbell,
	\freq, 200,
	\dur, Pseq(Bjorklund2(3, 8), inf),
	\amp, 0.05
).play(quant: 4)
)

Pbindef(\cowbellbind).stop

(
SynthDef.new(\clave, {
	arg output = 0, amp = 0.01, decay = 0.01, curve = -10, width = 0.5, pan = -1, freq = 110, rev = 2;
	var env, snd;

	Line.ar(0, 0, rev, doneAction: 2);

	env = EnvGen.ar(Env.perc(0.00, decay, curve: curve), doneAction: 0);

	snd = Pulse.ar(freq, width) * Pulse.ar(freq * 2.1, width);


	snd = HPF.ar(snd, 500 + (env * 100)) * env * amp;

	snd = RLPF.ar(snd + GVerb.ar(snd, revtime: rev, drylevel: 0, mul: 0.3), 1000, 0.3);

	Out.ar(output, Pan2.ar(snd, pan));
}).add;
)

(
Pbindef(
	\clavebind,
	\octave, 7,
	\instrument, \clave,
	\dur, Pseq(Bjorklund2(6, 16), inf) * 0.5,
	\amp, Pseq([0.01, 0.03], inf),
).play(quant: 4)
)

Pbindef(\clavebind).stop;

(
SynthDef(\bassy, {
	arg freq = 440, amp = 0.5, att = 0.01, dec = 4, f1 = 10, t_gate = 1, out = 0, rq = 0.1, div = 1;
	var snd, env;

	f1 = f1 * 0.05;
	rq = rq / 0.5;
	env = EnvGen.ar(Env.new([0, 1, 0], [att, dec], [4, -10]), t_gate, doneAction: 2);
	snd = Saw.ar(freq);
	snd = Splay.ar(snd);
	snd = (snd * 3).fold2;
	snd = RLPF.ar(snd, freq / div * 10, rq);
	snd = (snd * 5).fold2;
	snd = MoogFF.ar(snd, freq * f1 * env, 1);
	snd = snd + DelayC.ar(snd, 0.01, SinOsc.ar(0.5, [0, pi]).range(0, 0.001));
	snd = (snd * 3.dbamp).tanh * env * amp;
	Out.ar(out, snd);
}).add;
)

(
Pbindef(
	\bassy,
	\instrument, \bassy,
	\octave, 2,
	\degree, Pseq([0], inf),
	\dur, Pn(Pseq(Bjorklund2(5, 16) , inf)) * 0.125,
	\amp, 0.05,
	\att, Pn(Pseries(0.1, 0.1, 10) ++ Pseries(1, -0.1, 10), inf) / 8,
	\dec, 2,
	\f1, Pn(Pseries(0.1, 0.1, 10) ++ Pseries(1, -0.1, 10), inf) * 100 + 20,
	\rq, Pn(Pseries(0.1, 0.1, 20) ++ Pseries(2, -0.1, 20), inf) / 10 + 0.05,
).play(quant: 4)
)

Pbindef(\bassy).stop 