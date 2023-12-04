
(

~field_files = "/home/numina/repos/electromagnetic_sensibility/Field_recordings/*.wav".pathMatch;
~field_samples = ~field_files.collect{|i| Buffer.read(s, i); };

SynthDef(\field_sampler, {|out=0 bufnum amp=0.2 rateBus posBus gate=1|
	var env, sig, rate, pos;
	rate = In.kr(rateBus, 1);
	pos = In.kr(posBus, 1);
	env = EnvGen.ar(Env.adsr(3.0,0.0, 1.0, 3.0), gate, doneAction: 2);
	sig = PlayBuf.ar(1, bufnum,BufRateScale.kr(bufnum)*rate, 1, BufFrames.ir(bufnum) * pos, loop: 1);
	Out.ar(out, Pan2.ar(sig*env*amp, SinOsc.kr(LFNoise0.kr(0.4).range(0.1,82.0)).range(-0.9,0.9) ));
}).store;

SynthDef(\transform_comb, {|out=0 in ffreq=500 modFreq mix = 0.2|
	var sig = In.ar(in, 2);
	var drysig = sig;
	sig = MoogFF.ar(sig , 500, 3);
	sig = BLowPass.ar(sig, 800, 0.7);

	4.do{ d = 0.1.rand + 0.05;
		sig = CombC.ar(sig, d, d, Rand(5.0, 8.0),0.3, sig * 0.33); };
	sig = ( drysig * ( 1- mix) ) + ( sig * mix );
	sig = HPF.ar(sig, 40);
	//sig = Pan2.ar(sig, LFNoise0.kr(0.1).range(-0.1,0.1));
	//sig = FreeVerb2.ar(sig[0], sig[1], 0.2, 0.8);

	Out.ar(out, sig ); }).store;


~main_group = Group.new;
~effect_group = Group.after(~main_group);

//effect busses
~comb_bus = Bus.audio(s, 2);


//control busses
~pos_bus = Bus.control(s, 1).set(0);
~rate_bus = Bus.control(s, 1).set(1);

a = Synth(\field_sampler, [\out, ~comb_bus, \amp, 1, \bufnum, ~field_samples[0],\posBus, ~pos_bus.index, \rateBus, ~rate_bus.index], ~main_group);
//a.set(\bufnum, ~field_samples[4]);
b = Synth(\transform_comb, [\in, ~comb_bus, \mix, 0.5], ~effect_group);
//b.free
//b.set(\mix, 0.1);

//a.set(\gate, 0);

// routine simulating joystick
r = Routine({ inf.do{ var time = rrand(0.01,0.5);
	~pos_bus.set(rrand(0.0, 0.9));
		~rate_bus.set(rrand(0.2, 1.0));
	time.wait; }; }).play;
)

~pos_bus.


a.set(\gate, 0);

 ~field_samples[0]

{ PlayBuf.ar(1, ~field_samples[0]); }.play;