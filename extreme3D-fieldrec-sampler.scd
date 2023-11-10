
NetAddr.langPort;
/*
buttons
tunings / scales
re-sampling
wavetable
granular

transform chains
more synthesis
*/

/*synthesis types*/

/* var for selecting */
~synthesis_type = 0;

/* FM synthesis */
SynthDef(\extreme_fm0, {|out recOut bus0 bus1 bus2 bus3 att=0.01 dur=0.5 amp=0.2 envbuf|
	var freq = In.kr(bus0, 1);
	var index = In.kr(bus1, 1);
	var phaseFreqMod = In.kr(bus2, 1);
	var phaseIndex = In.kr(bus3, 1);
	var mod = SinOsc.ar(freq.midicps, 0, index);
	var sig = SinOsc.ar(freq.midicps * mod, SinOsc.kr(phaseFreqMod, 0, phaseIndex) );
	//var env = EnvGen.ar(Env.adsr(att, 0.0, 1, rel), gate, doneAction: 2);
	var env = Osc1.ar(envbuf, dur);

	sig = sig * env * amp;
	Out.ar(recOut, sig);
	Out.ar(out, sig); }).store;

SynthDef(\extreme_fm1, {|out recOut bus0 bus1 bus2 bus3 att=0.01 dur=0.5 amp=1 envbuf gate=1|
	var freq = In.kr(bus0, 1);
	var index = In.kr(bus1, 1);
	var phaseFreqMod = In.kr(bus2, 1);
	var phaseIndex = In.kr(bus3, 1);

	var mod = SinOsc.ar(freq.midicps, 0, index);

	var sig = SinOsc.ar((freq ** Array.series(200, 0, 0.002)) * 300, SinOsc.kr(phaseFreqMod, 0, phaseIndex)).sum;
	//var sig = SinOsc.ar(freq.midicps * mod, SinOsc.kr(phaseFreqMod, 0, phaseIndex) );
	//var env = EnvGen.ar(Env.adsr(att, 0.0, 1, rel), gate, doneAction: 2);
	var env = Osc1.ar(envbuf, dur);

	//sig = Splay.ar(sig * 0.02, 1);
	sig = Mix(sig * 0.02);
	sig = sig * env * amp;
	Out.ar(recOut, sig);
	Out.ar(out, sig); }).store;

SynthDef(\extreme_fm2, {|out recOut freqBus indexBus att=0.01 dur=0.5 amp=0.25 envbuf phaseFreqModBus phaseIndexBus gate=1|
	var freq = In.kr(freqBus, 1);
	var index = In.kr(indexBus, 1);
	var phaseFreqMod = In.kr(phaseFreqModBus, 1);
	var phaseIndex = In.kr(phaseIndexBus, 1);
	var mod = SinOsc.ar(freq.midicps, 0, index);
	var sig = SinOsc.ar(freq.midicps * mod, SinOsc.kr(phaseFreqMod, 0, phaseIndex) );
	//var env = EnvGen.ar(Env.adsr(att, 0.0, 1, rel), gate, doneAction: 2);
	var env = Osc1.ar(envbuf, dur);

	sig = sig * env * amp;
	Out.ar(recOut, sig);
	Out.ar(out, sig); }).store;


SynthDef(\transform0, {|out=0 in ffreq=500 modFreq|
	var sig = In.ar(in, 1);


	//sig = PitchShift.ar(sig, 0.2, 0.25, 0.01,0.01);
	//sig = MoogVCF.ar(sig, LFTri.kr(SinOsc.kr(0.01).range(1,35.0)).range(200,1200),0.9,0.5, sig*0.5);
	//sig = MoogFF.ar(sig, 600, 2,0,2);
	//sig = BLowPass4.ar(sig, 800, 0.8,2);
	sig = MidEQ.ar(sig, 500, 0.4,6);
	sig = BLowPass4.ar(sig, 1500, 0.8,4);
	//sig = Decimator.ar(sig, 30000, 12);

	sig = HPF.ar(sig, 20);
	sig = Pan2.ar(sig, SinOsc.kr(5).range(-0.5,0.6));
	sig = FreeVerb2.ar(sig[0], sig[1], 0.15, 0.4);

	Out.ar(out, sig ); }).store;

