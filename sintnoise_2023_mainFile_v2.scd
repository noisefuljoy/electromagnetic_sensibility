
/*
1. atmosferisch granulair - hydrofonische geluiden met morse code
2. minimalistische ritmes met monome
3. elektromagnetische laag / kick met stoom
4.
5. joystick controller data mayhem

*/
/*
frequentie op web sdr: 7074.72
14075.00

THIS ONE WORKS NOW:
13659.72

chinese radioL
13600.15
turkish radio:
13633.86


To do:
controllers overzichtelijker. 1 minder?
nanopad vervangen door monome?
microtonale synth patch op monome voor Dragons a la minilogue
monome microtonale tune switch
monome rec sample buf switch
----
Spiral checken



*/
(

fork{
Require("/home/numina/repos/electromagnetic_sensibility/sintnoise_2023_synthdefs_tunings.scd");
2.0.wait;
/*	"./pulsejack".unixCmd;
	"jack_connect SuperCollider:out_1 system:playback_1".unixCmd;
	"jack_connect SuperCollider:out_2 system:playback_2".unixCmd;*/


MIDIClient.init;
MIDIIn.connectAll;
	// 5.0.wait;
	//
	// Require("D:/Dropbox/PROJECTS/SC_performances/tenori-on/Ansage_Ende_01052021/animals_grainpatch_v5.scd");

4.0.wait;
//s.latency = nil;
//stereo
~channels = Array.fill(16,{ 0});
	//multichannel (to mixer)
//~channels = [0,2,4,6,7,8,9];

~synthGroup = Group.new;
~percGroup = Group.tail(~synthGroup);
~insects = Group.tail(~synthGroup);

~recGroup = Group.after(~synthGroup);
~effectGroup = Group.after(~synthGroup);
~effectGroup2 = Group.after(~effectGroup);

~transformChain1 = Group.after(~percGroup);
~transformChain2 = Group.after(~percGroup);
~transformChain3 = Group.after(~percGroup);
~transformChain4 = Group.after(~percGroup);
~transBuses = Array.fill(4, { Bus.audio(s, 1); });



/* transform synth*/
/*
~trans1 = Synth(\transform1, [\in, ~transBuses[0]], ~transformChain1);
~trans2 = Synth(\transform2, [\in, ~transBuses[1]], ~transformChain2);
~trans3 = Synth(\transform3, [\in, ~transBuses[2]], ~transformChain3);
~trans4 = Synth(\transform4, [\in, ~transBuses[3]], ~transformChain4);
*/

~synthChooser = 1;

~notes = Array.fill(16, { nil!128 });
~noteGroups = Array.fill(16, { Group.new(~synthGroup); });


/*BUSES*/
~anaBus = 8;
~tenvolBus = Bus.audio(s, 2);


~combBus = Bus.audio(s, 1);
~combBus2 = Bus.audio(s, 1);
/*for toy piano */
~toycombBus = Bus.audio(s, 1);
/* for tape grin */
~tapecombBus = Bus.audio(s, 1);

~percBus = Bus.audio(s, 1);
~percGrainBus = Bus.audio(s, 1);

~dronesideBus = Bus.audio(s, 1);
~droneverbBus = Bus.audio(s, 2);
~toypianoverbBus = Bus.audio(s, 1);
~voiceverbBus = Bus.audio(s, 1);
~slenverbBus = Bus.audio(s, 1);
~sineverbBus = Bus.audio(s, 1);
~sawverbBus = Bus.audio(s, 1);
~pulseBus = Bus.audio(s, 2);
~crushBus = Bus.audio(s, 1);

/*control buses */
~maingrainDurBus = Bus.control(s, 1).set(0.5);
~fmodBus = Bus.control(s, 1).set(0.01);
~widthBus = Bus.control(s, 1).set(0.5);
~phasemodBus = Bus.control(s,1).set(0.1);
~bpmodBus = Bus.control(s,1).set(0.1);
~fmfreqBus = Bus.control(s, 1).set(10);
~fmindexBus = Bus.control(s, 1).set(0.01);
~fmfreqBus2 = Bus.control(s, 1).set(10);
~fmindexBus2 = Bus.control(s, 1).set(0.01);

~ampVBus = Bus.control(s, 1).set(0); //bus for switching amplitude variation
~srBus = Bus.control(s, 1).set(48000);
~pitchBus = Bus.control(s, 1);

//~combC.free
//~crusher.free;
/* EFFECT SYNTHS */

// a custom envelope
~winenv = Env([0, 1, 0], [3, 1], [8, -8]);
~wenv = Buffer.sendCollection(s, ~winenv.discretize, 1);

//SAMPLES
/* BUFFERS for recording */
~recBufs = [Buffer.alloc(s, s.sampleRate*2,1), Buffer.alloc(s, s.sampleRate*2,1)];
~recBufs2 = [Buffer.alloc(s, s.sampleRate*2,1), Buffer.alloc(s, s.sampleRate*2,1)];
~recBufs3 = [Buffer.alloc(s, s.sampleRate*2,1), Buffer.alloc(s, s.sampleRate*2,1)];
~playBuf = ~recBufs[0];

~fftBuf = Buffer.alloc(s, 1024, 1);
~fftBuf2 = Buffer.alloc(s, 1024, 1);
~fftBuf3 = Buffer.alloc(s, 1024, 1);

~recFreqBus = [Bus.control(s, 1), Bus.control(s, 1)];
~recFreqBus2 = [Bus.control(s, 1), Bus.control(s, 1)];
~recFreqArr = Array.fill(2, { 0});
~grainFreqArray = Array.fill(2, {0 });

//windows for grains
~win1 = Buffer.sendCollection(s, Signal.hammingWindow(1024));
~win2 = Buffer.sendCollection(s, Signal.hanningWindow(1024));
~win3 = Buffer.sendCollection(s, Signal.welchWindow(1024));

3.0.wait;
~baseFreqs = [32.7, 65.41, 130.81, 261.63, 523.25];


~whatDrone = 0;
~whatSlen = 0;
~scaleNum = 0;

~typeScale = ~oton;
~typeScaleNum = 0;
~scale = ~typeScale[~scaleNum];
~scale = ~micro[0];
~index = 1;
~index2 = 0;
~index3 = 0;
~playBuf = ~recBufs[0];
~pelogChoose = 0;
~myscaleChoose = 0;
~myscaleChoose2 = 0;
~whatBuf = 0;
~whatMalm = 0;
~whatBallBuf = 0;
~sampleColState = 0;
~sampleCol = ~harpsi;
~sampleBallCol = ~harpsi;
//duration for drones
~dur = 2.0;
~grainAmp = 0.1;
~durSpec = [0.001, 2.0,\exp,0.001,2.0].asSpec;
~ampSpec = [0.004,0.05,\exp].asSpec;

~grainDurSpec = [2.0,0.01,\exp].asSpec;
~grainAmpSpec = [0.025,0.035,\exp].asSpec;
~maingrainDurSpec = [4.0,0.01,\exp].asSpec;
~droneMul = 0.5;
~droneMulChoose = 0;
~dronemularr = [0.5,1,0.25];

~ffreqSpec = [250,8000,\linear].asSpec;
~srateSpec = [250,32000,\exp].asSpec;

~widthSpec = [0.01,0.99,\exp].asSpec;
~fmodSpec = [0.001,300.0,\exp].asSpec;
~phasemodSpec = [0.01,80.0,\exp].asSpec;
~bpmodSpec = [0.01,500.0, \linear].asSpec;
~fmfreqSpec = [1.0,100,\linear].asSpec;
~fmindexSpec = [0.0,1,\linear].asSpec;

~modRange = [0.001, 9, \exp, 0.001].asSpec;
~ampRange = [0.25, 1.0, \linear, 0.001].asSpec;
~relRange = [0.1, 2.0, \linear, 0.001].asSpec;
~decRange = [0.001, 30.0, \exp, 0.001].asSpec;
~ratioSpec = [0, 15, \linear, 1].asSpec;


2.0.wait;
~defChoose = 0;


Require("/home/numina/repos/electromagnetic_sensibility/sintnoise_2023_grains.scd");
4.0.wait;
Require("/home/numina/repos/electromagnetic_sensibility/sintnoise_2023_extreme3d.scd");
2.0.wait;
Require("/home/numina/repos/electromagnetic_sensibility/sintnoise_2023_monome.scd");
2.0.wait;




	~fcricket_trigBus = Bus.control(s, 1).set(58.82);
	~cicada_trigBus = Bus.control(s, 1).set(0.2);

	~percReleaseBus = Bus.control(s, 1).set(0.001);


	~phasemIndexBus = Bus.control(s, 1).set(0);
	~phaseModFreq = Bus.control(s, 1).set(8);

	~phasemIndexSpec = [0.01, 1000.0, \linear, 0.01].asSpec;
	~freqRange = [100, 800, \linear, 10].asSpec;
	~releaseRange = [0.1,1.0, 5, 0.001].asSpec;
	~relmulSpec = [1.0, 10.0, \exp, 0.001].asSpec;

	~fcrickets_trigSpec = [58.82, 400.0, \linear, 0.01].asSpec;
	~cicada_trigSpec = [0.001, 80.0, \linear, 0.01].asSpec;
	~relMul = 1;

/*fade in sdr */
	~radio_sample_picker = 0;
	~radio_sample_pick = ~radio_samples[5];
	// ~radio_sample_pick = ~radio_samples[5];
MIDIdef.cc(\white_control, {|val, num, cc, chan|
	[val, num,cc, chan].postln;
	case
	/*fading web sdr */
	{ num == 46 } { if ( val == 127, {

			"fading in morse sample".postln;

Ndef(\sdr_morse).fadeTime = 32;

Ndef(\sdr_morse, {

	//var sig = SoundIn.ar([4,5],0.2);
	// voor morse 3 voor stem 5
	var sig = PlayBuf.ar(1, ~radio_samples[4];, BufRateScale.kr(~radio_samples[4];), 1, 0, loop: 1);

	sig = LPF.ar(sig, 9000, 1.2);
	//Pan2.ar(sig, SinOsc.kr(LFNoise0.kr(0.2).range(0.01,30.0)).range(-0.6,0.3));
	//Pan2.ar(PitchShift.ar(sig, 0.2, LFNoise1.kr(0.2).range(0.92,1.15),0.3,0.2);, SinOsc.kr(LFNoise0.kr(0.2).range(0.01,30.0)).range(0.6,-0.3));

	sig = [sig, PitchShift.ar(sig, 0.2, LFNoise1.kr(0.2).range(0.92,1.15),0.3,0.4);];


}).play;
	}, {
		"fading out morse sample".postln;
		Ndef(\sdr_morse).free;

	}); }
	{ num == 47 } { if ( val == 127, {

			"fading in radio sample".postln;

Ndef(\sdr).fadeTime = 32;

Ndef(\sdr, {

	//var sig = SoundIn.ar([4,5],0.2);
	// voor morse 3 voor stem 5
	var sig = PlayBuf.ar(1, ~radio_sample_pick, BufRateScale.kr(~radio_sample_pick), 1, 0, loop: 1);

	sig = LPF.ar(sig, 9000, 1.2);
				sig = [sig, PitchShift.ar(sig, 0.2,0.95,0.1,0.0);];

}).play;
	}, {
		"fading out radio sample".postln;
		Ndef(\sdr).free;

	}); }
	// comb delay on percussion //
	{ num == 1 } { ~combPerc.set(\mix, val/127); }
	{ num == 57 } { ~combPerc.set(\decay, ~decRange.map(val/127);  ); };

});

MIDIdef.cc(\secondController, {|val, num, cc, chan|
		[val, num, cc, chan].postln;

		case
		/*
		{ num == 82 }
		{ ~phasemIndexBus.set(~phasemIndexSpec.map(val/127)); "setting phase index".postln; }
		{ num == 50 }
		{ ~relMul = ~relmulSpec.map(val/127); "increasing perc rel".postln; }
		*/
		{ num == 76 }
		{ if ( val == 127, { 	~fieldcricket = Synth(\fieldcricket, [\tfreqBus, ~fcricket_trigBus.index, \recout, ~anaBus], ~insects); }, { ~fieldcricket.set(\gate, 0); }); }
		{ num == 84 }
		{
			~fcricket_trigBus.set( ~fcrickets_trigSpec.map(val/127));
		}
		{ num == 77 }
		{ if ( val == 127, { 	~cicada_3calls = Synth(\cicada_3calls, [\tfreqBus, ~cicada_trigBus.index, \recout, ~anaBus], ~insects); }, { ~cicada_3calls.set(\gate, 0); }); }
		{ num == 85 }
		{
			~cicada_trigBus.set( ~cicada_trigSpec.map(val/127));
		}

		}, chan: 0);



};
)
