/*
ordenen
granulaire patch checken
ritmische klanken aan nanopad
opties voor gamepad
frequentie op web sdr: 7074.72
*/

(

fork {
	// Require("D:/Dropbox/PROJECTS/SC_performances/tenori-on/Ansage_Ende_01052021/Cologne_tonalities_v2.scd");
	//
	// MIDIClient.init;
	// MIDIIn.connectAll;


/*	5.0.wait;*/


~nyquist = s.sampleRate * 0.5;

SynthDef(\ten_volume, {|out=0 in volume=1|
		var sig = In.ar(in, 2);
		Out.ar(out, [sig[0]*volume, sig[1]*volume]); }).store;

SynthDef(\sidechainer, {|out=0 inBus controlBus thresh=0.1 ratio=0.1 controlgain=0.5 volume=1|
			var in,control,sig1,sig2;
			in = In.ar(inBus, 2);
			control = In.ar(controlBus, 2);
			sig1 = Limiter.ar(Compander.ar(in[0],in[0],thresh,1,ratio,0.001,0.1,(1/ratio)*0.5,in[0]*0.5),1,0.001);
			sig2 = Limiter.ar(Compander.ar(in[1],in[1],thresh,1,ratio,0.001,0.1,(1/ratio)*0.5,in[1]*0.5),1,0.001);
			Out.ar(out, [sig1*volume, sig2*volume]); }).store;

SynthDef(\compressor, {|out=0 inBus thresh=0.1 ratio=0.1 gain=1|
			var in,control,sig1,sig2;
			in = In.ar(inBus, 2);
			sig1 = Limiter.ar(Compander.ar(in[0],in[0],thresh,1,ratio,0.001,0.1,1/ratio),1,0.001)*gain;
			sig2 = Limiter.ar(Compander.ar(in[1],in[1],thresh,1,ratio,0.001,0.1,1/ratio),1,0.001)*gain;
			Out.ar(out, [sig1, sig2]);
			//Out.ar(out, in);
		}).store;

SynthDef(\radiorecorder, {|in bufnum|
	var input = In.ar(in, 1);
	input = Limiter.ar(input,1, 0.001);
	//input = Compander.ar(input, input, 0.01, 1, 0.01, 0.001, 0.1,1000);
	input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,200);
	//for hardware input
	//RecordBuf.ar(SoundIn.ar(in),bufnum);
	//for bus
	RecordBuf.ar(input,bufnum);
}).store;

//SYNTHS
//second generation sampler
SynthDef(\recrecorder, {|in bufnum|
	//for hardware input
	//RecordBuf.ar(SoundIn.ar(in),bufnum);
	//for bus
	var input = In.ar(in, 1);
	input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,200);
	//input = Compander.ar(input, input, 0.001,1,0.01,0.001,0.1,50);
	RecordBuf.ar(input,bufnum,loop:0,doneAction:2);
}).store;
//sampleplayer

SynthDef(\radioplay, {|out amp mainvolBus start end release=0.005 trig=1 octave=1 reverse=1 vectorOut bufnum xpan= -0.5 ypan=1.0 nyquist sampleRate|
	//var start = In.kr(startBus, 1);
	var mainvol = In.kr(mainvolBus, 1);
	var loopdur = (end - start)/sampleRate*(1/octave);

	var trigger = EnvGen.kr(Env([1,0],[loopdur*0.95]),1);
	var env = EnvGen.ar(Env.adsr(loopdur*0.3,loopdur*0.1,1,loopdur*0.05),trigger,doneAction:2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 0) * env * amp;
	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),trig, loop: 1);
	//Out.ar(out, Pan2.ar(sig, LFNoise1.kr(Rand(0.8,3.2)).range(pan,pan+0.25)));
	//loopdur.poll;
	//Out.ar(out, Pan4.ar(sig, LFNoise2.kr(Rand(0.1,6.4)).range(xpan,xpan+1.0),LFNoise2.kr(Rand(0.1,14.4)).range(ypan,ypan+1.0,)));
	sig = LPF.ar(sig, nyquist);
	sig = HPF.ar(sig, 30,2);
	//Out.ar(out, Pan2.ar(sig*mainvol, LFNoise1.kr(Rand(0.8,3.2)).range(-0.5,0.5)));
	Out.ar(out, Pan2.ar(sig*mainvol,0) );
	Out.ar(vectorOut,sig);
}).store;

