(
fork {
//SYNTHDEFS
/*
SynthDef(\perc, {|out=0 amp=0.5 release=0.2 bufnum pan=0 phasemIndexBus|
	var env, sig,phasemIndex;
	phasemIndex = In.kr(phasemIndexBus, 1);
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	//sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	sig = SinOsc.ar(440, LFSaw.kr(LFNoise0.kr(16.8).range(0.1,85.0),mul:phasemIndex).range(-2pi,2pi),0.5);
	Out.ar(out, sig*env*amp); }).store;
	*/

/*

SynthDef(\perc_effect, {|in=0 out=0 amp=1.0 mix=0.0 decay=1|
	var sig,drysig, wetsig;
	drysig = In.ar(in, 1);
	wetsig = drysig;
	3.do{|i| var del = (i+1)*0.1;
		wetsig = CombL.ar(wetsig, del, SinOsc.kr(del*0.1).range(del*0.1,del),(i+1)*decay,0.4,wetsig*0.6);
	};
	sig = ((1-mix)*drysig) + (mix*wetsig);
	Out.ar(out, Pan2.ar(sig*amp, SinOsc.kr(LFNoise0.kr(0.8).range(0.1,80.0)).range(-0.25,0.25)));
}).store;*/

SynthDef(\analysis, {|input=0 ampBus freqBus|
	var sig,amp,freq,hasFreq;
	sig = In.ar(input,1);
		amp = Amplitude.kr(sig);
		# freq, hasFreq = Pitch.kr(sig);
		//amp.poll;
		//freq.poll;
		Out.kr(ampBus, amp);
		Out.kr(freqBus, freq);
	}).store;

SynthDef(\tenorigrainsampler, {|anaBus out amp envbuf bufnum freq realFreq dur=1 pos=0|
	var freqRatio, env, sig;
	freqRatio = (freq/realFreq);
	env = Osc1.ar(envbuf, dur,doneAction:2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio,1,pos,loop:1);
	sig = sig * env * amp;
	Out.ar(out, Pan2.ar(sig) );
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorimonograinsampler, {|out anaBus amp envbuf bufnum freq realFreq dur=1 pos=0|
	var freqRatio, env, sig;
	freqRatio = (freq/realFreq);
	env = Osc1.ar(envbuf, dur,doneAction:2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio,1,pos,loop:1);
	sig = sig * env * amp;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorigrainsampler2, {|anaBus out amp envbuf bufnum freq realFreq=220 dur=1 pos=0|
	var freqRatio, env, sig;
	freqRatio = (freq/realFreq);
	env = Osc1.ar(envbuf, dur,doneAction:2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio,1,pos,loop:1);
	sig = sig *env * amp;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorikick, {|anaBus out amp=0.5 bufnum rel=0.35 gate=1|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.01,rel),gate,doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),loop:0);
	sig = sig*env*amp;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorikick2, {|anaBus out amp=0.5 bufnum rel=0.35 gate=1|
	var env, sig;
	env = EnvGen.ar(Env.perc(0.01,rel),gate,doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),loop:0);
	sig = sig*env*amp;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenoriPulse, {|anaBus out amp=0.25 freq rel=0.001 gate=1 widthBus fmodBus pan=0|
	var env, sig,sig1,sig2,sig3,width,fmod;
	env = EnvGen.ar(Env.adsr(0.01,0.001,0.5,rel),gate,doneAction: 2);
	width = In.kr(widthBus, 1);
	fmod = In.kr(fmodBus, 1);

	sig = Pulse.ar(freq,width);
	sig = MoogFF.ar(sig, SinOsc.kr(fmod).range(30,900),3.5,0,2.0,sig*0.25);
	sig = Decimator.ar(sig, SinOsc.kr(fmod).range(100,7500),Rand(3,24));

	sig = Compander.ar(sig, sig, LFNoise0.kr(0.4).range(0.001,0.9),1, LFNoise2.kr(0.4).range(0.001,1.0),0.001,0.1,10);

		//sig = LPF.ar(sig, 1000);
		sig = LPF.ar(sig, 1000,3);
		sig = Compander.ar(sig, sig, 0.001,1,0.001,0.001,0.1,1000);
		sig = Limiter.ar(sig,1);

	sig = sig * env * amp;
	Out.ar(out, Pan2.ar(sig,FSinOsc.kr(Rand(0.01,0.35)).range(-1.0,1.0)));
	Out.ar(anaBus, sig);
	//Out.ar(out, Pan2.ar(sig2*env*amp*1,0));
	//Out.ar(out, Pan2.ar(sig3*env*amp*0.5,0));
}).store;

SynthDef(\tenoriSine, {|anaBus out amp=0.25 freq rel=0.001 gate=1 width=0.25 pan=0 phasemodBus bpmodBus|
	var env, sig,sig1,sig2,sig3,phaseMod, bpMod;
	phaseMod = In.kr(phasemodBus, 1);
	bpMod = In.kr(bpmodBus, 1);
	env = EnvGen.ar(Env.adsr(0.001,0.001,0.5,rel),gate,doneAction: 2);
	sig = SinOsc.ar([freq*LFNoise0.kr(bpMod*0.001).range(0.48,0.51),freq,freq*LFNoise1.kr(bpMod*0.002).range(1.99,2.03)],
		SinOsc.kr(phaseMod).range(-2pi,2pi)!3,0.25).tanh;
	//sig = Mono(sig);
	sig = Mix(sig);
	sig = BPF.ar(sig, freq*0.5,SinOsc.kr(bpMod).range(0.05,0.15),2.5);
	//sig = Ringz.ar(sig, LFNoise2.kr(freq*0.01).range(freq*0.25,freq*0.5),SinOsc.kr(freq*0.01).range(1,10));
	//sig = MoogLadder.ar(sig,SinOsc.kr(Rand(0.05,0.35)).range(500,2500),Rand(0.1,0.5));

	//sig2 = MoogFF.ar(sig[1],SinOsc.kr(0.4).range(100,1500),2);
	//sig3 = MoogFF.ar(sig[0],SinOsc.kr(0.6).range(100,1750),2);
	sig = Limiter.ar(sig);
	sig = sig * env * amp;
	Out.ar(out, sig);
	//Out.ar(anaBus, sig);
	//Out.ar(out, Pan2.ar(sig2*env*amp*1,0));
	//Out.ar(out, Pan2.ar(sig3*env*amp*0.5,0));
}).store;


SynthDef(\tenoriSaw, {|anaBus out amp=0.25 freq rel=0.1 gate=1 width=0.25,pan=0 fmfreqBus fmindexBus|
	var env, sig,sig1,sig2,sig3,ampComp,fmfreq,fmindex;
	fmfreq = In.kr(fmfreqBus, 1);
	fmindex = In.kr(fmindexBus, 1);
	env = EnvGen.ar(Env.adsr(0.01,0.01,0.5,rel),gate,doneAction: 2);
	sig = VarSaw.ar(freq*Pulse.kr(fmfreq,0.5,fmindex,1) ,0,SinOsc.kr(freq*0.001).range(0.1,0.9));

	sig = MoogVCF.ar(sig,SinOsc.ar(Rand(0.05,0.35)).range(freq*0.5,freq*2.5),Rand(0.5,0.8),sig*0.75,sig*0.25);
	sig = LPF.ar(sig, SinOsc.kr(freq*0.001).range(800,1500),3);
	ampComp = AmpComp.kr(freq);

	sig = sig*env*amp*ampComp;
	Out.ar(out, sig);
	//Out.ar(anaBus, sig);

}).store;

SynthDef(\tenoriTri, {|anaBus out amp=0.25 freq rel=0.1 gate=1 width=0.25,pan=0 fmfreqBus fmindexBus|
	var env, sig,sig1,sig2,sig3,ampComp,fmfreq,fmindex;
	fmfreq = In.kr(fmfreqBus, 1);
	fmindex = In.kr(fmindexBus, 1);
	env = EnvGen.ar(Env.adsr(0.01,0.01,0.5,rel),gate,doneAction: 2);
	sig = LFTri.ar(freq*SinOsc.kr(fmfreq,0.5,fmindex,1));

	//sig = MoogVCF.ar(sig,SinOsc.ar(Rand(0.05,0.35)).range(freq*0.5,freq*2.5),Rand(0.5,0.8),sig*0.75,sig*0.25);
	//sig = LPF.ar(sig, SinOsc.kr(freq*0.001).range(800,1500),3);
	ampComp = AmpComp.kr(freq);

	sig = sig*env*amp*ampComp;
	Out.ar(out, sig);
	//Out.ar(anaBus, sig);

}).store;


//a = Synth(\tenoriSaw,[\freq,110]);
//a.free;
/*
SynthDef(\tenori_recorder, {|in=0 amplitudeBus fftbuf recbuf|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,0.1);
//var amplitude = Amplitude.kr(input);
//input = Compander.ar(input, input, 0.1,1,0.1,0.001,0.1,5);
//amplitude.poll;
	input = Limiter.ar(input, 0.5);
	RecordBuf.ar(input, recbuf,loop:0,trigger:1,doneAction: 2);
	//Out.kr(amplitudeBus, amplitude);

}).store;
*/
SynthDef(\tenori_recorder, {|in=0 fftbuf recbuf thresh=0.3|
var input = SoundIn.ar(in);
var chain = FFT(fftbuf, input);
var onsets = Onsets.kr(chain,thresh);
input = Compander.ar(input, input, 0.01,1,0.01,0.005,0.1,25);
//amplitude.poll;
	RecordBuf.ar(input, recbuf,loop:0,trigger:onsets);
 }).store;


SynthDef(\pitchFinder, {|outBus amp=0.25 bufnum dur=10.0|
	var sig, freq,env;
	env = EnvGen.kr(Env([1,0],[dur]),1,doneAction:2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum),1,0,0,doneAction: 2);
	//freq = AverageOutput(Pitch.kr(sig).at(0));
	freq = AverageOutput.kr(Pitch.kr(sig).at(0));

	Out.kr(outBus, freq);
	//Out.ar(0,sig);
	//freq.poll;
}).store;



SynthDef(\tenorisampler, {|anaBus out amp=0.5 durBus bufnum envbuf freq realFreq gate=1 sideout=30|
	var freqRatio, env, sig, dur;
		dur = In.kr(durBus, 1);
	freqRatio = (freq/realFreq);
	//env = EnvGen.ar(Env.adsr(0.001,0.0,0.5,0.1),gate, doneAction: 2);
	env = Osc1.ar(envbuf, dur,doneAction:2);
		sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio, 1, Rand(0.0,0.9)*BufFrames.ir(bufnum) );
	sig = sig*env*amp;
	Out.ar(out, sig);
	//Out.ar(anaBus, sig);
	//Out.ar(sideout, sig);
}).store;


SynthDef(\tenorisamplermono, {|anaBus out amp durBus bufnum envbuf freq realFreq gate=1|
	var freqRatio, env, sig,dur;
		dur = In.kr(durBus, 1);
	//freqRatio = (freq/realFreq);
	freqRatio = 1;
	env = Osc1.ar(envbuf, dur,doneAction:2);
	//env = EnvGen.ar(Env.adsr(0.001,0.0,0.5,0.1),gate, doneAction: 2);
		sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio, startPos: Rand(0.0,0.9)* BufFrames.ir(bufnum),loop: 1 );
	sig = sig * env * amp * 1;
	Out.ar(out, Pan2.ar(sig));
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorisamplermonorecord, {|anaBus out amp bufnum freq realFreq=220 gate=1|
	var freqRatio, env, sig;
	freqRatio = (freq/realFreq);
	//freqRatio = 1;
	env = EnvGen.ar(Env.adsr(0.001,0.0,0.5,0.1),gate, doneAction: 2);
	sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*freqRatio);
	sig = sig*env*amp * 1;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\tenorichaos, {|anaBus out amp freq gate=1|
	var sig,env;
	sig = Gendy1.ar(4,2,1,3,freq,freq*1.5);
	sig = LPF.ar(sig, 800);
	env = EnvGen.ar(Env.adsr(0.075,0.1,0.5,0.01),gate, doneAction: 2);
	sig = sig * amp * env;
	Out.ar(out, Pan2.ar(sig));
	Out.ar(anaBus, sig);
}).store;



SynthDef(\tenoriDrone, {|anaBus out amp bufnum freq realFreq gate=1|
	var freqRatio, env, trigger, sig;
	freqRatio = (freq/realFreq);
	trigger = Impulse.kr(freq);

	env = EnvGen.ar(Env.adsr(0.01,0.1,0.5,0.2),gate, doneAction: 2);
/*
	sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*freqRatio,0,LFNoise0.kr(3.2).range(0.0,BufFrames.kr(bufnum)),loop:1);

	*/
	sig = TGrains.ar(2, trigger, bufnum, BufRateScale.kr(bufnum)*freqRatio,LFNoise0.kr(3.2).range(0.0,BufFrames.kr(bufnum)),
		LFNoise0.kr(3.2).range(0.1,1.0),0,1,4);

	//sig = BufRd.ar(2, bufnum, LFNoise0.ar(freqRatio) * BufFrames.ir(bufnum));
	sig = sig * amp * env;
	Out.ar(out, sig);
	Out.ar(anaBus, sig);
}).store;

SynthDef(\ten_crusher, {|out=0 in srate=20000 bit=8 mix=0.5|
	var dry, wet;
	dry = In.ar(in, 1);

	//wet = Decimator.ar(dry, srate, bit);
	wet = FreeVerb.ar(dry, mix, 0.8, 0.4);
	//dry = (dry * mix) + (wet * (1-mix));
	Out.ar(out, wet!2 )}).store;

SynthDef(\ten_sidechainer, {|out in side thresh=0.1 slope=0.1 pan=0|
	var sig, sidechain;
	sidechain = In.ar(side, 1);
	sig = Compander.ar(In.ar(in,1),sidechain,thresh,1,slope,0.001,mul:3);
	Out.ar(out, Pan2.ar(sig, pan)); }).store;


SynthDef(\tenoricomb, {|out=6 in maxdel mix=0.1|
	var dry, wet,bpsig;
	dry = In.ar(in, 1);
	wet = dry;
	bpsig = dry;
	10.do{|i| var delay, decay, bfreq;
		delay = 0.0025 + ((i + 1) * 0.01);
		decay = (i + 1) * 1;
		bfreq = 50 + (i * 200);
		wet = CombC.ar(wet, delay, SinOsc.kr(LFNoise2.kr(Rand(0.001,8.2)).range(0.001,0.01)).range(0.025, delay), decay,0.1, wet);
		bpsig = BPF.ar(wet, bfreq, 0.9,2);
		wet = HPF.ar(wet*0.25, 40, 1, bpsig*0.75);
			wet = LPF.ar(wet, 10000, 1);

	};
		wet = wet * 3;

	dry = (dry * mix) + (wet * (1-mix));
	//dry = Compander.ar(dry, dry, 0.1,1.0,0.2,0.001,0.1,10.0);
	Out.ar(out, Pan2.ar(dry,SinOsc.kr(LFNoise0.kr(0.8).range(13.0,152.0)).range(-0.5,0.5)); )}).store;


SynthDef(\toycomb, {|out=6 in maxdel mix=0.1|
	var dry, wet,bpsig;
	dry = In.ar(in, 1);
	wet = dry;
	bpsig = dry;
	5.do{|i| var delay, decay, bfreq;
		delay = 0.025 + ((i + 1) * 0.05);
		decay = (i + 1) * 1;
		bfreq = 500 + (i * 50);
		wet = CombC.ar(wet, delay, SinOsc.kr(LFNoise2.kr(Rand(0.001,8.2)).range(0.001,0.01)).range(0.025, delay), decay,0.2, wet);
		bpsig = BPF.ar(wet, bfreq, 0.9,2);
		wet = HPF.ar(wet*0.25, 40, 1, bpsig*0.75);
			wet = LPF.ar(wet, 10000, 1);

	};
		wet = wet * 3;

	dry = (dry * mix) + (wet * (1-mix));
	//dry = Compander.ar(dry, dry, 0.1,1.0,0.2,0.001,0.1,10.0);
	Out.ar(out, Pan2.ar(dry,SinOsc.kr(LFNoise0.kr(0.8).range(13.0,152.0)).range(-0.5,0.5)); )}).store;

SynthDef(\tapecomb, {|out=6 in maxdel mix=0.1|
	var dry, wet,bpsig;
	dry = In.ar(in, 1);
	wet = dry;
	bpsig = dry;
	5.do{|i| var delay, decay, bfreq;
		delay = 0.025 + ((i + 1) * 0.05);
		decay = (i + 1) * 1;
		bfreq = 100 + (i * 500);
		wet = CombC.ar(wet, delay, SinOsc.kr(LFNoise2.kr(Rand(0.001,8.2)).range(0.001,0.05)).range(0.025, delay), decay,0.2, wet);
		bpsig = BPF.ar(wet, bfreq, 0.9,2);
		wet = HPF.ar(wet*0.25, 40, 1, bpsig*0.75);
			wet = LPF.ar(wet, 10000, 1);

	};
		wet = wet * 3;

	dry = (dry * mix) + (wet * (1-mix));
	//dry = Compander.ar(dry, dry, 0.1,1.0,0.2,0.001,0.1,10.0);
	Out.ar(out, Pan2.ar(dry,SinOsc.kr(LFNoise0.kr(0.8).range(13.0,152.0)).range(-0.5,0.5)); )}).store;


SynthDef(\ten_droneverb, {|out=0 in maxdel mix=0.35|
	var dry, wet;
	dry = In.ar(in, 2);
	wet = dry;
	3.do{
		d = 0.3.rand + 0.05;
		wet = AllpassC.ar(wet, d, FSinOsc.kr(Rand(0.001,0.025)).range(0.05, d), Rand(6, 8),0.2, wet);
	};
	dry = (dry * (1-mix)) + (wet * mix);
	dry = FreeVerb2.ar(dry[0],dry[1],mix,0.8,0.25);
	Out.ar(out, dry!2 )}).store;

SynthDef(\ten_monoverb, {|out=0 in maxdel mix=0.5|
	var dry, wet;
	dry = In.ar(in, 1);
	wet = dry;
	3.do{
		d = 0.3.rand + 0.05;
		wet = AllpassC.ar(wet, d, FSinOsc.kr(Rand(0.001,0.025)).range(0.05, d), Rand(6, 8),0.2, wet);
	};
	dry = (dry * mix) + (wet * (1-mix));
	dry = FreeVerb.ar(dry,0.35,0.8,0.25);
	Out.ar(out, dry!2 )}).store;

SynthDef(\ten_perc_effect, {|out=0 in maxdel mix=0.1 srate=32000 ffreq=3000|
	var sig,dry, wet;
	dry = In.ar(in, 1);
	dry = Decimator.ar(dry,srate,16);
	dry = LPF.ar(dry, ffreq);
	wet = dry;
	3.do{
		d = 0.3.rand + 0.05;
		wet = AllpassC.ar(wet, d, FSinOsc.kr(Rand(0.001,0.025)).range(0.05, d), Rand(6, 8),0.2, wet);
	};
	sig = (dry * mix) + (wet * (1-mix));

	sig = FreeVerb.ar(dry,0.1,0.8,0.25);
	Out.ar(out, sig!2 )}).store;

SynthDef(\fieldcricket, {|out=0 recout=100 tfreqBus gate=1 amp=1|
	var tfreq, env, trig, seq, demand, cricket;
	tfreq = In.kr(tfreqBus, 1);
	env = EnvGen.ar(Env.adsr(15,0.0,1,15),gate, doneAction: 2);

	// instead of [metro], Impulse.kr is used here. Delta t = 17 ms equates to 58.82 Hz.
	trig = Impulse.kr(tfreq);

	// the main idea of the following line was to use an approach
	// that uses the same coefficients as described in the pd patch
	seq = Dseq(Array.fill(41, {|i| if(i<7, {(i+2)/9},{0}) }),inf);
	demand = Demand.kr(trig,0,seq);

	// Implementation of the pd code for pulses including amplitude grow:
	// cricket = EnvGen.ar(Env.new([0, 1, 1, 0], [0.0001, 0.0001, 0]), trig) * demand;

	// 2nd implementation: pure data seemed to slightly disobey its own specifications,
	// so I analysed the waveform and came up with this:
	cricket = EnvGen.ar(Env.new([0, 1, 0], [4/44100, 0]), trig) * demand;


	cricket = OnePole.ar(cricket, exp(-2pi * (1000 * SampleDur.ir)));
	cricket = (
			// changed the Q factor of the first 3 BPFs to approximate farnells sound
			BPF.ar(cricket, 4500 + ((0..2)*50), 300.reciprocal, 100)).sum
			+ BPF.ar(cricket, 9000, 500.reciprocal, 42
	);
	cricket = ((cricket - OnePole.ar(cricket, exp(-2pi * (4000 * SampleDur.ir)))) * 0.5);
			Out.ar(out, Pan2.ar(cricket*env*amp) );
			Out.ar(recout, cricket*env*amp );
		}).store;

SynthDef(\cicada_3calls, {|out=0 recout=100 tfreqBus amp=1 gate=1|
	var tfreq, env, sig, trig, seq, freq, mul, vals;
	tfreq = In.kr(tfreqBus, 1);
	env = EnvGen.ar(Env.adsr(15,0.0,1,15),gate, doneAction: 2);

	trig = Impulse.kr(tfreq);
	vals = [
		[0.5, 128],
		[8,6],
		[30,3]
	];
	freq = TChoose.kr(trig, vals);


	sig = WhiteNoise.ar;
	// The one pole filters in pure data and SC differ, so I changed the coefficents
	// a little. Also the  multiplication by 5 is not in the book, but helps to
	// approach the audible result of Farnells patch.
	sig = (sig - OnePole.ar(sig, exp(-2pi * (8000 * SampleDur.ir))));
	sig = (sig - OnePole.ar(sig, exp(-2pi * (8000 * SampleDur.ir))));
	sig = OnePole.ar(sig, exp(-2pi * (10000 * SampleDur.ir)));
	sig = OnePole.ar(sig, exp(-2pi * (10000 * SampleDur.ir)));
	sig = sig * 5;


	sig = BPF.ar(sig, [7500, 5500], 40.reciprocal).sum * SinOsc.ar(500);
	sig = sig * (1 / (SinOsc.ar( freq[0], 0, freq[1] ).squared + 1));
	sig = (sig - OnePole.ar(sig, exp(-2pi * (4000 * SampleDur.ir)))) * 4;

			Out.ar(out, sig*env*amp);
			Out.ar(recout, sig*env*amp);
		}).store;

/*perc synths */
SynthDef(\perc, {|out=0 freq=440 amp=0.5 release=0.2 bufnum pan=0 phasemIndexBus|
	var env, sig,phasemIndex;
	phasemIndex = In.kr(phasemIndexBus, 1);
	env = EnvGen.ar(Env.perc(0.001, release),doneAction: 2);
	//sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, 0,0);
	sig = SinOsc.ar(freq, LFSaw.kr(LFNoise0.kr(16.8).range(0.1,85.0),mul:phasemIndex).range(-2pi,2pi),0.5);
	Out.ar(out, sig*env*amp); }).store;

SynthDef(\perc2, {|out=0 freq=440 ffreq=1 fmIndex=1 amp=0.5 release=1 dur=3 bufnum pan=0 phasemIndexBus|
	var env, sig,phasemIndex, fmod,gate;
	gate = EnvGen.kr(Env([1,0],[dur]),1);
	phasemIndex = In.kr(phasemIndexBus, 1);
	env = EnvGen.ar(Env.adsr(0.01,0.0,1,release),gate,doneAction: 2);
	fmod = SinOsc.kr(freq,0,fmIndex);
			sig = SinOsc.ar(freq*fmod);
	//sig = Saw.ar(freq*fmod,0.5);
	//sig = VarSaw.ar([freq*0.8*fmod,freq*1*fmod,freq*1.2*fmod],[-0.25,0,0.25],SinOsc.kr(LFNoise0.kr(0.4).range(0.1,85.0)).range(0.1,0.9)!3,0.2);
	sig = Mix(sig);
	sig = LPF.ar(sig, 800);
	Out.ar(out, sig*env*amp); }).store;




~chineScale = [ Scale.chinese(\pythagorean); ];

~chinese = Array.fill(1, {|j|
var sc = ~chineScale[j];

Array.fill(128, {|i|
	var octave = i / 15;
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
});


~thirtysevensteps = [
	Scale.new(#[0,2,5,7,10,12,15,17,20,22,25,27,30,32,35],37,name: "37steps");
];

~thirtyseven = Array.fill(1, {|j|
var sc = ~thirtysevensteps[j];

Array.fill(128, {|i|
	var octave = i / 15;
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
});




~newScale = [
	Scale.new(#[0,1,3,4,5,8,9,10,11,13,14,15,18,19,20,21,22],24,name: "quarter-tone");
];
~quarter = Array.fill(1, {|j|
var sc = ~newScale[j];

Array.fill(128, {|i|
	var octave = i / 15;
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
});

/*
~micro =
Array.fill(128, {|i|
	var fundTone = 65;
	fundTone + (0.075*(i+1)); })
*/
~fibo = [1,2,3,5,8,13,21,34,55,89]*0.3;

~micro =
Array.fill(10, {|j|
Array.fill(128, {|i|
	var fundTone = 65;
		fundTone + (    (0.00625*~fibo[j] )  *(i+1) ); })

});

~minorScale =
Scale.minorPentatonic(\pythagorean);



~minorratios = Array.fill(20, {|i|
	var multi;
	case
	{ i < 5 } { multi = 1; }
	{ i < 10 } { multi = 2; }
	{ i < 15 } { multi = 4; }
	{ i < 20 } { multi = 8; };

	~minorScale.ratios[i%5] * multi;
});


//SCALES AND TUNINGS
~partchO = [
Scale.partch_o1(\partch),
Scale.partch_o2(\partch),
Scale.partch_o3(\partch),
Scale.partch_o4(\partch),
Scale.partch_o5(\partch),
Scale.partch_o6(\partch);
];

~partchU = [
Scale.partch_u1(\partch),
Scale.partch_u2(\partch),
Scale.partch_u3(\partch),
Scale.partch_u4(\partch),
Scale.partch_u5(\partch),
Scale.partch_u6(\partch);
];


~otonratios = Array.fill(6, {|j|

	Array.fill(128, {|i|
	var oct = i / 5;
	var mod = ( i % 5) + 1;
	//mod.postln;
	case
	{ oct < 1 } { (~partchO[j].ratios[5]*0.125) + (~partchO[j].ratios[mod]*0.125) }
	{ oct < 2 } { (~partchO[j].ratios[5]*0.25) + (~partchO[j].ratios[mod]*0.25) }
	{ oct < 3 } { (~partchO[j].ratios[5]*0.5) + (~partchO[j].ratios[mod]*0.5) }
	{ oct < 4 } {  0 + ~partchO[j].ratios[mod] }
	{ oct < 5 } { ~partchO[j].ratios[5] + ~partchO[j].ratios[mod] }
	{ oct < 6 } {  (~partchO[0].ratios[5]* 2) + ~partchO[j].ratios[mod] }
	{ oct < 7 } {  (~partchO[0].ratios[5]* 3) + ~partchO[j].ratios[mod] }
	{ oct < 8 } {  (~partchO[0].ratios[5]* 4)  + ~partchO[j].ratios[mod] }
	{ oct < 9 } {  (~partchO[0].ratios[5]* 5) + ~partchO[j].ratios[mod] }
	{ oct < 10 } {  (~partchO[0].ratios[5]* 6) + ~partchO[j].ratios[mod] }
	{ oct < 11 } {  (~partchO[0].ratios[5]* 7)+ ~partchO[j].ratios[mod] }
	{ oct < 12 } {  (~partchO[0].ratios[5]* 8) + ~partchO[j].ratios[mod] }
	{ oct < 13 } {  (~partchO[0].ratios[5]* 9) + ~partchO[j].ratios[mod] }
	{ oct < 14 } {  (~partchO[0].ratios[5]* 10)  + ~partchO[j].ratios[mod] }
	{ oct < 15 } {  (~partchO[0].ratios[5]* 11)+ ~partchO[j].ratios[mod] }
	{ oct < 16 } {  (~partchO[0].ratios[5]* 12) + ~partchO[j].ratios[mod] }
	{ oct < 17 } {  (~partchO[0].ratios[5]* 13) + ~partchO[j].ratios[mod] }
	{ oct < 18 } {  (~partchO[0].ratios[5]* 14) + ~partchO[j].ratios[mod] }
	{ oct < 19 } {  (~partchO[0].ratios[5]* 15) + ~partchO[j].ratios[mod] }
	{ oct < 20 } {  (~partchO[0].ratios[5]* 16) + ~partchO[j].ratios[mod] }
	{ oct < 21 } {  (~partchO[0].ratios[5]* 17)  + ~partchO[j].ratios[mod] }
	{ oct < 22 } {  (~partchO[0].ratios[5]* 18)+ ~partchO[j].ratios[mod] }
	{ oct < 23 } {  (~partchO[0].ratios[5]* 19) + ~partchO[j].ratios[mod] }
	{ oct < 24 } {  (~partchO[0].ratios[5]* 20) + ~partchO[j].ratios[mod] }
	{ oct < 25 } {  (~partchO[0].ratios[5]* 21) + ~partchO[j].ratios[mod] }
	{ oct < 26 } {  (~partchO[0].ratios[5]* 22) + ~partchO[j].ratios[mod] };
});
});



~oton = Array.fill(6, {|j|

	Array.fill(128, {|i|
	var oct = i / 5;
	var mod = ( i % 5) + 1;
	//mod.postln;


	case
	{ oct < 1 } {  0 + ~partchO[j][mod] }
	{ oct < 2 } { ~partchO[j][5] + ~partchO[j][mod] }
	{ oct < 3 } {  (~partchO[0][5]* 2) + ~partchO[j][mod] }
	{ oct < 4 } {  (~partchO[0][5]* 3) + ~partchO[j][mod] }
	{ oct < 5 } {  (~partchO[0][5]* 4)  + ~partchO[j][mod] }
	{ oct < 6 } {  (~partchO[0][5]* 5) + ~partchO[j][mod] }
	{ oct < 7 } {  (~partchO[0][5]* 6) + ~partchO[j][mod] }
	{ oct < 8 } {  (~partchO[0][5]* 7)+ ~partchO[j][mod] }
	{ oct < 9 } {  (~partchO[0][5]* 8) + ~partchO[j][mod] }
	{ oct < 10 } {  (~partchO[0][5]* 9) + ~partchO[j][mod] }
	{ oct < 11 } {  (~partchO[0][5]* 10)  + ~partchO[j][mod] }
	{ oct < 12 } {  (~partchO[0][5]* 11)+ ~partchO[j][mod] }
	{ oct < 13 } {  (~partchO[0][5]* 12) + ~partchO[j][mod] }
	{ oct < 14 } {  (~partchO[0][5]* 13) + ~partchO[j][mod] }
	{ oct < 15 } {  (~partchO[0][5]* 14) + ~partchO[j][mod] }
	{ oct < 16 } {  (~partchO[0][5]* 15) + ~partchO[j][mod] }
	{ oct < 17 } {  (~partchO[0][5]* 16) + ~partchO[j][mod] }
	{ oct < 18 } {  (~partchO[0][5]* 17)  + ~partchO[j][mod] }
	{ oct < 19 } {  (~partchO[0][5]* 18)+ ~partchO[j][mod] }
	{ oct < 20 } {  (~partchO[0][5]* 19) + ~partchO[j][mod] }
	{ oct < 21 } {  (~partchO[0][5]* 20) + ~partchO[j][mod] }
	{ oct < 22 } {  (~partchO[0][5]* 21) + ~partchO[j][mod] }
	{ oct < 23 } {  (~partchO[0][5]* 22) + ~partchO[j][mod] }
	{ oct < 24 } {  (~partchO[0][5]* 23) + ~partchO[j][mod] }
	{ oct < 25 } {  (~partchO[0][5]* 24) + ~partchO[j][mod] }
	{ oct < 26 } {  (~partchO[0][5]* 25) + ~partchO[j][mod] };
});
});



/*
~oton = Array.fill(6, {|j|
var sc = ~partchO[j];

Array.fill(128, {|i|
	var octave = i / 6;
	case
	{ octave < 1; } { sc.semitones.wrapAt(i) }
	{ ((octave == 1) or: (octave > 1)) and: (octave < 2) } { sc.semitones.wrapAt(i) + 10  }
	{ ((octave == 2) or: (octave > 2)) and: (octave < 3)  } { sc.semitones.wrapAt(i) + 20 }
	{ ((octave == 3) or: (octave > 3)) and: (octave < 4)  } { sc.semitones.wrapAt(i) + 30 }
	{ ((octave == 4) or: (octave > 4)) and: (octave < 5)  } { sc.semitones.wrapAt(i) + 40 }
	{ ((octave == 5) or: (octave > 5)) and: (octave < 6)  } { sc.semitones.wrapAt(i) + 50 }
	{ ((octave == 6) or: (octave > 6)) and: (octave < 7)  } { sc.semitones.wrapAt(i) + 60 }
	{ ((octave == 7) or: (octave > 7)) and: (octave < 8)  } { sc.semitones.wrapAt(i) + 70 }
	{ ((octave == 8) or: (octave > 8)) and: (octave < 9)  } { sc.semitones.wrapAt(i) + 80 }
	{ ((octave == 9) or: (octave > 9)) and: (octave < 10)  } { sc.semitones.wrapAt(i) + 90 }
	{ ((octave == 10) or: (octave > 10)) and: (octave < 11)  } { sc.semitones.wrapAt(i) + 100 }
	{ ((octave == 11) or: (octave > 11))  and: (octave < 12)  } { sc.semitones.wrapAt(i) +  110 }
	{ ((octave == 12) or: (octave > 12)) and: (octave < 13)  } { sc.semitones.wrapAt(i) + 120 }
	{ ((octave == 13) or: (octave > 13)) and: (octave < 14 )  } { sc.semitones.wrapAt(i) + 130 }
	{ ((octave == 14) or: (octave > 14)) and: (octave < 15 )   } { sc.semitones.wrapAt(i) +  140 }

	{ ((octave == 15) or: (octave > 15)) and: (octave < 16)  } { sc.semitones.wrapAt(i) + 150 }
	{ ((octave == 16) or: (octave > 16)) and: (octave < 17 )  } { sc.semitones.wrapAt(i) + 160 }
	{ ((octave == 17) or: (octave > 17)) and: (octave < 18 )   } { sc.semitones.wrapAt(i) +  170 }

	{ ((octave == 18) or: (octave > 18)) and: (octave < 19)  } { sc.semitones.wrapAt(i) + 180 }
	{ ((octave == 19) or: (octave > 19)) and: (octave < 20 )  } { sc.semitones.wrapAt(i) + 190 }
	{ ((octave == 20) or: (octave > 20)) and: (octave < 21 )   } { sc.semitones.wrapAt(i) +  200 }

	{ ((octave == 21) or: (octave > 21)) and: (octave < 22)  } { sc.semitones.wrapAt(i) + 210 }
	{ ((octave == 22) or: (octave > 22)) and: (octave < 23 )  } { sc.semitones.wrapAt(i) + 220 }
	{ ((octave == 23) or: (octave > 23)) and: (octave < 24 )   } { sc.semitones.wrapAt(i) +  230 }

	{ ((octave == 24) or: (octave > 24)) and: (octave < 25)  } { sc.semitones.wrapAt(i) + 240 }
	{ ((octave == 25) or: (octave > 25)) and: (octave < 26 )  } { sc.semitones.wrapAt(i) + 250 }
	{ ((octave == 26) or: (octave > 26)) and: (octave < 27 )   } { sc.semitones.wrapAt(i) +  260 }

	{ ((octave == 27) or: (octave > 27)) and: (octave < 28)  } { sc.semitones.wrapAt(i) + 270 }
	{ ((octave == 28) or: (octave > 28)) and: (octave < 29 )  } { sc.semitones.wrapAt(i) + 280 }
	{ ((octave == 29) or: (octave > 29)) and: (octave < 30 )   } { sc.semitones.wrapAt(i) +  290 }

	{ ((octave == 30) or: (octave > 30)) and: (octave < 31)  } { sc.semitones.wrapAt(i) + 120 }
	{ ((octave == 31) or: (octave > 31)) and: (octave < 32 )  } { sc.semitones.wrapAt(i) + 121 }
	{ ((octave == 32) or: (octave > 32))  } { sc.semitones.wrapAt(i) +  122 }
});
});
*/

~uton = Array.fill(6, {|j|

var sc = ~partchU[j];

Array.fill(128, {|i|
	var octave = i / 5;
case
	{ octave < 1; } { sc.semitones.wrapAt(i) }
	{ ((octave == 1) or: (octave > 1)) and: (octave < 2) } { sc.semitones.wrapAt(i) + 1 }
	{ ((octave == 2) or: (octave > 2)) and: (octave < 3)  } { sc.semitones.wrapAt(i) + 2 }
	{ ((octave == 3) or: (octave > 3)) and: (octave < 4)  } { sc.semitones.wrapAt(i) + 12 }
	{ ((octave == 4) or: (octave > 4)) and: (octave < 5)  } { sc.semitones.wrapAt(i) + 13 }
	{ ((octave == 5) or: (octave > 5)) and: (octave < 6)  } { sc.semitones.wrapAt(i) + 14 }
	{ ((octave == 6) or: (octave > 6)) and: (octave < 7)  } { sc.semitones.wrapAt(i) + 24 }
	{ ((octave == 7) or: (octave > 7)) and: (octave < 8)  } { sc.semitones.wrapAt(i) + 25 }
	{ ((octave == 8) or: (octave > 8)) and: (octave < 9)  } { sc.semitones.wrapAt(i) + 26 }
	{ ((octave == 9) or: (octave > 9)) and: (octave < 10)  } { sc.semitones.wrapAt(i) + 36 }
	{ ((octave == 10) or: (octave > 10)) and: (octave < 11)  } { sc.semitones.wrapAt(i) + 37 }
	{ ((octave == 11) or: (octave > 11))  and: (octave < 12)  } { sc.semitones.wrapAt(i) +  38 }
	{ ((octave == 12) or: (octave > 12)) and: (octave < 13)  } { sc.semitones.wrapAt(i) + 48 }
	{ ((octave == 13) or: (octave > 13)) and: (octave < 14 )  } { sc.semitones.wrapAt(i) + 49 }
	{ ((octave == 14) or: (octave > 14)) and: (octave < 15 )   } { sc.semitones.wrapAt(i) +  50 }

	{ ((octave == 15) or: (octave > 15)) and: (octave < 16)  } { sc.semitones.wrapAt(i) + 60 }
	{ ((octave == 16) or: (octave > 16)) and: (octave < 17 )  } { sc.semitones.wrapAt(i) + 61 }
	{ ((octave == 17) or: (octave > 17)) and: (octave < 18 )   } { sc.semitones.wrapAt(i) +  62 }

	{ ((octave == 18) or: (octave > 18)) and: (octave < 19)  } { sc.semitones.wrapAt(i) + 72 }
	{ ((octave == 19) or: (octave > 19)) and: (octave < 20 )  } { sc.semitones.wrapAt(i) + 73 }
	{ ((octave == 20) or: (octave > 20)) and: (octave < 21 )   } { sc.semitones.wrapAt(i) +  74 }

	{ ((octave == 21) or: (octave > 21)) and: (octave < 22)  } { sc.semitones.wrapAt(i) + 84 }
	{ ((octave == 22) or: (octave > 22)) and: (octave < 23 )  } { sc.semitones.wrapAt(i) + 85 }
	{ ((octave == 23) or: (octave > 23)) and: (octave < 24 )   } { sc.semitones.wrapAt(i) +  86 }

	{ ((octave == 24) or: (octave > 24)) and: (octave < 25)  } { sc.semitones.wrapAt(i) + 96 }
	{ ((octave == 25) or: (octave > 25)) and: (octave < 26 )  } { sc.semitones.wrapAt(i) + 97 }
	{ ((octave == 26) or: (octave > 26)) and: (octave < 27 )   } { sc.semitones.wrapAt(i) +  98 }

	{ ((octave == 27) or: (octave > 27)) and: (octave < 28)  } { sc.semitones.wrapAt(i) + 108 }
	{ ((octave == 28) or: (octave > 28)) and: (octave < 29 )  } { sc.semitones.wrapAt(i) + 109 }
	{ ((octave == 29) or: (octave > 29)) and: (octave < 30 )   } { sc.semitones.wrapAt(i) +  110 }

	{ ((octave == 30) or: (octave > 30)) and: (octave < 31)  } { sc.semitones.wrapAt(i) + 120 }
	{ ((octave == 31) or: (octave > 31)) and: (octave < 32 )  } { sc.semitones.wrapAt(i) + 121 }
	{ ((octave == 32) or: (octave > 32))  } { sc.semitones.wrapAt(i) +  122 }
});
});

//pelog scale with 3 different mean tone tunings
~pelog = Array.fill(3, {|j| var tuning,sc;
	case
	{ j == 0 } {
		sc = Scale.pelog(\mean4);
}
	{ j == 1 } {
		sc = Scale.pelog(\pythagorean);
 }
	{ j == 2 } {
		sc = Scale.pelog(\reinhard);
 };

	Array.fill(128, {|i|
	var octave = i / 4;
	case
	{ octave < 1; } { sc.semitones.wrapAt(i) }
	{ ((octave == 1) or: (octave > 1)) and: (octave < 2) } { sc.semitones.wrapAt(i) + 1 }
	{ ((octave == 2) or: (octave > 2)) and: (octave < 3)  } { sc.semitones.wrapAt(i) + 2 }
	{ ((octave == 3) or: (octave > 3)) and: (octave < 4)  } { sc.semitones.wrapAt(i) + 12 }
	{ ((octave == 4) or: (octave > 4)) and: (octave < 5)  } { sc.semitones.wrapAt(i) + 13 }
	{ ((octave == 5) or: (octave > 5)) and: (octave < 6)  } { sc.semitones.wrapAt(i) + 14 }
	{ ((octave == 6) or: (octave > 6)) and: (octave < 7)  } { sc.semitones.wrapAt(i) + 24 }
	{ ((octave == 7) or: (octave > 7)) and: (octave < 8)  } { sc.semitones.wrapAt(i) + 25 }
	{ ((octave == 8) or: (octave > 8)) and: (octave < 9)  } { sc.semitones.wrapAt(i) + 26 }
	{ ((octave == 9) or: (octave > 9)) and: (octave < 10)  } { sc.semitones.wrapAt(i) + 36 }
	{ ((octave == 10) or: (octave > 10)) and: (octave < 11)  } { sc.semitones.wrapAt(i) + 37 }
	{ ((octave == 11) or: (octave > 11))  and: (octave < 12)  } { sc.semitones.wrapAt(i) +  38 }
	{ ((octave == 12) or: (octave > 12)) and: (octave < 13)  } { sc.semitones.wrapAt(i) + 48 }
	{ ((octave == 13) or: (octave > 13)) and: (octave < 14 )  } { sc.semitones.wrapAt(i) + 49 }
	{ ((octave == 14) or: (octave > 14)) and: (octave < 15 )   } { sc.semitones.wrapAt(i) +  50 }

	{ ((octave == 15) or: (octave > 15)) and: (octave < 16)  } { sc.semitones.wrapAt(i) + 60 }
	{ ((octave == 16) or: (octave > 16)) and: (octave < 17 )  } { sc.semitones.wrapAt(i) + 61 }
	{ ((octave == 17) or: (octave > 17)) and: (octave < 18 )   } { sc.semitones.wrapAt(i) +  62 }

	{ ((octave == 18) or: (octave > 18)) and: (octave < 19)  } { sc.semitones.wrapAt(i) + 72 }
	{ ((octave == 19) or: (octave > 19)) and: (octave < 20 )  } { sc.semitones.wrapAt(i) + 73 }
	{ ((octave == 20) or: (octave > 20)) and: (octave < 21 )   } { sc.semitones.wrapAt(i) +  74 }

	{ ((octave == 21) or: (octave > 21)) and: (octave < 22)  } { sc.semitones.wrapAt(i) + 84 }
	{ ((octave == 22) or: (octave > 22)) and: (octave < 23 )  } { sc.semitones.wrapAt(i) + 85 }
	{ ((octave == 23) or: (octave > 23)) and: (octave < 24 )   } { sc.semitones.wrapAt(i) +  86 }

	{ ((octave == 24) or: (octave > 24)) and: (octave < 25)  } { sc.semitones.wrapAt(i) + 96 }
	{ ((octave == 25) or: (octave > 25)) and: (octave < 26 )  } { sc.semitones.wrapAt(i) + 97 }
	{ ((octave == 26) or: (octave > 26)) and: (octave < 27 )   } { sc.semitones.wrapAt(i) +  98 }

	{ ((octave == 27) or: (octave > 27)) and: (octave < 28)  } { sc.semitones.wrapAt(i) + 108 }
	{ ((octave == 28) or: (octave > 28)) and: (octave < 29 )  } { sc.semitones.wrapAt(i) + 109 }
	{ ((octave == 29) or: (octave > 29)) and: (octave < 30 )   } { sc.semitones.wrapAt(i) +  110 }

	{ ((octave == 30) or: (octave > 30)) and: (octave < 31)  } { sc.semitones.wrapAt(i) + 120 }
	{ ((octave == 31) or: (octave > 31)) and: (octave < 32 )  } { sc.semitones.wrapAt(i) + 121 }
	{ ((octave == 32) or: (octave > 32))  } { sc.semitones.wrapAt(i) +  122 }
});
});


};
)

