//NetAddr.langPort
fork{
(
(
SynthDef('granulator', {|
	bufnum, gate=1, out=0, amp=0.4,
	input1=4, input2=5, recGate=1,
	inAmp=1, outAmp=1, overlap=3, tFreq=20, tFreqMF=0, tFreqMD=0,
	rate=1, rateMF=0, rateMD=0,
	offset = 0, offsetMF=0, offsetMD=0|

	var input,env;
	var gDur, readPos, signal, writePos, drygrained, grained, balance;

	var t, bufFrames, bufRateScale;
	var buf, bufdur;

	var tFreqMod = {
		SinOsc.ar(tFreqMF, Rand(0.0,2pi)) * tFreqMD;
	};

	var rateMod = {
		SinOsc.ar(rateMF, Rand(0.0,2pi)).range(rateMD.neg, rateMD);
		// SinOsc.ar(rateMF, Rand(0.0,2pi)).range(0, rateMD);
	};

	var offsetMod = {
		SinOsc.ar(offsetMF, Rand(0.0,2pi)).range(0, offsetMD);
		// LFDNoise3.ar(offsetMF).range(0,offsetMD(0.0))
	};

	env = EnvGen.ar(Env.adsr(0.4,0.0,1.0, 1.0),gate, doneAction: 2);
	tFreq = tFreq + tFreqMod.dup;
	rate = rate - rateMod.dup;


	bufFrames = 2**16;
	buf = {LocalBuf(bufFrames).clear}!2;
	bufdur = BufDur.ir(buf);


	writePos = Phasor.ar( end: bufFrames );


	t = Impulse.ar(tFreq);


	readPos =
	writePos
	- 64 // looks like a controlblocksize ------ why?
	/ bufFrames
	- offset
	- offsetMod.dup;
	// readPos = readPos.clip( 0, bufFrames - 64 / bufFrames );

	readPos = Wrap.ar(readPos, 0, 1);

/*
	(
		offset * bufFrames + 64 / SampleRate.ir
	).poll(10, \delaytime);
*/

/*
				dur: overlap / tFreq,*/

	grained = GrainBufJ.ar(
		numChannels:1,
		loop: 1,
		trigger:t,
		dur: tFreq.reciprocal * overlap,
		sndbuf: buf,
		rate: rate,
		pos: readPos,
		interp: 4,
		pan: 0,
		envbufnum:-1
	);


	grained  = HPF.ar( grained, \grHpf.kr(40) );
	grained  = LPF.ar( grained, \grLpf.kr(15000) );




	//input = SoundIn.ar([input1,input1]) * inAmp * recGate;
	input = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0, loop: 1);

	// writing granulated + input back to grain buffer


	buf.do { |b i|

		BufWr.ar(grained[i] * \feedback.kr(0.3) + input, b, writePos)

		// RecordBuf has an option to overdub, might be of any use for big mess
		// RecordBuf.ar(
		// 	grained[i] * \feedback.kr(0.3) + input[i],
		// 	b,
		// 	recLevel: \recLevel.kr(1),
		// 	preLevel: \preLevel.kr(0),
		// );

	};

	drygrained = grained;
				//
				// 3.do{ d = 0.1 + 0.3.rand;
				// 	e = 2 + 5.rand;
				// grained = AllpassC.ar(grained, d, d, e, 0.8, grained * 0.6); };
				//
				// grained = drygrained + grained;
	grained = FreeVerb.ar(grained,room: 0.9, mix:0.2);
	signal = Mix([
		grained * \wet.kr(1),
		drygrained * \dry.kr(0.01)
	]) * outAmp;

	signal = signal * env * amp * 2;
	signal = Mix(signal);
				Out.ar(out, Pan2.ar(signal, SinOsc.kr(0.1).range(-0.8,-0.1)));
				Out.ar(out, Pan2.ar(PitchShift.ar(signal.tanh, 0.2, SinOsc.kr(0.01).range(0.88,0.99),LFNoise1.kr(0.4).range(0.15,0.6),LFNoise0.kr(0.2).range(0.1,0.5)), SinOsc.kr(0.15).range(0.8,0.1)));

				//Out.ar(out, [signal, PitchShift.ar(signal, 0.2, SinOsc.kr(0.01).range(0.91,0.99),0.1,0.1)] );

}).store;

SynthDef(\extreme_grainsampler, {|anaBus out amp=1 envbuf bufnum rate=1 transpose=1 freq realFreq dur=0.1 overlap=1 pos|
	var freqRatio, env, sig;
	//dur = In.kr(durBus, 1);
	freqRatio = (freq/realFreq);
	env = Osc1.ar(envbuf, dur*overlap);
				sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate*transpose,1,BufFrames.ir(bufnum)*pos,loop:1);
	sig = sig * env * amp * 4;
				Out.ar(out, Pan2.ar(sig, Rand(-0.3,0.3)) );
	//Out.ar(anaBus, sig);
}).store;



SynthDef(\grain_reverb, {
	arg out, gate = 1, roomsize = 100, revtime = 5, damping = 0.6, inputbw = 0.5, spread = 15, drylevel = 1, earlyreflevel = 0.1, taillevel = 0.125, maxroomsize = 300, amp = 1;
	var source = In.ar(out,2);
	var reverb;
	var env = Linen.kr(gate, 0.1, 1, 0.1, 2);


	reverb = GVerb.ar(source, roomsize, revtime, damping, inputbw, spread, drylevel, earlyreflevel, taillevel, maxroomsize);
	reverb = reverb * amp ;
	XOut.ar(out,env,reverb);

}).add;

);


