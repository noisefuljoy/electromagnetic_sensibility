/*
knop om monome ritmes plotseling superkort te maken en er dan langere synth klanken overheen te leggen
elektromagnetische kick

Server.default.makeGui

make the ensemble aleatoric
https://www.youtube.com/watch?v=jkuHFoWPJug&t=1191s
routines gebruiken binnen


different scenes
joystick gebruiken voor field recordings
kanalen 0, 1 monome, radio
kanalen 2, 3 joystick, field recordings
mixer


hydrophone
insect landscape - digital insects | electromagnetic sounds

niet alle samples tegelijkertijd veranderen maar "faden" -> task met timer gekoppeld aan tempoclock
field recordings ook met een bepaalde verhouding aan die clock hangen?

scene met diversified samples over monome

tuning switcher

*/
// polyrhytmic

(

fork{

	/* CHECK THIS ONE */
~footpedal_srcid = 8388608;

~radio_files = "/home/numina/repos/electromagnetic_sensibility/Radio/*.wav".pathMatch;
~radio_samples = ~radio_files.collect{|i| Buffer.read(s, i); };

// SynthDef shared by all voices:

b = Buffer.sendCollection(s, { 1.0.rand }!1024);

/*
SynthDef(\minilogue, {|out=0 amp=0.25 freq=440 dur=0.25 rel=0.1 widthMod=0.01 res=0.1 gate=1|
	var env,filtEnv,sig,fm_mod1,fm_mod2,fm_mod3;
	//gate = EnvGen.kr(Env([1,0],[dur+rel],1));
	env = EnvGen.ar(Env.adsr(dur/4,dur/8,0.5,rel),gate,doneAction:2);

	fm_mod1 = SinOsc.ar(freq * (4/3) ) * freq * Rand(1,5);
	fm_mod2 = SinOsc.ar(freq * (5/4) ) * freq * Rand(1,15);.
	fm_mod3 = SinOsc.ar(freq * (2/1) ) * freq * Rand(1,20);

	sig = Mix(Pulse.ar([(freq*0.499)+fm_mod1,freq+fm_mod2,(freq*2.02)+fm_mod3],LFNoise2.kr(widthMod).range(0.1,0.95),0.33));
	filtEnv = EnvGen.ar(Env.adsr(dur/2,dur/3,0.5,rel*0.75),gate,doneAction:0);
	sig = MoogVCF.ar(sig, Rand(1000,8000)*filtEnv, res,3);
	Out.ar(out, sig*amp*env) }).add;
*/




SynthDef(\em_kick,
	{ arg out = 0, freq = 50, mod_freq = 5, mod_index = 5, sustain = 0.4, amp = 0.8, beater_noise_level = 0.05;
	var pitch_contour, drum_osc, drum_lpf, drum_env;
	var beater_source, beater_hpf, beater_lpf, lpf_cutoff_contour, beater_env;
	var kick_mix;
	pitch_contour = Line.kr(freq*2, freq, 0.02);
	drum_osc = PMOsc.ar(	pitch_contour,
				mod_freq,
				mod_index/1.3,
				mul: 1,
				add: 0);
	drum_lpf = LPF.ar(in: drum_osc, freq: 1000, mul: 1, add: 0);
	drum_env = drum_lpf * EnvGen.ar(Env.perc(0.005, sustain), 1.0, doneAction: 2);
	beater_source = WhiteNoise.ar(beater_noise_level);
	beater_hpf = HPF.ar(in: beater_source, freq: 500, mul: 1, add: 0);
	lpf_cutoff_contour = Line.kr(6000, 500, 0.03);
	beater_lpf = LPF.ar(in: beater_hpf, freq: lpf_cutoff_contour, mul: 1, add: 0);
	beater_env = beater_lpf * EnvGen.ar(Env.perc, 1.0, doneAction: 2);
	kick_mix = Mix.new([drum_env, beater_env]) * 1.25 * amp;
	Out.ar(out, [kick_mix, kick_mix])
	}
	).store;

SynthDef(\minilogue, {|out1 out2 amp=0.0 gate=1 gate2=1 freq=110 index=0.1|
		var t_env,env,f_env, modfreq,sig,sig2;
		t_env = EnvGen.kr(Env.adsr(0.001,0.0,1,0.00001),gate2);
		env = EnvGen.ar(Env.adsr(5.0,0.0,1,Rand(6.0,9.0)),gate,doneAction: 2);
		f_env = EnvGen.kr(Env.adsr(5.0,0.0,1,6.0),gate,doneAction: 0);
		modfreq = SinOsc.ar(freq*(4/3)) * freq * index;
		sig = SinOsc.ar(freq+modfreq, 0, 0.75);
		//sig = VarSaw.ar(freq+modfreq, 0,0.9, 0.1);
		sig = Gate.ar(sig, gate2);
		//sig = HPF.ar(sig * env, freq: freq * 0.5);
		sig = BMoog.ar(sig, f_env*(freq*2),0.3,1,0.8,0.5);
		sig2 = PitchShift.ar(sig, 0.2,Rand(1.05,1.15),Rand(0.01,0.2),Rand(0.0,0.15));
		Out.ar(out1, sig*amp*env);
		Out.ar(out2, sig2*amp*env);
	}).store;


SynthDef(\aether_whitenoise, {|out=0 bfreq=440 gate=1|

	var env, filtenv, base_sig, sig1, sig2;
	filtenv = EnvGen.kr(Env.adsr(4.0,0.0,1.0,20.0), gate);
	env = EnvGen.ar(Env.adsr(6.0,0.0,1.0,20.0),gate, doneAction: 2);
	base_sig = WhiteNoise.ar(0.01);
	sig1 = BMoog.ar(base_sig, SinOsc.kr(LFNoise0.kr(0.3).range(0.001,0.1)).range(4000,9000),0.4, 0, 0.8);
	sig1 = BBandPass.ar(sig1, SinOsc.kr(0.05).range(bfreq, bfreq*1.5), 8.0);
	sig1 = BLPF.ar(sig1, 4, bfreq*2.8);
	sig1 = (CombN.ar(sig1, 0.4, 0.4,2) * 0.4) + (sig1 * 0.5);
	sig2 = BMoog.ar(base_sig, SinOsc.kr(LFNoise0.kr(0.2).range(0.001,0.075)).range(3200,9500),0.4, 0, 0.8);
	sig2 = BBandPass.ar(sig2, SinOsc.kr(0.025).range(bfreq*0.9, bfreq*1.75), 9.0);
	sig2 = BLPF.ar(sig2, 4, bfreq*3.2);
	sig2 = (CombN.ar(sig2, 0.4, 0.35,3.5) * 0.4) + (sig2 * 0.5);
		sig1 = BMoog.ar(sig1, (filtenv*9000)+60, 0.1,0,0.4);
		sig2 = BMoog.ar(sig2, (filtenv*9200)+60, 0.15,0,0.3);
		Out.ar(out, Pan2.ar(sig1, SinOsc.kr(LFNoise2.kr(0.3).range(0.01,0.1)).range(-0.8,0.1)));
		Out.ar(out, Pan2.ar(sig2, SinOsc.kr(LFNoise2.kr(0.4).range(0.001,0.05)).range(0.8,-0.1)));


}).store;


/*
SynthDef(\mini_delay, {|in deltime amp=1 decay=5 out|
		var drysig, sig;
		sig = In.ar(in, 1);
		drysig = sig;
		3.do{|i|
			d = 0.01 + 0.2.rand;
			sig = AllpassC.ar(sig, d, d, decay+(i+1), 2, sig*0.9); };
		sig = (drysig*0.1) + (sig * 1);
		Out.ar(out, Pan2.ar(sig*amp,0)); }).store;
*/
SynthDef(\mini_delay, {|in out=0 delmod=0.001 dec=8 mix=0.25 pan=0|
		var sig,delsig;
		sig = In.ar(in, 1);

		delsig = sig;
		3.do{|i|
			n = (i + 1) * 0.1;
			o = (i + 1) * 0.01;
			e = (i + 1) * 0.1;

			delsig = AllpassC.ar(sig, 0.2, SinOsc.kr(delmod+o).range(0.01, n), e + dec, 0.3, delsig*0.7);
		};

		sig = (delsig * mix) + (sig * ( 1 - mix) );

		//sig = LPF.ar(sig, 800);
		Out.ar(out, Pan2.ar(sig, SinOsc.kr(LFNoise0.kr(0.2).range(0.001,0.5)).range(pan, pan+0.6) ) ); }).store;

SynthDef(\radiograin, { |envbuf bufnum freq = 440, amp = 1, t_trig = 0, decay, rate=1|

	var sig;
	//var dur = In.kr(durBus, 1);
	//var env = Env.new([0,0,1,0],[0,0.01,decay], curve:-8, releaseNode: 1);
	var env = Osc1.ar(envbuf, decay);
	/*sig = SinOsc.ar(freq, SinOsc.kr(LFNoise0.kr(0.2).range(1,80.0)).range(-2pi,2pi), amp) * EnvGen.kr(
		env,
		gate: t_trig // 't_trig' syntax allows the env to restart on-demand
	);*/
	sig = PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum)*rate,1, 0, loop: 1);
	Out.ar(0, Pan2.ar(sig*env*amp, SinOsc.kr(LFNoise0.kr(Rand(0.2,12.2)).range(0.01,40.0)).range(-0.9,0.9)));
}).add;

