(
SynthDef.new(\klank, {
	arg out = 0, freq = 440, amp = 1, gate = 1, pan = 0, mratio = 1.5, dur, delta, durmult = 10;
	var sig, freqs, amps, ringtimes, coll, size = 10;
	coll = (0..(size-1));
	freqs = coll * mratio + 1 * freq;
	amps = Array.fill(coll.size, {ExpRand(0.1, 100.0)}).normalizeSum;
	ringtimes = coll.reverse.normalize + 0.1 * dur * 10;
	sig = DynKlank.ar(`[freqs, amps, ringtimes], Impulse.ar(0), 1, 0) * amp / size;
	sig = sig * EnvGen.ar(Env.perc(releaseTime: dur * durmult, curve: {Rand(-25, -4)}), gate, doneAction: 2);
	sig = Pan2.ar(sig, pan);
	Out.ar(out, sig);
}).add;

Pbindef(
	\klanky,
	\instrument, \klank,
	\degree, 0,
	\dur, Pn(Pgeom(0.1, 1.3, 8)),
	\octave, Pwhite(2, 6),
	\mratio, Prand([1.0, 1.25, 1.5, 2], inf) * Pwhite(0.98, 1.02),
	\amp, Pwhite(0.1, 0.5, inf) * 10,
	\pan, Pwhite(-1.0, 1.0),
	\out, 20
).play;

Ndef(\verb, {
	arg in = 20, time = 0.4, wet = 0.05, damp = 0.6;
	var snd;

	snd = InFeedback.ar(20, 2);
	snd = MiVerb.ar(snd, time, wet, damp);
	Out.ar(0, snd);
}).play(numChannels: 2);
)



