//synth for granular patterns
SynthDef(\radioplaypattern, {|out=0 ampBus lengthBus start=0 endBus octave=1 trig=1 reverse=1 bufnum envbuf xpos=0 ypos=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
	var env = Osc1.ar(envbuf, length*Rand(1.0,2.0), doneAction: 2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 1) * env * 0.125;
	sig = LPF.ar(sig, nyquist);
	//Out.ar(out, Pan2.ar(sig*amp, 0));
	Out.ar(out, Pan2.ar(sig*amp, LFNoise0.kr(0.8).range(-1.0,1.0)));
	Out.ar(vectorOut, sig*2);
	}).store;

//for recording zitar
SynthDef(\zitarRecorder, {|in=0 amplitudeBus fftbuf recbuf|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.15);
var amplitude = Amplitude.kr(input);

		input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,6);
//amplitude.poll;
RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
Out.kr(amplitudeBus, amplitude); }).store;


//for recording zitar
SynthDef(\busRecorder, {|in=0 amplitudeBus fftbuf recbuf|
var input = In.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.15);
var amplitude = Amplitude.kr(input);

		input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,6);
//amplitude.poll;
RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
Out.kr(amplitudeBus, amplitude); }).store;


//3rd generation granulation
SynthDef(\regranulate, {|out=0 recOut ampBus lengthBus start=0 endBus octave=1 trig=1 reverse=1 bufnum envbuf pan=0 vectorOut nyquist|
	//var trigger = EnvGen.kr(Env([0,1,0],[0.001,0.001]),trig);
	var amp = In.kr(ampBus, 1);
	var end = In.kr(endBus, 1);
	var length = In.kr(lengthBus, 1);
	var env = Osc1.ar(envbuf, length, doneAction: 2);
	var sig = BufRd.ar(1, bufnum, Phasor.ar(trig, BufRateScale.kr(bufnum)*reverse*octave,start,end ),loop: 1) * env * 0.125;
	//var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),trig, loop: 1);
	sig = LPF.ar(sig, nyquist);
	//Out.ar(out, Pan2.ar(sig * amp));
	Out.ar(out, Pan2.ar(sig * amp, LFNoise0.kr(0.9).range(-1.0,1.0)) );
	Out.ar(recOut, sig*2);
	}).store;

SynthDef(\pumper, {|in out amp=0.5|
	var input = In.ar(in, 1);
	input = Compander.ar(input, input, 0.001,1, 0.001, 0.001,0.1,1000);
	//Out.ar(out, Pan2.ar(input*amp))
	Out.ar(out,  input * amp);
		}).store;


~fftbuffers = Array.fill(2,{Buffer.alloc(s, 1024,1)});


~bike0smpls = Array.fill(2, { Buffer.alloc(s, 1.0 * s.sampleRate, 1); });
~bike1smpls = Array.fill(2, { Buffer.alloc(s, 1.0 * s.sampleRate, 1); });

~win1 = Buffer.sendCollection(s, Signal.hammingWindow(1024));

~samNum1 = 0;
~samNum2 = 0;

~fbrecBufs = Array.fill(2, { Array.fill(2, { Buffer.alloc(s, s.sampleRate * 10, 1); }); });
~recrecBufs = Array.fill(2, { Buffer.alloc(s, s.sampleRate * 10, 1); });

//samples
~firstgeneration_grainsample1 =  {  ~bike0smpls[~samNum1];      };
~firstgeneration_grainsample2 = 	 { ~bike1smpls[~samNum2] ;      };


3.0.wait;
//groups
~synthGroup2 = Group.tail(~synthGroup);
~gerriGroup = Group.new(~synthGroup2);
~noteGroups2 = Array.fill(8, { Group.new(~gerriGroup); });


	~recGroup = Group.after(~synthGroup2);
//groups for sample loopers
~playGroups = Array.fill(2, { Array.fill(2, { Group.head(~synthGroup2); }); });
~recGroups = Array.fill(2, {|i| Array.fill(2, {|j| Group.after(~playGroups[i][j]); }); });
//sampler groups
//group for resample grain loop
~recrecGroups = Array.fill(2, {|i| Group.after(~synthGroup2); });
~compressGroup = Group.after(~gerriGroup);

~sidechainBus = Bus.audio(s, 2);
~controlBus = Bus.audio(s, 2);
~snareverbBus = Bus.audio(s, 2);
~compressBus = Bus.audio(s, 2);

/*
~sideChainer.free;
~sideChainer.set(\ratio, 0.8);*/
~sideChainer = Synth(\sidechainer, [\inBus, ~sidechainBus, \controlBus, ~controlBus, \thresh, 0.1, \ratio,0.8,\volume,1.0], ~compressGroup);

//~drumcompressor.set(\ratio,0.1);

