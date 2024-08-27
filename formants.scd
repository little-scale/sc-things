s.options.numWireBufs = 4096;
s.options.memSize = 8192 * 32;

(
// Formant data
// Formant table: https://www.classes.cs.uchicago.edu/archive/1999/spring/CS295/Computing_Resources/Csound/CsManual3.48b1.HTML/Appendices/table3.html
// As a spreadsheet: https://docs.google.com/spreadsheets/d/1UYqeo9j7U2jEF3q5pkiT8j1HIMVRzXV3fYH9pG1yV54/edit?usp=sharing

~soprano_freq = [800, 1150, 2900, 3900, 4950, 350, 2000, 2800, 3600, 4950, 270, 2140, 2950, 3900, 4950, 450, 800, 2830, 3800, 4950, 325, 700, 2700, 3800, 4950];
~soprano_amp = [0, -6, -32, -20, -50, 0, -20, -15, -40, -56, 0, -12, -26, -26, -44, 0, -11, -22, -22, -50, 0, -16, -35, -40, -60].dbamp;
~soprano_bw = [80, 90, 120, 130, 140, 60, 100, 120, 150, 200, 60, 90, 100, 120, 120, 70, 80, 100, 130, 135, 50, 60, 170, 180, 200];

~alto_freq = [800, 1150, 2800, 3500, 4950, 400, 1600, 2700, 3300, 4950, 350, 1700, 2700, 3700, 4950, 450, 800, 2830, 3500, 4950, 325, 700, 2530, 3500, 4950];
~alto_amp = [0, -4, -20, -36, -60, 0, -24, -30, -35, -60, 0, -20, -30, -36, -60, 0, -9, -16, -28, -55, 0, -12, -30, -40, -64].dbamp;
~alto_bw = [80, 90, 120, 130, 140, 60, 80, 120, 150, 200, 50, 100, 120, 150, 200, 70, 80, 100, 130, 135, 50, 60, 170, 180, 200];

~countertenor_freq = [660, 1120, 2750, 3000, 3350, 440, 1800, 2700, 3000, 3300, 270, 1850, 2900, 3350, 3590, 430, 820, 2700, 3000, 3300, 370, 630, 2750, 3000, 3400];
~countertenor_amp = [0, -6, -23, -24, -38, 0, -14, -18, -20, -20, 0, -24, -24, -36, -36, 0, -10, -26, -22, -34, 0, -20, -23, -30, -34].dbamp;
~countertenor_bw = [80, 90, 120, 130, 140, 70, 80, 100, 120, 120, 40, 90, 100, 120, 120, 40, 80, 100, 120, 120, 40, 60, 100, 120, 120];

~tenor_freq = [650, 1080, 2650, 2900, 3250, 400, 1700, 2600, 3200, 3580, 290, 1870, 2800, 3250, 3540, 400, 800, 2600, 2800, 3000, 350, 600, 2700, 2900, 3300];
~tenor_amp = [0, -6, -7, -8, -22, 0, -14, -12, -14, -20, 0, -15, -18, -20, -30, 0, -10, -12, -12, -26, 0, -20, -17, -14, -26].dbamp;
~tenor_bw = [80, 90, 120, 130, 140, 70, 80, 100, 120, 120, 40, 90, 100, 120, 120, 40, 80, 100, 120, 120, 40, 60, 100, 120, 120];

~bass_freq = [600, 1040, 2250, 2450, 2750, 400, 1620, 2400, 2800, 3100, 250, 1750, 2600, 3050, 3340, 400, 750, 2400, 2600, 2900, 350, 600, 2400, 2675, 2950];
~bass_amp = [0, -7, -9, -9, -20, 0, -12, -9, -12, -18, 0, -30, -16, -22, -28, 0, -11, -21, -20, -40, 0, -20, -32, -28, -36].dbamp;
~bass_bw = [60, 70, 110, 120, 130, 40, 80, 100, 120, 120, 60, 90, 100, 120, 120, 40, 80, 100, 120, 120, 40, 80, 100, 120, 120];

~freqs = [~soprano_freq, ~alto_freq, ~countertenor_freq, ~tenor_freq, ~bass_freq];
~amps = [~soprano_amp, ~alto_amp, ~countertenor_amp, ~tenor_amp, ~bass_amp];
~bws = [~soprano_bw, ~alto_bw, ~countertenor_bw, ~tenor_bw, ~bass_bw];
)

(
// Formant synth
SynthDef.new(\vow, {
	arg voce = 0, vow = 0, amp = 0.5, rq = 0.1, lag_time = 0.1, freq = 50, dur, gate = 1, noi = 0.5, res_scale = 5, lfo_depth = 0.1, lfo_rate = 5, pan = 0;
	var snd, env, formants = 5, lfo;

	~formant_freq = Array2D.fromArray(5, 5, Select.kr(voce, ~freqs));
	~formant_amp = Array2D.fromArray(5, 5, Select.kr(voce, ~amps));
	~formant_bw = Array2D.fromArray(5, 5, Select.kr(voce, ~bws));

	lfo = SinOsc.ar(lfo_rate, 0, lfo_depth);
	freq = (freq.cpsmidi + lfo).midicps;
	snd = Impulse.ar(freq) + PinkNoise.ar(noi * amp);
	snd = LPF.ar(snd, 5000);
	snd = HPF.ar(snd, 110);

	snd= Array.fill(5, {
		arg index;
		var form_freq, form_bw, form_amp;

		form_freq = Lag.kr(Select.kr(vow, ~formant_freq.colAt(index)), lag_time);
		form_bw = Select.kr(vow, ~formant_bw.colAt(index)).reciprocal;
		form_amp = Select.kr(vow, ~formant_amp.colAt(index));
		Formlet.ar(snd, form_freq, 0.001, res_scale * form_bw, form_amp) * 5 * amp;
	});

	snd = Mix.ar(snd);
	env = EnvGen.ar(Env.adsr(sustainLevel: 0.5, curve: -10), gate, doneAction: 2);
	snd = snd * env * amp;
	snd = Pan2.ar(snd, pan);

	Out.ar(0, snd);
}).add;
)

(

// Formant playback
Pmono(
	\vow,
	\voce, 0, // 0 = soprano, 1 = alto, 2 = countertenor, 3 = tenor, 4 = bass
	\freq, 440,
	\vow, Pn(Pseries(0, 1, 5)), // 0 = a, 1 = e, 2 = i, 3 = o, 4 = u
	\dur, 3,
	\lag_time, 1,
	\pan, 0,
	\amp, 0.1
).play

)