// instantiate a grid variable:
~flinGrid = MonomeGrid.new(prefix: "/flin", fps: 60);
//~secondGrid = MonomeGrid.new(prefix: "/second", fps: 60);
//~effect_group.freeAll

MIDIIn.connectAll;
~maingroup = Group.new;
~effect_group = Group.after(~maingroup);
~monome_synth_group = Array.fill(128, { Group.new(~maingroup); });
~monome_synth_arr = Array.fill(128, { nil } );
~monome_synth_gates = Array.fill(128, { 0 });
~rhythmic_gate = 0;

~whitenoise_synth_group = Array.fill(128, { Group.new(~maingroup); });
~whitenoise_synth_arr = Array.fill(128, { nil } );

~index_spec = [0.1, 100.0,\exp,0.001].asSpec;


	~mini_delay_busjes = Array.fill(2, { Bus.audio(s, 1); });

	Synth(\mini_delay,[\in, ~mini_delay_busjes[0], \pan, -0.5 ], ~effect_group);
	Synth(\mini_delay,[\in, ~mini_delay_busjes[1], \pan,  -0.1 ], ~effect_group);

~rec_synths = Array.fill(8, { 0 });
~fft_bufs = Array.fill(8, { Buffer.alloc(s, 512);    });
~rec_bufs = Array.fill(8, { Buffer.alloc(s, s.sampleRate * 5);    });

