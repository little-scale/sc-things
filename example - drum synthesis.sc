// Memory size
// Synthesised drum sounds
// Applying effects within synthdefs
// Panning
// Quantised patterns

// Kick - distorted sweep with a click
// Snare - sines waves at 180, 180  + 150 and tri waves at 180 + 106 and 180 + 155 with enveloped noise
// Hi hat - filtered noise
// Cowbell - enveloped pulse waves at 587 anbd 587 * 1.44
// Tom - distorted and filtered sweep
// Cymbal - high pass filtered randomly tuned square waves 200 - 800
// Clave - square wave at 220 modulated by a square wave 5.1x with a bandpass

s.options.memSize = 8192 * 32; // Making a larger memory allocation for delays and reverbs

TempoClock.default.tempo = 96 / 60;

(
SynthDef.new(\kick, {
	arg output = 0, amp = 0.1, clipamp = 1.5, freq = 100, peak = 100, decay = 3, curve = -100, gate = 1, click = 0.1;
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
	\kickbind, // this is the name of this Pbind!
	\instrument, \kick,
	\octave, 1,
	\dur, 0.8,
	\delta, Prand([3], inf) * 1/4,
	\clipamp, Pseq([3, 2, 1, 1], inf),
	\peak, Pwhite(100.0, 150.0)
).play(quant: 4);
)

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
	\freq, 180,
	\dur, Pseq([2, 1, 3], inf) * 1/4,
	\tuned, 0.2,
	\decay, Pwhite(0.1, 0.15),
	\amp, Pseq([0.1, 0.05, 0.05, 0.05], inf) * 2,
	\dT, 2
).play(quant: 4)
)

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
	\octave, 10,
	\degree, Pseq([7, 3, 2, 0], inf),
	\dur, Pdup(Pseq([14, 4], inf), Pseq([2, 1], inf)) * 1/4,
	\decay, Pdup(Pseq([3, 1], inf), Pseq([0.2, 0.025], inf)),
	\amp, 0.5
).play(quant: 4);
)

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
	\dur, Pseq([4, 8], inf),
).play(quant: 4)
)

(
SynthDef.new(\tom, {
	arg output = 0, amp = 0.1, clipamp = 2, freq = 100, peak = 50, decay = 1, curve = -20, gate = 1, pan = 0, degree;
	var env, snd, ampenv, clicky;

	pan = (degree / 7.0) - 0.5;

	env = EnvGen.ar(Env.perc(0.01, decay, 1, curve), doneAction: 0);

	snd = SinOsc.ar(freq + (env * peak), 0, 1);

	snd = snd * clipamp;
	snd = RLPF.ar(snd, freq * 2, 0.5);
	snd = snd.softclip * amp * env;

	Out.ar(output, Pan2.ar(snd, pan));
}
).add;
)

(
Pbindef(
	\tombind,
	\instrument, \tom,
	\octave, 5,
	\degree, Pseq([7, 7, 3, 3, \rest, 1, 1, \rest, 0, 0], inf),
	\dur, Pseq([3, 3, 2], inf) * 1/4,
	\amp, 0.05
).play(quant: 4);
)

(
SynthDef.new(\cymbal, {
	arg output = 0, amp = 0.1, decay = 2.5, curve = -10, width = 0.5, pan = 0.5;
	var e1, e2, snd;

	e1 = EnvGen.ar(Env.perc(0.01, decay), doneAction: 2);
	e2 = EnvGen.ar(Env.perc(0.01, decay / 2), doneAction: 0);

	snd = Mix.fill(6, {
		Pulse.ar(rrand(200, 800), width, 1 / 6)
	});

	snd = HPF.ar(snd, 3000, 0.5) * e1 * amp;
	snd = HPF.ar(snd, 5000, 0.5) * e2 * amp;

	Out.ar(output, Pan2.ar(snd, pan));
}).add;
)

(
Pbindef(
	\cymbalbind,
	\instrument, \cymbal,
	\dur, 1,
	\amp, 0.4
).play(quant: 4)
)

(
SynthDef.new(\clave, {
	arg output = 0, amp = 0.01, decay = 0.05, curve = -10, width = 0.5, pan = -1, freq = 220, rev = 2;
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
	\dur, 1,
	\amp, Pseq([0, 0.1], inf),
).play(quant: 4)
)