~radio_files = "/home/numina/repos/electromagnetic_sensibility/Radio/*.wav".pathMatch;
~radio_samples = ~radio_files.collect{|i| Buffer.read(s, i); };

// a custom envelope
~winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
~window = Buffer.sendCollection(s, ~winenv.discretize, 1);

~otherenv = Buffer.sendCollection(s, Env.perc.discretize, 1);

SynthDef(\field_grain, { |out=0, gate = 1, amp = 0.4,posBus,bufnum, envbuf, trateBus durBus|
    var sig,sig1,sig2, pan, env, freqdev,trate, dur, pos;
			trate = In.kr(trateBus, 1);
			dur = In.kr(durBus, 1);
			pos = In.kr(posBus, 1);

    env = EnvGen.ar(
        Env([0, 1, 0], [1, 1], \sin, 1),
        gate,
        levelScale: amp,
        doneAction: Done.freeSelf);

/*	sig = GrainBuf.ar(2, Impulse.kr(trate), dur, bufnum, 1,
				pos * BufFrames.kr(bufnum), 2, FSinOsc.kr(LFNoise0.kr(0.2).range(0.01,80.0)).range(-0.1,0.1), envbuf);

			*/
		sig = GrainBuf.ar(1, Impulse.kr(trate), trate.reciprocal * dur, bufnum, 1,
				 BufFrames.ir(bufnum) * pos, 2, envbuf);

			//sig1 = PitchShift.ar(sig[0], 0.4,0.1, 0.2, 0.4, 0.5, sig[0]*0.5) * env;
			//sig2 = PitchShift.ar(sig[1], 0.4, 0.125, 0.2, 0.4, 0.5, sig[1]*0.5) * env;


			Out.ar(out, Pan2.ar(sig*amp*env,FSinOsc.kr(LFNoise0.kr(0.2).range(0.01,80.0)).range(-0.4,0.1)));
}).store;


//replace this tempoclock with the monome tempoclock
~grain_clock = 	TempoClock.new(1);
~graindur_bus = Bus.control(s, 1).set(0.1);


~nyquist = s.sampleRate * 0.5;

~modRange = [9.0, 0.001, \exp, 0.001].asSpec;
~ampRange = [0.25, 1.0, \linear, 0.001].asSpec;
~relRange = [0.1, 2.0, \linear, 0.001].asSpec;
~decRange = [0.001, 30.0, \exp, 0.001].asSpec;
~ratioSpec = [0, 15, \linear, 1].asSpec;

~ratios = [0.25,0.25,0.5,0.75,0.85,0.9,1,1.1,1.2,1.3,1.4,1.5,1.75,1.8,1.9,2.0];

~mainGroup = Group.new;
~fieldrecGroup = Group.new(~mainGroup);
~percGroup = Group.new(~mainGroup);
~granulatorGroup = Group.new(~mainGroup);
~percBus = Bus.audio(s, 1);


~combPerc = Synth(\perc_effect, [\in, ~percBus], ~percGroup, \addAfter);