~dur_bus = Bus.control(s, 1).set(0.1);

~dur_spec = [2.0, 8.0, \linear, 0.001,0.01].asSpec;
~tempo_spec = [20.0, 500.0, \linear, 0.001].asSpec;

SynthDef(\radio_recorder, {|in=0 fftbuf recbuf|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.3);
//input = Compander.ar(input, input, 0.01,1,0.01,0.005,0.1,50);
//amplitude.poll;
	RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
 }).store;

~radiosample_choose = 0;
~overlap = 1;
	~overlap_spec = [0.01, 1.0,\linear, 0.01].asSpec;

~kick_gate = 0;

~tempoBus = Bus.control(s, 1).set(20);
~tempo = 1;
~tempo_switch = 0;

~monomeScene = 0;

// deze onder controller knoppen
Ndef(\tempo_mod, {
	}).play;




~rateState = 0;

/* tones and tunings */

~newScale = Scale.new(#[0,1,3,4,5,8,9,10,11,13,14,15,18,19,20,21,22,24,26,27,28,30,31,33,35,36,37,39,41,42,44,46,47],48,name: "quarter-tone");

~quarter =
Array.fill(256, {|i|
	var octave = i / 33;
	var sc = ~newScale;
	case
	{ octave < 1; } { sc.semitones.wrapAt(i) }
	{ ((octave == 1) or: (octave > 1)) and: (octave < 2) } { sc.semitones.wrapAt(i) + 12 }
	{ ((octave == 2) or: (octave > 2)) and: (octave < 3)  } { sc.semitones.wrapAt(i) + 24 }
	{ ((octave == 3) or: (octave > 3)) and: (octave < 4)  } { sc.semitones.wrapAt(i) + 36 }
	{ ((octave == 4) or: (octave > 4)) and: (octave < 5)  } { sc.semitones.wrapAt(i) + 48 }
	{ ((octave == 5) or: (octave > 5)) and: (octave < 6)  } { sc.semitones.wrapAt(i) + 50 }
	{ ((octave == 6) or: (octave > 6)) and: (octave < 7)  } { sc.semitones.wrapAt(i) + 62 }
	{ ((octave == 7) or: (octave > 7)) and: (octave < 8)  } { sc.semitones.wrapAt(i) + 74 }
	{ ((octave == 8) or: (octave > 8)) and: (octave < 9)  } { sc.semitones.wrapAt(i) + 86 }
	{ ((octave == 9) or: (octave > 9)) and: (octave < 10)  } { sc.semitones.wrapAt(i) + 98 }
	{ ((octave == 10) or: (octave > 10)) and: (octave < 11)  } { sc.semitones.wrapAt(i) + 110 }
	{ ((octave == 11) or: (octave > 11)) } { sc.semitones.wrapAt(i) +  [0,12,24,36,48,50,62,74].choose  }
});


~partchO = Scale.partch_o1(\partch);


~otonratios =
	Array.fill(16, {|i|
	var oct = i / 5;
	var mod = ( i % 5);
	//mod.postln;
	case
	{ oct < 1 } {  0  + (~partchO.ratios[mod]); }
	{ oct < 2 } { (~partchO.ratios[5]*2) + (~partchO.ratios[mod]); }
	{ oct < 3 } { (~partchO.ratios[5]*4) + (~partchO.ratios[mod]) }
	//{ oct < 4 } {  0 + ~partchO[j].ratios[mod] }
	{ oct < 4 } { (~partchO.ratios[5]*8) + ~partchO.ratios[mod]; }
	{ oct < 5 } {  (~partchO.ratios[5]* 16) + ~partchO.ratios[mod] };
});

	~footPedalMode = 0;

(
MIDIdef.cc(\nanokontrol, {|val num chan src|
	[num, val, chan, src].postln;


	case
	{ num == 32 } {
			if ( val == 127, {
					~kick_gate = 1; "kick gate open".postln; }, { ~kick_gate = 0;  "kick gate closed".postln; });
			}
	{ num == 56 }
	{
			~overlap = ~overlap_spec.map(val/127);
			("overlap : "++~overlap).postln;
		}
	{ num == 40 }
	{
		if ( ~radiosample_choose != (~radio_samples.size-1), {
			~radiosample_choose = ~radiosample_choose + 1;
			//16.do{|i| ~voices[i].set(\bufnum, ~radio_samples[~radiosample_choose]); };

		}, {
			~radiosample_choose = 0;
			//16.do{|i| ~voices[i].set(\bufnum, ~radio_samples[~radiosample_choose]); };

		});
		("selected sample nr "++~radiosample_choose).postln;
	}
	{ num == 110 }
	{
			if ( ~tempo_switch != 3, { ~tempo_switch = ~tempo_switch + 1; }, { ~tempo_switch = 0; });
			case
			{ ~tempo_switch == 0 } {

					Ndef(\tempo_mod, {
					Out.kr(~tempoBus, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,30.0)).range(20.0, 800.0); );
				});

			}
			{ ~tempo_switch == 1 } {
				"Dseries 1 tempo mod".postln;
				Ndef(\tempo_mod, {
					var a, freq, trig;
					//a = Dbrown(20, 800, 10, inf);
					a = Dser([20, 40, 80, 30, 50,400,350,35,55,700,650,600,65, 75,85,90,105,750,800,650,500,50,40,30,20,60,20,30,90], inf);
					trig = Impulse.kr(28);
					freq = Demand.kr(trig, 0, a);
					Out.kr(~tempoBus, freq);
				});
			}
			{ ~tempo_switch == 2 } {
				"Dseries 2 tempo mod".postln;
				Ndef(\tempo_mod, {
					var a, freq, trig;
					//a = Dbrown(20, 800, 10, inf);
					a = Dser([Dser([20],20),400,350,Dser([35],30),Dser([55],10),700,650,600,Dser([65],5),Dser([75],5),
						Dser([85],5),Dser([90],5),750,800,650,500,Dser([50],10),Dser([40],5),Dser([30],5)], inf);
					trig = Impulse.kr(28);
					freq = Demand.kr(trig, 0, a);
					Out.kr(~tempoBus, freq);
				});
			}
			{ ~tempo_switch == 3 } {
				"Dstutter tempo mod".postln;
			Ndef(\tempo_mod, {
					var a, freq, trig;
					//a = Dbrown(20, 800, 10, inf);
		             a = Dseq([Dshuf([Drand([50, 55, 75], 6), 150, Drand([500,450], 1), 120, 80], 8)], inf);
		             //a = Diwhite(20, 500, inf);
		            a = Dstutter(Diwhite(1, 15, inf), a );
					trig = Impulse.kr(28);
					freq = Demand.kr(trig, 0, a);
					Out.kr(~tempoBus, freq);
				});

			};


		}
	//stop synth
	{ num == 102 }
	{
				~maingroup.set(\gate, 0);
				~monome_synth_arr.do{|i, item| ~monome_synth_arr.put(item, nil); };
				~monome_synth_gates.do{|i, item| ~monome_synth_gates.put(item, 0); };

			}
	{ num == 103 }
	{
		if ( val == 127, {
			"modulating tempo".postln;

				~tempoRoutine = Routine({inf.do{
				~tempoBus.get{|item| ~tempo = item; };
				//~tempo.postln;

				~bpm = ~tempo;
				//("bpm :"++~bpm).postln;
				~linkClock.tempo = ~bpm/60;

				0.1.wait; }; }).play;


		}, {
			"stopped modulating tempo".postln;
			~tempoRoutine.stop;


		});

	}
	{ num == 104 }
	{


				if ( ~footPedalMode != 1, { ~footPedalMode = ~footPedalMode + 1; }, { ~footPedalMode = 0; });


				case
				{ ~footPedalMode == 0 }
				{
					MIDIdef.cc(\BOSS_footpedal, {|val num chan src|

						//~maingroup.set(\index, ~index_spec.map(val/127));

						~bpm = ~tempo_spec.map(val/127).postln;
						~linkClock.tempo = ~bpm/60;
						[num,val,chan, src].postln;


					},srcID:~footpedal_srcid);

				}
				{ ~footPedalMode == 1 }
				{

					"no tempo footpedal".postln;
					MIDIdef.cc(\BOSS_footpedal, {|val num chan src|

						~maingroup.set(\index, ~index_spec.map(val/127));

						//~bpm = ~tempo_spec.map(val/127).postln;
						//~linkClock.tempo = ~bpm/60;
						[num,val,chan, src].postln;


					},srcID:~footpedal_srcid);


				};

				("footpedal mode : "++~footPedalMode).postln;

			}
	{ num == 105 }
	{


				if ( ~monomeScene != 2, { ~monomeScene = ~monomeScene + 1; }, {   ~monomeScene = 0; });


				case
				{ ~monomeScene == 0 }
				{


				}
				{ ~monomeScene == 1 }



				{
					Task({ 0.1.wait;
						~flinGrid.all(1);
						0.05.wait;
						~monome_synth_arr.do{|item, i| var column, row; [i, item].postln;
						if ( item != nil, {
								column = i%16;
								row = (i/16).floor;
								~flinGrid.led(column,row,15);



							});

						};
					}).start;


				}
				{ ~monomeScene == 2 }



				{
					Task({ 0.1.wait;
						~flinGrid.all(1);
						0.05.wait;
						~whitenoise_synth_arr.do{|item, i| var column, row; [i, item].postln;
						if ( item != nil, {
								column = i%16;
								row = (i/16).floor;
								~flinGrid.led(column,row,15);



							});

						};
					}).start;


				};

				("monome scene : "++~monomeScene).postln;

			}
	{ num == 107 }
	{
				if ( ~rateState != 2, { ~rateState = ~rateState + 1; }, {   ~rateState = 0; });
				("rate state : "++~rateState).postln;

			}
	{ num == 108 }
	{
		if ( val == 127, {


					~rhythmic_gate = 1; "rhythmic gate open".postln;


				}, {
					~rhythmic_gate = 0;

					"rhythmic gate closed".postln;

				});

			};


}, chan: 2);
	);