//
//~transformGroup.freeAll
//
// Synth(\transform0, [\in, ~trans_bs[0] ], ~transformGroup);

SynthDef(\transform1, {|out=0 in ffreq=500 modFreq|
	var sig = In.ar(in, 1);

	sig = MoogLadder.ar(sig, LFTri.kr(SinOsc.kr(0.01).range(1,35.0)).range(200,1200),0.9,0.5, sig*0.5).tanh;
	sig = BHiCut.ar(sig, 5000, 2);
	sig = Decimator.ar(sig, 10000, 8);

	sig = HPF.ar(sig, 40);
	sig = Pan2.ar(sig, LFNoise0.kr(0.8).range(-0.5,0.2));
	sig = FreeVerb2.ar(sig[0], sig[1], 0.2, 0.8);

	Out.ar(out, sig ); }).store;


SynthDef(\transform2, {|out=0 in ffreq=500 modFreq|
	var sig = In.ar(in, 1);
	var drysig = sig;
	sig = MoogFF.ar(sig , 500, 3);
	sig = BLowPass.ar(sig, 800, 0.7);

	4.do{ d = 0.1.rand + 0.05;
		sig = CombC.ar(sig, d, SinOsc.kr(LFNoise1.kr(Rand(0.1,0.8)).range(0.001,1.0)).range(0.001,d), Rand(5.0, 11.0),0.3, sig * 0.33); };
	sig = ( drysig * 0.8 ) + ( sig * 0.2 );
	sig = HPF.ar(sig, 40);
	sig = Pan2.ar(sig, LFNoise0.kr(0.1).range(-0.1,0.1));
	sig = FreeVerb2.ar(sig[0], sig[1], 0.2, 0.8);

	Out.ar(out, sig ); }).store;

SynthDef(\sampler_effect, {|out=0 in ffreq=500 modFreq|
	var sig = In.ar(in, 1);


	//sig = PitchShift.ar(sig, 0.2, 0.25, 0.01,0.01);
	//sig = MoogVCF.ar(sig, LFTri.kr(SinOsc.kr(0.01).range(1,35.0)).range(200,1200),0.9,0.5, sig*0.5);
	//sig = MoogFF.ar(sig, 600, 2,0,2);
	//sig = BLowPass4.ar(sig, 800, 0.8,2);
	sig = MidEQ.ar(sig, 500, 0.4,6);
	sig = BLowPass4.ar(sig, 1500, 0.8,4);
	//sig = Decimator.ar(sig, 30000, 12);

	sig = HPF.ar(sig, 20);
	sig = Pan2.ar(sig, SinOsc.kr(5).range(-0.5,0.6));
	3.do{ d = 0.01 + 0.2.rand;
		sig = AllpassL.ar(sig, d, d, Rand(3, 6), 0.2, sig * 0.7);
	};
	//sig = FreeVerb2.ar(sig[0], sig[1], 0.1, 0.9);

	Out.ar(out, Pan2.ar(sig, SinOsc.kr(LFNoise0.kr(0.2).range(0.01,8.0)).range(-0.5,0.5) )); }).store;




SynthDef(\extreme_recorder, {|in bufnum|
	var sig = In.ar(in, 1);
	RecordBuf.ar(sig, bufnum, loop: 0);
}).store;


SynthDef(\extreme_player, {|out=0 in bufnum gate=1 rateBus amp=1 recTime|
	var rate = In.kr(rateBus, 1);
	var env = EnvGen.ar(Env.adsr(0.4,0.0,1,2.0),gate,doneAction: 2);


	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), loop: 1);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(0, BufRateScale.kr(bufnum) * rate*0.25, 0, BufFrames.ir(bufnum) * (recTime /30) * 0.99 ), 1, 2);
	Out.ar(out, sig*env*amp* 2);
}).store;