~field_rec_files = "/home/numina/repos/chirp.crush_tour2023/AE_Samples/Stereo/*.wav".pathMatch;
~field_recs = ~field_rec_files.collect({|sample| Buffer.read(s, sample); });
~grainfield_rec_files = "/home/numina/repos/chirp.crush_tour2023/AE_Samples/Mono/*.wav".pathMatch;
~grainfield_recs = ~grainfield_rec_files.collect({|sample| Buffer.read(s, sample); });
~fieldsample_select = 0;

~recBufs = [ Buffer.alloc(s, 44100*5, 1), Buffer.alloc(s, 44100*5, 1); ];
~samNum1 = 0;
~fftbuf = Buffer.alloc(s, 1024,1);

~freezeSwitch = 0;
~fieldrecSwitch = ~field_recs.size - 1;
~fieldrecnum = 0;


~winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
~window = Buffer.sendCollection(s, ~winenv.discretize, 1);


);
(

/*    LOGITECH DUAL ACTION MAPPING */
/* main buttons */
~fmSwitch = 0;


	~sdr_fft = Buffer.alloc(s, 512, 1);
	~sdr_rec_buf = Buffer.alloc(s, s.sampleRate*4, 1);
	2.0.wait;
	~sdr_rec = Synth(\zitarRecorder, [\in, 4, \fftbuf, ~sdr_fft, \recbuf, ~sdr_rec_buf]);


~bangGates = Array.fill(16, { 0});

OSCdef(\btn_0, {|msg, time, addr, recvPort|
			var value = msg[1];
			value.postln;
		if ( ~bangGates[0] == 0, {

			~bangGates.put(0, 1);
				if ( (msg[1] == 1) or: (msg[1] == 0), {
					"btn 0".postln;
					msg.postln;

				if ( ~freezeSwitch == 0, {
						if ( value == 1, {



				Synth(\granulator, [\bufnum, ~sample_choose], ~granulatorGroup);
				//Synth(\fm7, [\gate,1], ~fm1Group);





							}, { ~granulatorGroup.set(\gate, 0); });

		});


				});

				Task({ 1.do{  0.1.wait; ~bangGates.put(0, 0); }; }).start;
			});

}, '/btn_0', nil);


~grain_routine_switch = 0;
		~grainclock_spec = [0.2, 50.0, \exp, 0.01].asSpec;
		~grain_dur_spec = [5.0, 0.02, \exp, 0.01].asSpec;
		~grain_pos_spec =[0.0,0.9,\linear, 0.001].asSpec;
		~grain_rate_spec =[-1.0,3,\linear, 0.1].asSpec;

		~grain_dur = 0.1;
		~grain_pos = 0;
		~grain_rate = 1;

		~second_grain_gate = 0;
		~third_grain_gate = 0;


~grains_group = Group.new;
~grains2_transpose = 1.2;
~grains3_transpose = 1.3;

~grains2_transpose_spec = [1.1, 2.5, -4, 0.1].asSpec;
~grains3_transpose_spec = [1.05, 2.5, -4, 0.1].asSpec;


~grain_bus = Bus.audio(s, 2);
~grain_verb = Synth(\grain_reverb, [\out, ~grain_bus], ~grains_group, \addAfter);

~sample_choose = ~grainfield_recs[~fieldrecnum];
		~sample_choose = ~grainfield_recs[4];
Ndef(\mixer, {

			var sig = In.ar(~grain_bus, 2);
			Out.ar(0, sig);

		});

OSCdef(\btn_1, {|msg, time, addr, recvPort|
		var value = msg[1];
		value.postln;

		if ( ~bangGates[1] == 0, {

			~bangGates.put(1, 1);
					if ( (msg[1] == 1) or: (msg[1] == 0), {
					"btn 1".postln;
					if ( value == 1, {

						case { ~grain_routine_switch == 0 } {

							"play grain routine".postln;

						~grain_routine =
						Routine({ inf.do{
							Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate, \dur, ~grain_dur, \pos, ~grain_pos ], ~grains_group);
								0.25.wait;
						if ( ~second_grain_gate == 1, {
									Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains2_transpose, \dur, ~grain_dur,\overlap, 1.1, \pos, ~grain_pos ], ~grains_group);
								0.125.wait;
								Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains2_transpose, \dur, ~grain_dur,\overlap, 1.1, \pos, ~grain_pos ], ~grains_group);
								0.125.wait;
								});
						if ( ~third_grain_gate == 1, {
									Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains3_transpose, \dur, ~grain_dur,\overlap, 0.9, \pos, ~grain_pos ], ~grains_group);
								0.0625.wait;
									Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains3_transpose, \dur, ~grain_dur,\overlap, 0.9, \pos, ~grain_pos ], ~grains_group);
								0.0625.wait;
									Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains3_transpose, \dur, ~grain_dur,\overlap, 0.9, \pos, ~grain_pos ], ~grains_group);
								0.0625.wait;
									Synth(\extreme_grainsampler, [\out, ~grain_bus, \envbuf, ~otherenv, \amp, 0.75, \bufnum,~sample_choose,
									\rate, ~grain_rate,\transpose, ~grains3_transpose, \dur, ~grain_dur,\overlap, 0.9, \pos, ~grain_pos ], ~grains_group);
								0.0625.wait;
								});


							}; }).play(~grain_clock);
							~grain_routine_switch = 1;
						}
						{ ~grain_routine_switch == 1 }  { ~grain_routine.stop; ~grain_routine_switch = 0; 	"stop grain routine".postln; };





					});
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(1, 0); }; }).start;
			});

}, '/btn_1', nil);