~bpm = 200;
~linkClock;


s.waitForBoot({

	var redraw, mainTimer,
	positions, speeds, widths, counts, holding, notes, base_note, voices,
	lvl2 = 15, lvl1 = 5, lvl0 = 2,
	length = 16,
	dirtyGrid = 0,
	// timing vars:
	stepInterval = 0.0625, stepMultiplier = 1, bpm = 250, playing = 1,
	linkClock, linkCallback, launchQuant = -1, launchQuants = [-1, -0.25, -0.125, -0.0625, 0],
	linkStartStop = 1,
	// GUI vars:
	tempoGUI, transportGUI, quantGUI, barsBox, beatsBox, startButton, toggleTransport;

	// create a Link-synchronized clock
	~linkClock = LinkClock(1).latency_(Server.default.latency);
	~linkClock.tempo = ~bpm/60;
	/*
	linkCallback = SimpleController(~linkClock)
	.put(\linkStart, {
		toggleTransport.value(1);
	})
	.put(\linkStop, {
		toggleTransport.value(1);
	})
	.put(\stop, { linkCallback.remove })
	.put(\tempo, {
		~bpm = round(~linkClock.tempo * 60,0.01);
		defer{tempoGUI.value = ~bpm}; // all GUI changes need to be deferred
	});
	*/
	//

	~flinGrid.connect();




	// build grid UI from connected grid measurements:
	positions = Array.fill(~flinGrid.cols, {-1});
	speeds = Array.fill(~flinGrid.cols, {~flinGrid.rows-1});
	widths = Array.fill(~flinGrid.cols, {0});
	counts = Array.fill(~flinGrid.cols, {-3});
	holding = Array.fill(~flinGrid.cols, {0});

	notes = [2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28];
	base_note = 60;

	// one voice per grid column
		~grain_groups = Array.fill(16, { Group.new; });

/*
	for(0,~voices.size-1){
		arg i;
		// instantiate a synth voice for each grid column:
		~voices[i] = Synth(\radiograin, [
			bufnum: ~radio_samples[0],
			rate: 440 / (notes[i] + base_note).midicps,
			amp: 0.2 * (1/(i+1)),
			t_trig: 0
		]);
	};*/

	// handler for start / stop from Link as well as GUI button
	toggleTransport = { arg state;
		if(state == 1,{
			Routine({
				playing = 1;
				defer{startButton.value = 1}; // all GUI changes need to be deferred
			}).play(linkClock,launchQuant);
		},{
			playing = 0;
			for(0,15){
				arg i;
				positions[i] = 0;
			};
			defer{startButton.value = 0}; // all GUI changes need to be deferred
		});
	};

	~flinGrid.key({ arg x,y,z;
			var synthNum = x+(16*y);
			[x,y,z].postln;
			("coordinate : "++synthNum).postln;


		case { ~monomeScene == 0 }
			{

		if(z == 1, {
			if(holding[x] == 0, {
				speeds[x] = y;
				widths[x] = y;
				positions[x] = 0;
				counts[x] = y+1;
				if(y == (~flinGrid.rows-1), {

				//~voices[x].set(\t_trig,-1.9);

				});
			},{

				widths[x] = y;
				//~voices[x].set(\t_trig,-1.9);
			});

			holding[x] = 1;
		},{
			holding[x] = 0;
		});

		dirtyGrid = 1;
			}
			{ ~monomeScene == 1 }
			{
				if(z == 1, {

					if ( ~monome_synth_arr[synthNum] == nil, {
						"play synth".postln;

					~monome_synth_arr.put(synthNum,
							Synth(\minilogue, [\amp,0.1,\freq, ~quarter[(synthNum-1)+128].midicps,
								\out1, ~mini_delay_busjes[0],\out1, ~mini_delay_busjes[1]
						], ~monome_synth_group[synthNum-1]); );

						("synth num trigged"++synthNum).postln;
					~flinGrid.led(x,y,15);
					},
					{	"stop synth".postln;
						~monome_synth_arr[synthNum].set(\gate, 0);
						~monome_synth_arr.put(synthNum, nil);

						~flinGrid.led(x,y,0);

					});






				});


			}
			{ ~monomeScene == 2 }
			{

				if(z == 1, {

					if ( ~whitenoise_synth_arr[synthNum] == nil, {
						"play whitenoise".postln;

					~whitenoise_synth_arr.put(synthNum,
							Synth(\aether_whitenoise, [\amp,0.1,\bfreq, ~quarter[(synthNum-1)+128].midicps,\out, 0 ], ~whitenoise_synth_group[synthNum-1]); );

						("synth num trigged"++synthNum).postln;
					~flinGrid.led(x,y,15);
					},
					{	"stop whitenoise".postln;
						~whitenoise_synth_arr[synthNum].set(\gate, 0);
						~whitenoise_synth_arr.put(synthNum, nil);

						~flinGrid.led(x,y,0);

					});






				});

			};

	});

	redraw = Routine({
		var interval = 1/60; // 60fps




		loop{
			case { ~monomeScene == 0 }
			{
			if(dirtyGrid != 0, {
				for(0, ~flinGrid.cols-1) {
					arg i1;
					// canvas:
					for(0, ~flinGrid.rows-1){
						arg i2;
						if((~flinGrid.rows == 16 && (speeds[i1] != 15)) || (~flinGrid.rows == 8 && (speeds[i1] != 7)),{
							~flinGrid.led(i1,i2,lvl1);
						},{
							~flinGrid.led(i1,i2,lvl0);
						});
					};


					// playhead:
					if((~flinGrid.rows == 16 && (speeds[i1] != 15)) || (~flinGrid.rows == 8 && (speeds[i1] != 7)),{
						var onGridPos = positions[i1]-1;
						if (onGridPos >= 0,{
							~flinGrid.led(i1,onGridPos,lvl2);
							if (widths[i1] >= 1,{
								for((onGridPos - widths[i1]),(onGridPos-1)){
									arg showWidth;
									if( showWidth >= 0, {
										~flinGrid.led(i1,showWidth,lvl2);
									});
								};
							});
						});
					});


				};
				dirtyGrid = 0;
			});


			}
				{ ~monomeScene == 1 }
				{
					//"not drawing anymore".postln;

				}
				{ ~monomeScene == 2 }
				{
					//"not drawing anymore".postln;

				};
			interval.yield;
		}

	});

	mainTimer = Routine({




		loop {
				case { ~monomeScene == 0 }
			{
			if(playing == 1, {

				for(0, ~flinGrid.cols-1) {
					arg i;
					if(speeds[i] != (~flinGrid.rows-1)) {
						counts[i] = counts[i] + 1;
						if(counts[i] > speeds[i]) {
							if(positions[i] == 0, {
								var sIM = stepInterval * stepMultiplier;
								var duration = (((widths[i] + speeds[i]) * sIM) * (1/sIM)).clip(sIM,inf);
								var rate;
										case
										{ ~rateState == 0 } { rate = 1; }
										{ ~rateState == 1 } { rate = (notes[i] + base_note).midicps/440; }
										{ ~rateState == 2 } { rate = ~otonratios[i]; };
								//~voices[i].set(\decay, duration);
								//~voices[i].set(\t_trig,1);
								Synth(\radiograin, [\envbuf, b,
								\bufnum, ~radio_samples[~radiosample_choose],
											\rate, rate,
											\decay, duration*~overlap], ~grain_groups[i]);

								if ( ~kick_gate == 1, {
										if ( 0.1.coin, {
												"KICK".postln;
									Synth(\em_kick, [\sustain, rrand(0.1, 0.2), \freq, rrand(40, 70), \mod_freq, rrand(3, 10),\mod_index, rrand(4, 10) ]);
											});
										});

									if ( ~rhythmic_gate == 1,  {

											Task({

												~monome_synth_arr.do{|i, item|
													//[i, item].postln;
													if ( i != nil, {
														if ( ~monome_synth_gates[item] == 0, {
															     ~monome_synth_arr[item].set(\gate2, 0);
															~monome_synth_gates.put(item, 1);
															"gating synth".postln;
														}, {
															  ~monome_synth_arr[item].set(\gate2, 1);
															~monome_synth_gates.put(item, 0);
															"ungating synth".postln;
														});
													});
														};

										}).start;
										});


							},{
								if((positions[i] - widths[i]) == 1,{
									//~voices[i].set(\t_trig,-10);
								});
							});

							positions[i] = (positions[i]+1) % length;
							counts[i] = 0;
						}
					}
				};
			});

			dirtyGrid = 1;
			(stepInterval * stepMultiplier).wait;
		}

				{ ~monomeScene == 1 }
			{
					//"not playing".postln;

			0.1.wait;
				}
			{ ~monomeScene == 2 }
			{
					//"not playing".postln;

			0.1.wait;
				};


			}

	});

	mainTimer.play(~linkClock, quant: 1);
	redraw.play();


		transportGUI = Routine {
		var bars, beats;
		loop {
			bars = ~linkClock.bar;
			beats = ~linkClock.beatInBar;
			{
				//barsBox.value = bars;
				//beatsBox.value = beats+1;
			}.defer(~linkClock.latency);
			1.0.wait;
		}
	}.play(~linkClock, quant: 1);




	//footpedal

	MIDIdef.cc(\BOSS_footpedal, {|val num chan src|

	//~maingroup.set(\index, ~index_spec.map(val/127));

	~bpm = ~tempo_spec.map(val/127).postln;
	~linkClock.tempo = ~bpm/60;
	//[num,val,chan, src].postln;


    },srcID:~footpedal_srcid);


});



};
)