// fill 2 different tables to be used for amplitude envelopes.

v = Signal.sineFill( 1024, 1.0/#[ 1, 2, 3, 5, 8, 13, 21, 34, 55 ].scramble );
v.put(v.size-1, 0);
~envBuf = Buffer.sendCollection(s, v, 1);


/*tunings*/
~pythScale = Scale.chromatic(\pythagorean);

~pyth_low_ratios = ~pythScale.ratios*0.25;
~pyth_low_ratios.add(0.5);


~pythTones = Array.fill(72, {|i|

	var octave = i / 12;

	case
	{ octave < 1; } { ~pythScale.semitones.wrapAt(i) + 24 }
	{ octave < 2; } { ~pythScale.semitones.wrapAt(i) + 36; }
	{ octave < 3; } { ~pythScale.semitones.wrapAt(i) + 48; }
	{ octave < 4; } { ~pythScale.semitones.wrapAt(i) + 60; }
	{ octave < 5; } { ~pythScale.semitones.wrapAt(i) + 72; }
	{ octave < 6; } { ~pythScale.semitones.wrapAt(i) + 84; }
	{ octave < 7; } { ~pythScale.semitones.wrapAt(i) + 96; }
	{ octave > 7; } { ~pythScale.semitones.wrapAt(i) + 108};
});

//~pythTones = ~pythTones.scramble;

~pythTuneSpec = [0, 71, \linear, 1, 10].asSpec;
~pythRateSpec = [0, 12, \linear, 1, 5].asSpec;


~extremeGroup = Group.new;
~recordGroup = Group.after(~extremeGroup);
~playGroup = Group.after(~extremeGroup);
~transformGroup = Group.after(~extremeGroup);


/*transformation */
~trans_bs = Array.fill(3, { Bus.audio(s, 1); });
~smplr_eff_bs = Array.fill(3, { Bus.audio(s, 1); });
~sampler_effect = Synth(\sampler_effect, [\in, ~smplr_eff_bs[0] ], ~playGroup, \addAfter);


/*
~transformGroup.freeAll
*/

Synth(\transform0, [\in, ~trans_bs[0] ], ~transformGroup);
Synth(\transform1, [\in, ~trans_bs[1] ], ~transformGroup);
Synth(\transform2, [\in, ~trans_bs[2] ], ~transformGroup);

/* vars for switching */
~transform_mode = 0;
~transform_bus = ~trans_bs[0];


~rateBus = Bus.control(s, 1).set(1);
~recBus = Bus.audio(s, 1);
~recBufs = Array.fill(10,  { Buffer.alloc(s, s.sampleRate * 30); } );


~extremeSwitch = 0;
/* per synthesis type 4 parameter Buses */
~extremeBuses = Array.fill(3, { Array.fill(4, { Bus.control(s, 1); }); });
~extremeBuses[0][0].set(100);
~extremeBuses[0][1].set(1);
~extremeBuses[0][2].set(1);
~extremeBuses[0][3].set(1);


~bangGates = Array.fill(16, { 0});
~freezeSwitch = nil;


~freqSpec = [50, 600, 4,1].asSpec;
~indexSpec = [30, 3000, \exp,0.1].asSpec;
~phaseFreqModSpec = [5, 5000, \exp,0.1].asSpec;
~phaseIndexSpec = [2, 100, \exp,0.1].asSpec;


~fm_arr = Array.fill(30, { nil });

~fm_cnt = nil;





OSCdef(\btn_0, {|msg, time, addr, recvPort| msg.postln;


	if ( ~freezeSwitch == nil, {

	if ( ~extremeSwitch == 0, {
		if ( msg[1] == 1, {"synth on".postln;
				if ( ~fm_arr[0] == nil, {
				//~fm_arr.put(0,

				~grainRoutine = Routine({ inf.do{
							var dur = rrand(0.1, 0.5);
							var overlap = rrand(1,2);
						    case
						{ ~synthesis_type == 0 } { dur = rrand(0.1, 0.5); }
						{ ~synthesis_type == 1 } {  dur = rrand(0.5, 1.0); }
						{ ~synthesis_type == 2 } { dur = rrand(0.1, 0.5);};
						case
						{ ~transform_mode == 0 } { ~transform_bus = ~trans_bs[0];  }
						{ ~transform_mode == 1 } {  ~transform_bus = ~trans_bs[1];  }
						{ ~transform_mode == 2 } { ~transform_bus = ~trans_bs[2];  };






						Synth(\extreme_fm++~synthesis_type, [\envbuf, ~envBuf, \dur, dur*overlap,
							\out, ~transform_bus, \recOut, ~recBus,
							\bus0, ~extremeBuses[~synthesis_type][0].index, \bus1,~extremeBuses[~synthesis_type][1].index,
							\bus2, ~extremeBuses[~synthesis_type][2].index,\bus3, ~extremeBuses[~synthesis_type][3].index ], ~extremeGroup );




							dur.wait; }; }).play;



				~fm_cnt = 0;


					~extremeSwitch = 1; }); });


		}, {
			if (msg[1] == 0, { "synth off".postln;
				~grainRoutine.stop;
				~extremeGroup.set(\gate, 0);
				~extremeSwitch = 0;
				30.do{|i| ~fm_arr.put(i, nil); };
	}); });

	});

}, '/btn_0', nil);

~playSwitch = nil;
~recSwitch = nil;
~recTime = nil;
~recTimeBus = Bus.control(s, 1).set(0);

~bangGates.put(1,0);



OSCdef(\btn_1, {|msg, time, addr, recvPort|
	//msg.postln;


	if ( ~bangGates[1] == 0, {

			~bangGates.put(1, 1);
		if ( msg[1] == 1, {

			if ( ~playSwitch == nil, {

			"turn on player".postln;

				~playSynth = Synth(\extreme_player, [\in, ~recBus,\rateBus, ~rateBus.index, \recTime, ~recTime,\bufnum, ~recBufs[0], \out, ~smplr_eff_bs[0] ], ~playGroup);


			~playSwitch = 1;

			}, {
				"turn off player".postln;
				~playGroup.set(\gate,0);

				~playSwitch = nil;

			});
		});


		Task({ 1.do{  0.4.wait; ~bangGates.put(1, 0); }; }).start;
	});


}, '/btn_1', nil);



OSCdef(\btn_2, {|msg, time, addr, recvPort|
	//msg.postln;

		if ( ~bangGates[2] == 0, {

			~bangGates.put(2, 1);
		if ( msg[1] == 1, {

			if ( ~recSwitch == nil, {

			~recSynth = Synth(\extreme_recorder, [\in, ~recBus, \bufnum, ~recBufs[0] ], ~recordGroup);
			~timeTask = Task({ 1.do{ 300.do{|i| var time = i/10; ~recTimeBus.set(time); time.postln; 0.1.wait;};  "end of buffer reached, rec stopped".postln; } }).start;
			~recSwitch = 1;

			}, {
				~recSynth.free;
		~timeTask.stop;
				~recTimeBus.get{|item| ~recTime = item; item.postln; };
				~recSwitch = nil;

			});
		});


		Task({ 1.do{  0.4.wait; ~bangGates.put(2, 0); }; }).start;
	});


}, '/btn_2', nil);


/*  GESTURAL FREEZE BUTTON */
OSCdef(\btn_3, {|msg, time, addr, recvPort|
	//msg.postln; time.postln;

		if ( ~bangGates[3] == 0, { ~bangGates.put(3, 1);
		if ( ~freezeSwitch == nil, { ~freezeSwitch = \on; ~freezeSwitch.postln; },
				{  ~freezeSwitch = nil;
					~freezeSwitch.postln; });
		Task({ 1.do{  0.2.wait; ~bangGates.put(3, 0); }; }).start;
	});

}, '/btn_3', nil);




OSCdef(\btn_4, {|msg, time, addr, recvPort|
	//msg.postln;

	if ( ~bangGates[4] == 0, { ~bangGates.put(4, 1);
		if ( ~transform_mode != 2, {
			~transform_mode = ~transform_mode + 1; },
		{ ~transform_mode = 0; });

		("transform mode : "++~transform_mode).postln;
		case
		{ ~transform_mode == 0 } { ~transform_bus = ~trans_bs[0]; }
		{ ~transform_mode == 1 } { ~transform_bus = ~trans_bs[1]; }
		{ ~transform_mode == 2 } { ~transform_bus = ~trans_bs[2]; };


		Task({ 1.do{  0.2.wait; ~bangGates.put(4, 0); }; }).start;
	});


}, '/btn_4', nil);


OSCdef(\btn_5, {|msg, time, addr, recvPort| msg.postln;

		if ( ~bangGates[5] == 0, { ~bangGates.put(5, 1);
		if ( ~synthesis_type != 2, {
			~synthesis_type = ~synthesis_type + 1; },
		{ ~synthesis_type = 0; });

		("synthesis type : "++~synthesis_type).postln;


		Task({ 1.do{  0.2.wait; ~bangGates.put(5, 0); }; }).start;
	});


}, '/btn_5', nil);

OSCdef(\btn_6, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_6', nil);

OSCdef(\btn_7, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_7', nil);

OSCdef(\btn_8, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_8', nil);

OSCdef(\btn_9, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_9', nil);

OSCdef(\btn_10, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_10', nil);

OSCdef(\btn_11, {|msg, time, addr, recvPort| msg.postln;


}, '/btn_11', nil);


OSCdef(\abs_x, {|msg, time, addr, recvPort|
	var pythTone;

	pythTone = ~pythTones[~pythTuneSpec.map(msg[1]/1021)];

	if ( ~freezeSwitch == nil, {
	~extremeBuses[~synthesis_type][0].set(
			pythTone.postln;
		);




		//~rateBus.set( ~pyth_low_ratios[~pythRateSpec.map(msg[1]/1021); ] );

	});


}, '/abs_x', nil);





OSCdef(\abs_y, {|msg, time, addr, recvPort|
	//msg.postln;

	if ( ~freezeSwitch == nil, {
	~extremeBuses[0][1].set(~indexSpec.map(msg[1]/1021); );
	~extremeBuses[1][1].set(~indexSpec.map(msg[1]/1021); );

	});
	}  , '/abs_y', nil);

OSCdef(\abs_rz, {|msg, time, addr, recvPort|
	msg.postln;

	if ( ~freezeSwitch == nil, {
	~extremeBuses[0][2].set(~phaseFreqModSpec.map(msg[1]/255); );
	~extremeBuses[1][2].set(~phaseFreqModSpec.map(msg[1]/255); );
	});

	}, '/abs_rz', nil);


OSCdef(\abs_throttle, {|msg, time, addr, recvPort|
	//msg.postln;



	~extremeBuses[0][3].set(~phaseIndexSpec.map(msg[1]/255); );
	~extremeBuses[1][3].set(~phaseIndexSpec.map(msg[1]/255); );


	}, '/abs_throttle', nil);


~lowRateArray = Array.series(10, 0.5,-0.049);
~lowRateIndex = 0;


OSCdef(\abs_hat0x, {|msg, time, addr, recvPort|
	msg.postln;

	if ( msg[1] == -1, {
		~rateBus.set( ~lowRateArray[~lowRateIndex]);
		~lowRateIndex.postln;
		if ( ~lowRateIndex != 9, { ~lowRateIndex = ~lowRateIndex + 1; }, { ~lowRateIndex = 0; });

	});


	}, '/\abs_hat0x', nil);

OSCdef(\abs_hat0y, {|msg, time, addr, recvPort|
	msg.postln;





}, '/\abs_hat0y', nil);