OSCdef(\btn_2, {|msg, time, addr, recvPort|

		if ( ~bangGates[2] == 0, {

			~bangGates.put(2, 1);
		if ( msg[1] == 1, {
					"btn 2".postln;

		if ( ~fieldrecnum == (~field_recs.size-1), { ~fieldrecnum = 0; }, { ~fieldrecnum = ~fieldrecnum + 1; });
					~granulatorGroup.set(\bufnum, ~field_recs[~fieldrecnum]);
					~sample_choose = ~grainfield_recs[~fieldrecnum];
					("fieldrec sample: "++~fieldrecnum).postln;

				});

				Task({ 1.do{  0.2.wait; ~bangGates.put(2, 0); }; }).start;
			});

}, '/btn_2', nil);

OSCdef(\btn_3, {|msg, time, addr, recvPort|

		if ( ~bangGates[3] == 0, {

			~bangGates.put(3, 1);
		if ( msg[1] == 1, {
					"btn 3".postln;
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(3, 0); }; }).start;
			});

}, '/btn_3', nil);


OSCdef(\btn_4, {|msg, time, addr, recvPort|

		if ( ~bangGates[4] == 0, {

			~bangGates.put(4, 1);
		if ( msg[1] == 1, {
					//"btn 4".postln;

		if ( ~fmSwitch != 1, { ~fmSwitch = ~fmSwitch + 1; },
		{
			~fmSwitch = 0;

	});
	("fm synth : "++~fmSwitch).postln;
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(4, 0); }; }).start;
			});

}, '/btn_4', nil);

OSCdef(\btn_5, {|msg, time, addr, recvPort|
			var value = msg[1];
		if ( ~bangGates[5] == 0, {

			~bangGates.put(5, 1);
		if ( msg[1] == 1, {
					"btn 5".postln;
					if ( value == 1, {
		if ( ~freezeSwitch == 0, { ~freezeSwitch = 1; "frozen".postln; }, { ~freezeSwitch = 0; "unfrozen".postln; });
	});
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(5, 0); }; }).start;
			});

}, '/btn_5', nil);

OSCdef(\btn_6, {|msg, time, addr, recvPort|

		if ( ~bangGates[6] == 0, {

			~bangGates.put(6, 1);
		if ( msg[1] == 1, {

					if ( ~second_grain_gate == 0, { ~second_grain_gate = 1; }, {
						~second_grain_gate = 0; });
					("second grain gate : "++~second_grain_gate).postln;
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(6, 0); }; }).start;
			});

}, '/btn_6', nil);

OSCdef(\btn_7, {|msg, time, addr, recvPort|

		if ( ~bangGates[7] == 0, {

			~bangGates.put(7, 1);
		if ( msg[1] == 1, {

					if ( ~third_grain_gate == 0, { ~third_grain_gate = 1; }, {
						~third_grain_gate = 0; });
					("third grain gate : "++~third_grain_gate).postln;
				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(7, 0); }; }).start;
			});

}, '/btn_7', nil);