//buses for record sample loop
~vectorBuses = Array.fill(2, { Array.fill(2, { Bus.audio(s, 1); }); });

//compress buses
~compressBuses = Array.fill(8, {
	Array.fill(4, {
		Bus.audio(s, 1);}); });
~recrecbus = Array.fill(2, { Array.fill(2, { Bus.audio(s, 1); }); });

//control buses
~lengthBuses = Array.fill(4, { Array.fill(10, {Bus.control(s, 1).set(0.1)}); });
~startBuses = Array.fill(2, { Array.fill(2, { Bus.control(s, 1).set(0.0); }); });

~ampBuses = Array.fill(8, { Bus.control(s, 1).set(0.25); });

~ampBus = Array.fill(2, {  Bus.control(s,1).set(0.001); });

~endBus = [
			Bus.control(s, 1).set(~bike0smpls[~samNum1].numFrames),
			Bus.control(s, 1).set(~bike1smpls[~samNum2].numFrames) ];

~endRecBus = Array.fill(2, {|i| Bus.control(s, 1).set(~recrecBufs[i].numFrames); });

~recordBuf = Buffer.alloc(s, 1024,1);

//specs
~lengthSpec = [1.0,0.001,\exp].asSpec;
//~lengthSpec = [0.001, 1.0,\linear].asSpec;
//~endSpec = [0.001, 1.0,\linear].asSpec;
~endSpec = [1.0,0.0001,\exp].asSpec;
~clockSpec = [0.5, 3.0, \exp].asSpec;
~startSpec = [0.0,0.9,\linear].asSpec;
~vecFreqSpec = [1, 19000,\exp].asSpec;
~octaveSpec = [0,6,\linear,1,1].asSpec;
~radioplayAmpSpec = [0.5,0.1,\linear].asSpec;
//differentiate length specs
~lengthSpecs = Array.fill(10, {|i| [0.75-((i+1)/20.408163265306),0.001,\linear].asSpec; });

~chooseBus = Bus.control(s, 1).set(1);

~whatFirstGrainSample = [0,0];
~whatSecondGrainSample = [0,0];


//tempo clocks for grain patterns
~clocks = Array.fill(4, { TempoClock.new; });
~recordClock = TempoClock.new(1);
//sample buffers

//arrays for buttons / switches
~startValues = [[0.0, 0.0],[0.0,0.0]];
~reverseButtons = [[0,0],[0,0]];
~playButtons  = [[0,0],[0,0]];
~recButtons  = [[0,0],[0,0]];
~starts  = [[0,0],[0,0]];
~playSwitches = [[0,0],[0,0]];
~recSwitches = [[0,0],[0,0]];
~sampleLengths = [[1.0,1.0],[1.0,1.0]];
~octave = [[1,1],[1,1]];
~octaves = [0.0625,0.125,0.25,0.5,1,2,4];
~radioplayAmps = [[0.1,0.1],[0.1,0.1]];
//feedback gates for rec loops
~fbgates = [0,0];

//array for routine names
~routineNames = Array.fill(2,{|j| Array.fill(2, {|i| "~routineName"++j++i; }); });
~timeRoutineNames = Array.fill(2,{|j| Array.fill(2, {|i| "~timeRoutineName"++j++i; }); });


~sine = Env.sine.discretize(1024).putLast(0);
~sineEnv = Buffer.sendCollection(s, ~sine, 1);

Pbindef(\radioplaypattern).fadeTime = 0.0001;

~inSelector1 = 0;
~inSelector2 = 0;
~selectInputs = [0,0];

~drumLengthSelect = 0;
~drumSamSelect = 0;
~drumPitchSelect = 0;

	//[num,val].postln;


//Server.default.makeGui
// loop different parts in buffer
//~playGroups[0][0].set(\trig, 1);
//get start values
2.do{|i|
2.do{|j|
Routine({inf.do{
~startBuses[i][j].get({|val| ~startValues[i].put(j, (val / s.sampleRate)); });
0.01.wait; } }).play; }; };

/*
~outputs = [ [ ~compressBuses[4][0].index, ~compressBuses[5][0].index ],
	[ ~compressBuses[6][0].index, ~compressBuses[7][0].index] ];
*/