~extreme3d_mapping_state = 0;

OSCdef(\btn_8, {|msg, time, addr, recvPort|

		if ( ~bangGates[8] == 0, {

			~bangGates.put(8, 1);
		if ( msg[1] == 1, {
					("extreme3d_mapping state : "++~extreme3d_mapping_state).postln;
					if ( ~extreme3d_mapping_state != 3, { ~extreme3d_mapping_state = ~extreme3d_mapping_state + 1; },
						{ ~extreme3d_mapping_state = 0; });

					case
					/* STATE 0 */
					{ ~extreme3d_mapping_state == 0 } {

						OSCdef(\abs_x, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);

							if ( ~freezeSwitch == 0, {

								~granulatorGroup.set(\tFreq,~tFreq_spec.map(value), \overlap,~overlap_spec.map(value) );
								~grain_pos = ~grain_pos_spec.map(value);


							});

						}, '/abs_x', nil);

						OSCdef(\abs_y, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);
							//msg[1].postln;

							if ( ~freezeSwitch == 0, {

								~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(value).postln, \rateMD, ~rateMD_spec.map(value).postln );

								~grain_clock.tempo = ~grainclock_spec.map(value);
								~grain_dur = ~grain_dur_spec.map(value);


							});

						}  , '/abs_y', nil);


						OSCdef(\abs_rz, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);
							//msg.postln;

							if ( ~freezeSwitch == 0, {

								~granulatorGroup.set(\feedback, ~fb_spec.map(value),\tFreqMD,~tFreqMD_spec.map(value),\rate,~rate_spec.map(value));
								~grain_rate = ~grain_rate_spec.map(value);
							});

						}, '/abs_rz', nil);


						OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);

							~granulatorGroup.set(\wet, value, \dry, 1 - value);

							~grains2_transpose = ~grains2_transpose_spec.map(value);
							~grains3_transpose = ~grains3_transpose_spec.map(value);


						}, '/abs_throttle', nil);

					}

					/*STATE 1 */
					{ ~extreme3d_mapping_state == 1 } {

					OSCdef(\abs_x, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);

							if ( ~freezeSwitch == 0, {

								~grains2_transpose = ~grains2_transpose_spec.map(value);
								~grains3_transpose = ~grains3_transpose_spec.map(value);

								~granulatorGroup.set(\feedback, ~fb_spec.map(value),\tFreqMD,~tFreqMD_spec.map(value),\rate,~rate_spec.map(value));
								~grain_rate = ~grain_rate_spec.map(value);
							});





						}, '/abs_x', nil);

						OSCdef(\abs_y, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);
							//msg[1].postln;

							if ( ~freezeSwitch == 0, {


								~granulatorGroup.set(\tFreq,~tFreq_spec.map(value), \overlap,~overlap_spec.map(value) );
								~grain_pos = ~grain_pos_spec.map(value);



							});

						}  , '/abs_y', nil);


						OSCdef(\abs_rz, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);
							//msg.postln;

							if ( ~freezeSwitch == 0, {

								~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(value).postln, \rateMD, ~rateMD_spec.map(value).postln );

								~grain_clock.tempo = ~grainclock_spec.map(value);
								~grain_dur = ~grain_dur_spec.map(value);
									});



						}, '/abs_rz', nil);


						OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);

							~granulatorGroup.set(\wet, value, \dry, 1 - value);



						}, '/abs_throttle', nil);


					}
					{ ~extreme3d_mapping_state == 2 } {

					OSCdef(\abs_x, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);

							if ( ~freezeSwitch == 0, {
								~granulatorGroup.set(\wet, value, \dry, 1 - value);
								~grain_rate = ~grain_rate_spec.map(value);

							});





						}, '/abs_x', nil);

						OSCdef(\abs_y, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);
							//msg[1].postln;

							if ( ~freezeSwitch == 0, {

								~grains2_transpose = ~grains2_transpose_spec.map(value);
								~grains3_transpose = ~grains3_transpose_spec.map(value);

								~granulatorGroup.set(\feedback, ~fb_spec.map(value),\tFreqMD,~tFreqMD_spec.map(value),\rate,~rate_spec.map(value));







							});

						}  , '/abs_y', nil);


						OSCdef(\abs_rz, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);
							//msg.postln;

							if ( ~freezeSwitch == 0, {

									~granulatorGroup.set(\tFreq,~tFreq_spec.map(value), \overlap,~overlap_spec.map(value) );
								~grain_pos = ~grain_pos_spec.map(value);


									});



						}, '/abs_rz', nil);


						OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);



							~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(value).postln, \rateMD, ~rateMD_spec.map(value).postln );

								~grain_clock.tempo = ~grainclock_spec.map(value);
								~grain_dur = ~grain_dur_spec.map(value);



						}, '/abs_throttle', nil);

					}
					{ ~extreme3d_mapping_state == 3 } {

						OSCdef(\abs_x, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);

							if ( ~freezeSwitch == 0, {
								~granulatorGroup.set(\wet, value, \dry, 1 - value);
								~grain_rate = ~grain_rate_spec.map(value);

							});





						}, '/abs_x', nil);

						OSCdef(\abs_y, {|msg, time, addr, recvPort|
							var value = (msg[1]/1021);
							//msg[1].postln;

							if ( ~freezeSwitch == 0, {


								~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(value).postln, \rateMD, ~rateMD_spec.map(value).postln );




							});

						}  , '/abs_y', nil);


						OSCdef(\abs_rz, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);
							//msg.postln;

							if ( ~freezeSwitch == 0, {

									~granulatorGroup.set(\feedback, ~fb_spec.map(value),\tFreqMD,~tFreqMD_spec.map(value),\rate,~rate_spec.map(value));

									~grain_clock.tempo = ~grainclock_spec.map(value);
								~grain_dur = ~grain_dur_spec.map(value);



									});



						}, '/abs_rz', nil);


						OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
							var value = (msg[1]/255);




								~granulatorGroup.set(\tFreq,~tFreq_spec.map(value), \overlap,~overlap_spec.map(value) );



							~grain_pos = ~grain_pos_spec.map(value);

								~grains2_transpose = ~grains2_transpose_spec.map(value);
								~grains3_transpose = ~grains3_transpose_spec.map(value);



						}, '/abs_throttle', nil);

					};




				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(8, 0); }; }).start;
			});

}, '/btn_8', nil);

/*button for sample switching */

~sample_switch = 0;
~sample_choose = ~grainfield_recs[~fieldrecnum];

		OSCdef(\btn_9, {|msg, time, addr, recvPort|
			//"btn9".postln;
		if ( ~bangGates[9] == 0, {
				"bang gate true".postln;

			~bangGates.put(9, 1);
		if ( msg[1] == 1, {

					if ( ~sample_switch != 2, { ~sample_switch = ~sample_switch + 1; }, {
						~sample_switch = 0; });
					("sample switch : "++~sample_switch).postln;

					case
					{ ~sample_switch == 0 } { "grainfield recs".postln;
						~sample_choose = ~grainfield_recs[~fieldrecnum];
					}
					{ ~sample_switch == 1 } { "rec bufs".postln;
						~sample_choose = ~firstgeneration_grainsample1;


					}
					{ ~sample_switch == 2 } { "random radio samples".postln;
						~sample_choose = ~radio_samples.choose;
					};


				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(9, 0); }; }).start;
			});

}, '/btn_9', nil);


~control_data_gate = 0;

OSCdef(\btn_10, {|msg, time, addr, recvPort|
			//"btn9".postln;
		if ( ~bangGates[10] == 0, {
				//"bang gate true".postln;

			~bangGates.put(10, 1);
		if ( msg[1] == 1, {
					if ( ~control_data_gate == 0, { ~control_data_gate = 1; "recording control data gate OPEN".postln; },
						{ ~control_data_gate = 0; "recording control data gate CLOSED".postln; });




				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(10, 0); }; }).start;
			});

}, '/btn_10', nil);


~play_control_data_gate = 0;