//routines for sample looping without clicks and recording
2.do{|i|

2.do{|j|
var reverse = 1, timeRoutine,timeRoutineSwitch=0,time=0.25, start=0;

Routine({
			inf.do{ var playTime = ~sampleLengths[i][j] * s.sampleRate;

//switch on&off loops - routine speed is based on length sample
if ( ~playButtons[i][j] == 1, { if ( ~playSwitches[i][j] == 0, {
		~playSwitches[i].put(j,1); "playing".postln;
		~routineNames[i][j] = Routine({ inf.do{


if ( ~octave[i][j] > 1,  { if ( ~sampleLengths[i][j] < 0.5, { ~sampleLengths[i].put(j, ~sampleLengths[i][j]*2); });
							//"tooooooo short!!!!".postln;
						});
~startBuses[i][j].get({|item| start = item; });
if ( ~octave[i][j] == 4, { if ( start > ((~sampleLengths[i][j]*s.sampleRate)-start), { start = start - ((~sampleLengths[i][j]*s.sampleRate)-start)}); });

//("start : "++start).postln;
if ( start == inf, { start = ~sampleLengths[i][j]*s.sampleRate*0.5;
"inf error".postln; });
time = (~sampleLengths[i][j] - ~startValues[i][j]) * (1/~octave[i][j]);
time = time + (time*0.05);

if ( time < 0.001, { time = 0.01});

if ( time < 0.01, { if ( start < ((~sampleLengths[i][j]*s.sampleRate)*0.8), {
							start = (~sampleLengths[i][j]*s.sampleRate)*0.8;

							 "damn".postln; }); });


								Synth(\radioplay, [\out,if ( i == 0, { ~sidechainBus }, { ~sidechainBus }); ,\amp,~radioplayAmps[i][j],\nyquist, ~nyquist,\sampleRate, s.sampleRate,
									\mainvolBus, if ( i == 0, { if ( j == 0, { ~ampBuses[2].index }, { ~ampBuses[3].index }); },
										{ if ( j == 0, { ~ampBuses[6].index }, { ~ampBuses[7].index }); }); ,
									\start,start,\bufnum, ~fbrecBufs[i][j], \end, ~sampleLengths[i][j]*s.sampleRate,\reverse,reverse,\xpan,j-1.0,\ypan,j-1.0,\octave, ~octave[i][j],
							\vectorOut,~recrecbus[i][j] ],~playGroups[i][j]);

					time.wait; } });
					~routineNames[i][j].play;
				}) },
					{ if ( ~playSwitches[i][j] == 1,
						{ ~playSwitches[i].put(j,0); ~routineNames[i][j].stop; }); });
if ( ~recButtons[i][j] == 1, {
			if ( ~recSwitches[i][j] == 0,{ ~recSwitches[i].put(j, 1);
				"recording".postln;
						Synth(\radiorecorder,[\in,~vectorBuses[i][j], \bufnum, ~fbrecBufs[i][j]],~recGroups[i][j]);
						if ( ~playSwitches[i][j] == 1, {
							~playGroups[i][j].set(\end,~sampleLengths[i][j]*s.sampleRate); ~playGroups[i][j].set(\trig, 1); });

//routine for measuring the length of recording
~timeRoutineNames[i][j] = Routine({
				inf.do{
				10000.do{|k| if ( k != 0 , {
					if ( ~recSwitches[i][j] == 0, {
					~sampleLengths[i].put(j, k * 0.001);
~playGroups[i][j].set(\start,~starts[i][j]*(~sampleLengths[i][j]*s.sampleRate),\end, ~sampleLengths[i][j]*s.sampleRate);  ~timeRoutineNames[i][j].stop;
						"stopped time routine".postln;

						}); });  0.001.wait; } } }).play;
					}); }, { if ( ~recSwitches[i][j] == 1, { ~recSwitches[i].put(j, 0);
						"sample length : ".postln; ~sampleLengths[i][j].postln;
						~startBuses[i][j].set((~starts[i][j]*~sampleLengths[i][j]*s.sampleRate).postln);
/*
~playGroups[j].set(\start,~starts[j]*(~sampleLengths[j]*s.sampleRate),\end, ~sampleLengths[j]*s.sampleRate);
*/
						~recGroups[i][j].freeAll;
						  }); });
				if ( ~reverseButtons[i][j] == 1, { if ( reverse == 1, {
					reverse = -1; if ( ~playSwitches[i][j] == 1, { ~playGroups[i][j].set(\reverse, reverse); }); }); },
			{ if ( reverse == -1, { reverse = 1;
						if ( ~playSwitches[i][j] == 1, { ~playGroups[i][j].set(\reverse, reverse); }); }); });

		0.01.wait;
	};
}).play;
	};
};
(
//clocks for speed recordings tasks
~recclockSpec = [1.0, 40.0, \exp].asSpec;

~recClocks = Array.fill(2, { TempoClock.new(8); });

~resp2 = CCResponder({|src,chan,num,val|

	if ( chan == 1, {
				[num,val].postln;
	//record live audio input for first grain pattern
	case { num == 8 } {

	if ( ~fbgates[0] == 0, {


	if ( val == 127, {

							if ( ~inSelector1 != 2, { "rec direct input 0".postln;
							~recsynth1 = Synth(\zitarRecorder, [\in,~selectInputs[0],\recbuf, ~bike0smpls[~samNum1],\fftbuf, ~fftbuffers[0]], ~recGroup);
							}, { "rec electronics".postln;
							~recsynth1 = Synth(\busRecorder,[\in, ~anaBus,\recbuf, ~bike0smpls[~samNum1],\fftbuf, ~fftbuffers[0] ],~recGroup); });

							}, { ~recsynth1.free; });
					}, {
	if ( val == 127, {

		"recording grain sample 0".postln;
						Synth(\recrecorder,[\in, ~recrecbus[1][0],\chooseBus,~chooseBus.index,
								\bufnum, ~bike0smpls[~samNum1] ],~recrecGroups[1]); });
					});

					}
//select input
	{ num == 16 }
				{ if ( ~inSelector1 != 3,
					{ ~inSelector1 = ~inSelector1 + 1; }, { ~inSelector1 = 0; });
					case
					{ ~inSelector1 == 0 } { "input recorder input 2".postln; ~selectInputs.put(0, 2);
						~firstgeneration_grainsample1 = {   ~bike0smpls[~samNum1];    }; }
					{ ~inSelector1 == 1 } { "input 1".postln; ~selectInputs.put(0, 0); }
					{ ~inSelector1 == 2 } { "input electronics".postln; ~selectInputs.put(0, ~anaBus); }
				{ ~inSelector1 == 3 } { "input 3, radio".postln; ~selectInputs.put(0, 4); };


	}


	//record live audio input for second grain pattern
	{ num == 9 } {
	if ( ~fbgates[1] == 0, {

	if ( val == 127 , {


	if ( ~inSelector2 != 2, { "rec direct input 1".postln;
	~recsynth2 = Synth(\zitarRecorder, [\in,~selectInputs[1],\recbuf, ~bike1smpls[~samNum2],\fftbuf, ~fftbuffers[0]], ~recGroup);
								},
			{ "rec electronics".postln;
							~recsynth2 = Synth(\busRecorder,[\in, ~anaBus,\recbuf, ~bike1smpls[~samNum2],\fftbuf, ~fftbuffers[0] ],~recGroup); });



						}, { ~recsynth2.free; }); }, {
	if ( val == 127, {
							"recording grain sample 1".postln;
							Synth(\recrecorder,[\in, ~recrecbus[1][1],
								\bufnum, ~bike1smpls[~samNum2] ],~recrecGroups[1]); });
				}); }
		// select input
		{ num == 17 }
				{ if ( ~inSelector2 !=3, { ~inSelector2 = ~inSelector2 + 1; }, { ~inSelector2 = 0; });
					case
					{ ~inSelector2 == 0 } { "input 2 recorder".postln; ~selectInputs.put(1, 2);
						~firstgeneration_grainsample2 = {   ~bike1smpls[~samNum2];    };
					}
					{ ~inSelector2 == 1 } { "input 1 ".postln; ~selectInputs.put(1, 1); }
					{ ~inSelector2 == 2 } { "input electronics".postln; ~selectInputs.put(1, ~anaBus); }
					{ ~inSelector2 == 3 } {  "input 3, radio".postln; ~selectInputs.put(1, 4); };
	}




	//start&stop pattern 1
	{ num == 24 } {
	"playing pattern 1".postln;
	if ( val == 127, {
10.do{|i|var pan = ((i+1)*0.1)-1,dur = 0.1 + (i*0.01);
Pbindef(("grainpattern1"++i).asSymbol,\instrument, \radioplaypattern,
\group,~synthGroup2, \out,~sidechainBus,
\nyquist, ~nyquist,
\octave, 1,
\start,0,\endBus,~endBus[0].index,\lengthBus, ~lengthBuses[0][i].index,\dur,dur,\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,
Pfunc({ ~firstgeneration_grainsample1.value}),
\envbuf, ~sineEnv,\ampBus,~ampBuses[0].index,\pan,Pwhite(pan,pan+0.1),
\vectorOut, ~vectorBuses[0][0] ).play(~clocks[0]);
};	},{ 10.do{|i| Pbindef(("grainpattern1"++i).asSymbol).pause; }; }); }
	//change speed + length grains
	{ num == 32 }
	{ ~clocks[0].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[0][i].set(~lengthSpec.map(val/127);); } }
	//end position in sample
	{ num == 0 }
				{ ~endBus[0].set(~lengthSpec.map(val/127)*(~firstgeneration_grainsample1.value).numFrames); }


//start&stop pattern 2
{ num == 25 } { if ( val == 127, {
5.do{|i|var pan = (i+1)*0.1,dur = 0.1 + (i*0.01);
Pbindef(("grainpattern2"++i).asSymbol,\instrument, \radioplaypattern,\group,~synthGroup2,
\out,~sidechainBus,
\nyquist, ~nyquist,
\octave, 1,
\start,0,
\endBus,~endBus[1].index,
\lengthBus, ~lengthBuses[1][i].index,
\dur,dur,\reverse,Pwrand([1,-1],[0.6,0.4],inf),
							\bufnum,Pfunc({~firstgeneration_grainsample2.value}),\envbuf, ~sineEnv,
							\ampBus,~ampBuses[1].index,
\vectorOut, ~vectorBuses[0][1] ).play(~clocks[1]); } },
		{ 10.do{|i| Pbindef(("grainpattern2"++i).asSymbol).pause; }; }); }
	//change speed + length grains
	{ num == 33 }
	{ ~clocks[1].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[1][i].set( ~lengthSpec.map(val/127).postln; ); }; }
	//change end position grain pattern
	{ num == 1 }
	{ //~length2 = ~lengthSpec.map(val/127).postln;
		~endBus[1].set(~lengthSpec.map(val/127)*(~firstgeneration_grainsample2.value).numFrames);
	}
	//3rd granular pattern samples the sampler
	//start&stop pattern
	{ num == 28 } { if ( val == 127, {
"pattern3 started".postln;
5.do{|i|var pan = ((i+1)*0.19)-1;
Pbindef(("grainpattern3"++i).asSymbol,\instrument, \regranulate,
\group,~synthGroup2,
\nyquist, ~nyquist,
\ampBus,~ampBuses[4].index,
\out, ~sidechainBus,
\octave, 1,
\start,0,
\endBus,~endRecBus[0].index,
\lengthBus, ~lengthBuses[2][i].index,
\dur,0.1,
\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,~recrecBufs[0],\envbuf, ~sineEnv,\pan,Pwhite(pan,pan+0.1),
				\recOut, ~vectorBuses[1][0] ).play(~clocks[2]);
};	},
	{ 10.do{|i| Pbindef(("grainpattern3"++i).asSymbol).stop;};	"pattern 3 stopped".postln; }); }
	{ num == 36 }
	{
		~clocks[2].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[2][i].set(~lengthSpecs[i].map(val/127);); }
	}
	{ num == 4 }
	{ ~endRecBus[0].set( ((~lengthSpec.map(val/127))*~recrecBufs[0].numFrames).postln;); }

{ num == 20 }
	{ if ( val == 127, { ~durVar3 = Routine({ inf.do{ 100.do{|i| var dur = ~clocks[2].tempo.reciprocal*0.5, time = 0.001 + rrand(0.0001,0.001);
		10.do{|i|
			~lengthBuses[2][i].set(rrand(dur*0.001,dur)); }; time.wait; } }}).play; "dur routine playing".postln; },
		{ ~durVar3.stop; "dur routine stop".postln; });
	}

{ num == 29 } { if ( val == 127, {
"pattern4 started".postln;
5.do{|i|var pan = ((i+1)*0.19)-1,dur = 0.1 + (i*0.001);
Pbindef(("grainpattern4"++i).asSymbol,
\instrument, \regranulate,
\group,~synthGroup2,
\nyquist, ~nyquist,
\ampBus,~ampBuses[5].index,
\out, ~sidechainBus,
\octave, 1,
\start,0,
\endBus,~endRecBus[1].index,
\lengthBus, ~lengthBuses[3][i].index,
\dur,0.1,
\reverse,Pwrand([1,-1],[0.6,0.4],inf),
\bufnum,~recrecBufs[1],\envbuf, ~sineEnv,
				\recOut, ~vectorBuses[1][1]).play(~clocks[3]);
};	},
		{ 10.do{|i| Pbindef(("grainpattern4"++i).asSymbol).stop;};	"pattern 4 stopped".postln; }); }
{ num == 37 }
{
		~clocks[3].tempo = ~clockSpec.map(val/127).postln;
		10.do{|i| ~lengthBuses[2][i].set(~lengthSpecs[i].map(val/127);); }
}
{ num == 5 }
{
		~endRecBus[1].set( ((~lengthSpec.map(val/127))*~recrecBufs[1].numFrames).postln;);
}

{ num == 21 }
	{ if ( val == 127, { ~durVar = Routine({ inf.do{ 100.do{|i| var dur = ~clocks[3].tempo.reciprocal*0.5, time = 0.001 + rrand(0.0001,0.001);
		10.do{|i|
			~lengthBuses[3][i].set(rrand(dur*0.001,dur)); }; time.wait; } }}).play; "dur routine playing".postln; },
		{ ~durVar4.stop; "dur routine stop".postln; });
	}
	//record sampler for grain pattern 3
	{ num == 12 } { "rec 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][0], \bufnum, ~recrecBufs[0]],~recrecGroups[0]); }
	//record sampler for grain pattern 4
	{ num == 13 } { "rec 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][1], \bufnum, ~recrecBufs[1]],~recrecGroups[1]); };





if ( num == 10,
		{  if ( val == 127, {"sampling grain pattern 1".postln;~recButtons[0].put(0,1); },{ ~recButtons[0].put(0,0); }); });
	//play sample
	if ( num == 18,
		{ if ( val == 127, { "playing grain loop 1".postln;~playButtons[0].put(0,1); },{ "stopped grain loop 1".postln; ~playButtons[0].put(0,0); }); });
	//reversed on / off
	if ( num == 26,
		{ if ( val == 127, { "reverse on".postln; ~reverseButtons[0].put(0,1) }, { "reverse off".postln; ~reverseButtons[0].put(0,0) }); });
	//set start position
	if ( num == 34, { ~starts[0].put(0, ~startSpec.map(val/127); ); ~starts[0][0].postln;
		~startBuses[0][0].set(~starts[0][0]*~sampleLengths[0][0]*s.sampleRate);
		~radioplayAmps[0].put(0, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[0][0].postln;
	});
	//octave shifting
	if ( num == 2, {
		~octave[0].put(0, ~octaves[~octaveSpec.map(val/127)];); ~octave[0][0].postln;
		if ( ~playSwitches[0][0] == 1, {
			~playGroups[0][0].set(\octave, ~octave[0][0]); }); });
	//record sample 2 from grain pattern 2
	if ( num == 11, {
		if ( val == 127, { "sampling grain pattern 2".postln; ~recButtons[0].put(1,1); },{ ~recButtons[0].put(1,0); });});
	if ( num == 19, { if ( val == 127, { "playing grain loop 2".postln; ~playButtons[0].put(1,1); }, { ~playButtons[0].put(1,0); });});
	//reversed on /off
	if ( num == 27,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[0].put(1,1); },{ "reverse off".postln; ~reverseButtons[0].put(1, 0); });});
	//set start position
	if ( num == 35, {
	~starts[0].put(1, ~startSpec.map(val/127) ); ~starts[0][1].postln;
	~startBuses[0][1].set(~starts[0][1]*~sampleLengths[0][1]*s.sampleRate);
	~radioplayAmps[0].put(1, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[0][1].postln;
	});
	//octave shifting
	if ( num == 3, {
		~octave[0].put(1, ~octaves[~octaveSpec.map(val/127)]); ~octave[0][1].postln;
		if ( ~playSwitches[0][1] == 1, {
			~playGroups[0][1].set(\octave, ~octave[0][1]); }); });
	//SECOND
		if ( num == 14,
		{  if ( val == 127, {"sampling grain pattern 1".postln;~recButtons[1].put(0,1); },{ ~recButtons[1].put(0,0); }); });
	//play sample
	if ( num == 22,
	{ if ( val == 127, { "playing grain loop 1".postln;~playButtons[1].put(0,1); },{ "stopped grain loop 1".postln; ~playButtons[1].put(0,0); }); });
	//reversed on / off
	if ( num == 30,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[1].put(0,1) }, { "reverse off".postln; ~reverseButtons[1].put(0,0) }); });
	//set start position
	if ( num == 38, { ~starts[1].put(0, ~startSpec.map(val/127); ); ~starts[1][0].postln;
		~startBuses[1][0].set(~starts[1][0]*~sampleLengths[1][0]*s.sampleRate);
		~radioplayAmps[1].put(0, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[1][0].postln;
	});
	//octave shifting
	if ( num == 6, {
		~octave[1].put(0, ~octaves[~octaveSpec.map(val/127)];); ~octave[1][0].postln;
		if ( ~playSwitches[1][0] == 1, {
			~playGroups[1][0].set(\octave, ~octave[1][0]); }); });
	//record sample 2 from grain pattern 2
	if ( num == 15, {
		if ( val == 127, { "sampling grain pattern 2".postln; ~recButtons[1].put(1,1); },{ ~recButtons[1].put(1,0); });});

	//play sample loop
	if ( num == 23, { if ( val == 127, { "playing grain loop 2".postln; ~playButtons[1].put(1,1); }, { ~playButtons[1].put(1,0); });});
	//reversed on /off
	if ( num == 31,
	{ if ( val == 127, { "reverse on".postln; ~reverseButtons[1].put(1,1); },{ "reverse off".postln; ~reverseButtons[1].put(1, 0); });});
	//set start position
	if ( num == 39, {
		~starts[1].put(1, ~startSpec.map(val/127) ); ~starts[1][1].postln;
		~startBuses[1][1].set(~starts[1][1]*~sampleLengths[1][1]*s.sampleRate);
		~radioplayAmps[1].put(1, ~radioplayAmpSpec.map(val/127); ); ~radioplayAmps[1][1].postln;
	});
	//octave shifting
	if ( num == 7, {
		~octave[1].put(1, ~octaves[~octaveSpec.map(val/127)]); ~octave[1][1].postln;
		if ( ~playSwitches[1][1] == 1, {
			~playGroups[1][1].set(\octave, ~octave[1][1]); }); });
	//rec loops
	if ( num == 100, {
		if ( val == 127, { "rec loop 0 running".postln;
	~recRoutine0 = Routine({
				inf.do{
		"recording sample loop 0".postln;
		~recButtons[0].put(0,1);
		rrand(0.5,2.0).wait;
		"stopped recording sample loop 0".postln;
		~recButtons[0].put(0,0);
		rrand(0.5,2.0).wait;
		"recording grain sample 1".postln;
		Synth(\recrecorder,[\in, ~recrecbus[0][0], \bufnum, ~recrecBufs[0]],~recrecGroups[0]);
		rrand(0.5,2.0).wait;
		"recording sample loop 1".postln;
		~recButtons[1].put(0,1);
		rrand(0.5,2.0).wait;
		"stopped recording sample loop 0".postln;
		~recButtons[1].put(0,0);
		rrand(0.5,2.0).wait;
		if ( ~fbgates[0] == 1, {
		"recording grain sample 0".postln;

						Synth(\recrecorder,[\in, ~recrecbus[1][0],\chooseBus,~chooseBus.index,
							\bufnum, ~bike0smpls[~samNum1] ],~recrecGroups[1]);
						1.0.wait;
						10.do{|i| Pbindef(("grainpattern1"++i).asSymbol,\bufnum,~bike0smpls[~samNum1] ); };
					});
				}
				}).play(~recClocks[0]); }, { "rec loop 0 stopped".postln; ~recButtons[0].put(0,0); ~recButtons[0].put(1,0); ~recRoutine0.stop; }); } );
		if ( num == 101, {
		if ( val == 127, { "rec loop 1 running".postln;
		~recRoutine1 = Routine({
	inf.do{

		~recButtons[0].put(1,1);
		rrand(0.5,2.0).wait;
		~recButtons[0].put(1,0);
		rrand(0.5,2.0).wait;
		Synth(\recrecorder,[\in, ~recrecbus[0][1], \bufnum, ~recrecBufs[1]],~recrecGroups[0]);
		rrand(0.5,2.0).wait;
		~recButtons[1].put(1,1);
		rrand(0.5,2.0).wait;
		~recButtons[1].put(1,0);
		rrand(0.5,2.0).wait;
		if ( ~fbgates[1] == 1, {

		Synth(\recrecorder,[\in, ~recrecbus[1][1],
							\bufnum, ~bike1smpls[~samNum2] ],~recrecGroups[1]);
							1.0.wait;
								10.do{|i| Pbindef(("grainpattern2"++i).asSymbol,\bufnum,~bike1smpls[~samNum2]  ); };
			 });
	}
}).play(~recClocks[1]);
 }, { "rec loop 1 stopped".postln; ~recButtons[1].put(0,0); ~recButtons[1].put(1,0); ~recRoutine1.stop; }); } );
//open close feedback gates
	if ( num == 106, {
		if ( val == 127, {"gate 0 opened".postln; ~fbgates.put(0, 1); },
			{"gate 0 closed".postln; ~fbgates.put(0, 0); }); });
	if ( num == 107, {
		if ( val == 127, {"gate 1 opened".postln; ~fbgates.put(1, 1); },
			{"gate 1 closed".postln; ~fbgates.put(1, 0); }); });


	//second sampler

				});
});
);













};

);