OSCdef(\btn_11, {|msg, time, addr, recvPort|
			//"btn9".postln;
		if ( ~bangGates[11] == 0, {
				//"bang gate true".postln;

			~bangGates.put(11, 1);
		if ( msg[1] == 1, {
					if ( ~play_control_data_gate == 0, { ~play_control_data_gate = 1; "play control data gate OPEN".postln; },
						{ ~play_control_data_gate = 0; "play control data gate CLOSED".postln; });




				});

				Task({ 1.do{  0.4.wait; ~bangGates.put(11, 0); }; }).start;
			});

}, '/btn_11', nil);


	~fr_trateBus = Bus.control(s, 1).set(1);
	~fr_durBus = Bus.control(s, 1).set(1.0);
	~fr_posBus = Bus.control(s, 1).set(0.0);


	~fr_trateRange = [1.5, 250, 4,0.001].asSpec;
	~fr_durRange = [5.0, 0.5, 1,0.001].asSpec;
	~fr_posRange = [0.0, 0.9, \linear,0.001].asSpec;


		~fb_spec = [-0.1, 0.1, \linear, 0.001].asSpec;
		~tFreq_spec = [10, 4000, -2, 0.1].asSpec;
		~overlap_spec = [8.5,0.01, -2, 0.01].asSpec;
		~offsetmf_spec = \widefreq.asSpec;
		~offsetMD_spec = [0.0,0.1,\linear,0.1].asSpec;
		~rateMD_spec = [0.0,0.75,\linear,0.1].asSpec;
		~rate_spec = [0.5,2.5,\linear,0.1].asSpec;
		~tFreqMF_spec = [30.0,5.0, \linear, 0.1].asSpec;
		~tFreqMD_spec = [150,250, \linear, 0.1].asSpec;

// controller record setup
~control_data_busses = Array.fill(4, { Bus.control(s, 1); });
~control_data_arrays = Array.fill(4, { Array.fill(100, { 0 }); });
~control_data_rec_gates = [0, 0, 0, 0];




OSCdef(\abs_x, {|msg, time, addr, recvPort|
	var value = (msg[1]/1021);
	~control_data_busses[0].set(value);

	if ( ~freezeSwitch == 0, {
		~fmGroup.set(\mod1, ~modRange.map(value));
		~fr_posBus.set(~fr_posRange.map(value); );

				~granulatorGroup.set(\tFreq,~tFreq_spec.map(value), \overlap,~overlap_spec.map(value) );
				~grain_pos = ~grain_pos_spec.map(value);


	});

}, '/abs_x', nil);

OSCdef(\abs_y, {|msg, time, addr, recvPort|
			var value = (msg[1]/1021);
			~control_data_busses[1].set(value);
			//msg[1].postln;

	if ( ~freezeSwitch == 0, {

		~fr_trateBus.set(~fr_trateRange.map(value); );

		~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(value), \rateMD, ~rateMD_spec.map(value) );

		~grain_clock.tempo = ~grainclock_spec.map(value);
		~grain_dur = ~grain_dur_spec.map(value);


	});

	}  , '/abs_y', nil);


OSCdef(\abs_rz, {|msg, time, addr, recvPort|
	var value = (msg[1]/255);
	~control_data_busses[2].set(value);
	//msg.postln;

	if ( ~freezeSwitch == 0, {
		~fmGroup.set(\mod3, ~modRange.map(value));
				~granulatorGroup.set(\feedback, ~fb_spec.map(value),\tFreqMD,~tFreqMD_spec.map(value),\rate,~rate_spec.map(value));
				~grain_rate = ~grain_rate_spec.map(value);
	});

	}, '/abs_rz', nil);


		~abs_throttle_bus = Bus.control(s, 1).set(50);

OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
	var value = (msg[1]/255);
	~control_data_busses[3].set(value);
	~granulatorGroup.set(\wet, value, \dry, 1 - value);

	~grains2_transpose = ~grains2_transpose_spec.map(value);
	~grains3_transpose = ~grains3_transpose_spec.map(value);



	}, '/abs_throttle', nil);


);



/*
// test routine
r = Routine({ 60.do{ ~abs_throttle_bus.set(rrand(-600.0, 30000.0); ); 0.05.wait; }; }).play;
~data_record_routine.stop;
*/
~data_record_routine = Routine({ var data0, prev_data0, data1, prev_data1, data2, prev_data2, data3, prev_data3;
		inf.do{|i|
			//i.postln;
			if ( i > 2, {


			if ( ~control_data_gate == 1, {

					if ( prev_data0 != data0 , {
					if ( ~control_data_rec_gates[0] != 1, {
					"abs x recording for 10 seconds".postln;
					~control_data_rec_gates[0] = 1;~control_data_rec_gates[3] = 0;
					Routine({ 100.do{|j| ~control_data_arrays[0].put(j, data0); 0.1.wait;
					if ( j == 99, { "finished abs x recording".postln; ~control_data_rec_gates[0] = 0; };) }; }).play;
					});
					});


					if ( prev_data1 != data1 , {
					if ( ~control_data_rec_gates[1] != 1, {
					"abs y recording for 10 seconds".postln;
					~control_data_rec_gates[1] = 1;
					Routine({ 100.do{|j| ~control_data_arrays[1].put(j, data1); 0.1.wait;
					if ( j == 99, { "finished abs y recording".postln; ~control_data_rec_gates[1] = 0; };) }; }).play;
					});
					});

					if ( prev_data2 != data2 , {
					if ( ~control_data_rec_gates[2] != 1, {
					"abs rz recording for 10 seconds".postln;
					~control_data_rec_gates[2] = 1;
					Routine({ 100.do{|j| ~control_data_arrays[2].put(j, data2); 0.1.wait;
					if ( j == 99, { "finished abs rz recording".postln; ~control_data_rec_gates[2] = 0; };) }; }).play;
					});
					});

					if ( prev_data3 != data3 , {
					if ( ~control_data_rec_gates[3] != 1, {
					"throttle recording for 10 seconds".postln;
					~control_data_rec_gates[3] = 1;
					Routine({ 100.do{|j| ~control_data_arrays[3].put(j, data3); 0.1.wait;
					if ( j == 99, { "finished throttle recording".postln; ~control_data_rec_gates[3] = 0; };) }; }).play;
						});
					});

				});
			});

			prev_data0 = data0;
			~control_data_busses[0].get({|val| data0 = val; });

			prev_data1 = data1;
			~control_data_busses[1].get({|val| data1 = val; });

			prev_data2 = data2;
			~control_data_busses[2].get({|val| data2 = val; });

			prev_data3 = data3;
			~control_data_busses[3].get({|val| data3 = val; });
			//("data : "++data).postln;
			//("prev_data : "++prev_data).postln;
		0.1.wait;
		};
	}).play;


~play_data_switch = 0;

~play_data_routine = Routine({

		inf.do{|i|
			if ( ~play_control_data_gate == 1, {
				if ( ~play_data_switch == 0, {
					"playing data".postln;


					~control_play_routine = Routine({ inf.do{ 100.do{|j|



						~grain_clock.tempo = ~grainclock_spec.map( ~control_data_arrays[0][j];);
						~grain_dur = ~grain_dur_spec.map( ~control_data_arrays[0][j];);
						~grain_pos = ~grain_pos_spec.map( ~control_data_arrays[1][j]; );

						~grain_rate = ~grain_rate_spec.map(~control_data_arrays[2][j];);
						~grains2_transpose = ~grains2_transpose_spec.map(~control_data_arrays[2][j]; );
						~grains3_transpose = ~grains3_transpose_spec.map(~control_data_arrays[2][j]; );

						~granulatorGroup.set(\tFreq,~tFreq_spec.map(~control_data_arrays[1][j]), \overlap,~overlap_spec.map(~control_data_arrays[1][j]) );
						~granulatorGroup.set(\tFreqMF,~tFreqMF_spec.map(~control_data_arrays[0][j]), \rateMD, ~rateMD_spec.map(~control_data_arrays[0][j];) );
					    ~granulatorGroup.set(\feedback, ~fb_spec.map(~control_data_arrays[2][j]),
						\tFreqMD,~tFreqMD_spec.map(~control_data_arrays[2][j]),\rate,~rate_spec.map(~control_data_arrays[2][j]));

						0.1.wait; }; }; }).play;
					~play_data_switch = 1;
				});
			},
			{
			if ( ~play_data_switch == 1, {
				"stop playing data".postln;
					~control_play_routine.stop;
					~play_data_switch = 0;

			});

			});
			0.01.wait; };
	}).play;



/*
(
//control for recording
y = MIDIdef.cc(\cc_record,{
	arg vel, note, ch, src;
	"record".postln;
	~recordControl[~playhead] = [vel,note,ch];
});
//set up a 2d array, if the entry is [-1], then there is no playback for this index
~recordControl = [[-1]];
~playhead = 0;
r = Routine({{
	~recordControl = ~recordControl ++ [[-1]];
	~playhead= ~playhead+1;
	~playhead.postln;
	~wait.wait;
}.loop}).play;
)
*/








};




