/*
different scenes
joystick gebruiken voor field recordings
kanalen 0, 1 monome, radio
kanalen 2, 3 joystick, field recordings
mixer
*/
// polyrhytmic



Server.default.makeGui

(
Server.default = Server.local;

// SynthDef shared by all voices:
SynthDef(\radiograin, { |bufnum freq = 440, amp = 0.2, t_trig = 0, durBus, decay, rate=1|
	var sig;
	var dur = In.kr(durBus, 1);
	var env = Env.new([0,0,1,0],[0,0.01,decay], curve:-8, releaseNode: 1);
	/*sig = SinOsc.ar(freq, SinOsc.kr(LFNoise0.kr(0.2).range(1,80.0)).range(-2pi,2pi), amp) * EnvGen.kr(
		env,
		gate: t_trig // 't_trig' syntax allows the env to restart on-demand
	);*/
	sig = PlayBuf.ar(1, bufnum, BufRateScale.ir(bufnum)*rate,1, 0, loop: 1) * EnvGen.kr(
		env,
		gate: t_trig // 't_trig' syntax allows the env to restart on-demand
	);
	Out.ar(0, Pan2.ar(sig, SinOsc.kr(LFNoise0.kr(Rand(0.2,12.2)).range(0.01,40.0)).range(-0.9,0.9)));
}).add;

// instantiate a grid variable:
~flinGrid = MonomeGrid.new(prefix: "/flin", fps: 60);

MIDIIn.connectAll;

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



MIDIdef.cc(\nanokontrol, {|val num chan src|
	[num, val, chan, src].postln;
	if ( num >= 32 && num <= 39  , {
		if ( val == 127, {
			if ( ~rec_synths[num-32] == 0, {

				~rec_synths.put(num-32, Synth(\radio_recorder, [\in, 4, \recbuf, ~rec_bufs[num-32], \fftbuf, ~fft_bufs[num-32]]); );
				("rec synth nr : "++(num - 32)).postln;


			});
		},
		{
			if ( ~rec_synths[num - 32] != 0, {
				~rec_synths[num-32].free;
				~rec_synths.put(num-32, 0);
				("rec nr : "++(num - 32)++" shut down").postln;
			});


		});



	});

}, chan: 2);



s.waitForBoot({

	var redraw, mainTimer,
	positions, speeds, widths, counts, holding, notes, base_note, voices,
	lvl2 = 15, lvl1 = 5, lvl0 = 2,
	length = 16,
	dirtyGrid = 0,
	// timing vars:
	stepInterval = 0.0625, stepMultiplier = 1, bpm = 90, playing = 0,
	linkClock, linkCallback, launchQuant = -1, launchQuants = [-1, -0.25, -0.125, -0.0625, 0],
	linkStartStop = 1,
	// GUI vars:
	tempoGUI, transportGUI, quantGUI, barsBox, beatsBox, startButton, toggleTransport;

	// create a Link-synchronized clock
	linkClock = LinkClock(1).latency_(Server.default.latency);
	linkClock.tempo = bpm/60;
	linkCallback = SimpleController(linkClock)
	.put(\linkStart, {
		toggleTransport.value(1);
	})
	.put(\linkStop, {
		toggleTransport.value(0);
	})
	.put(\stop, { linkCallback.remove })
	.put(\tempo, {
		bpm = round(linkClock.tempo * 60,0.01);
		defer{tempoGUI.value = bpm}; // all GUI changes need to be deferred
	});
	//

	~flinGrid.connect();

	MIDIdef.cc(\BOSS_footpedal, {|val num chan src|


	bpm = ~tempo_spec.map(val/127).postln;
	linkClock.tempo = bpm/60;
	//[num,val,chan, src].postln;


    },srcID:8454144);

	// build grid UI from connected grid measurements:
	positions = Array.fill(~flinGrid.cols, {-1});
	speeds = Array.fill(~flinGrid.cols, {~flinGrid.rows-1});
	widths = Array.fill(~flinGrid.cols, {0});
	counts = Array.fill(~flinGrid.cols, {-3});
	holding = Array.fill(~flinGrid.cols, {0});

	notes = [2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28];
	base_note = 60;

	// one voice per grid column
	voices = Array.newClear(~flinGrid.cols);
	// instantiate a 'singrain' for each voice
	for(0,voices.size-1){
		arg i;
		// instantiate a synth voice for each grid column:
		voices[i] = Synth(\radiograin, [
			bufnum: ~rec_bufs[0],
			rate: 440 / (notes[i] + base_note).midicps,
			amp: 0.2 * (1/(i+1)),
			t_trig: 0
		]);
	};

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

		if(z == 1, {
			if(holding[x] == 0, {
				speeds[x] = y;
				widths[x] = y;
				positions[x] = 0;
				counts[x] = y+1;
				if(y == (~flinGrid.rows-1), {
					voices[x].set(\t_trig,-1.9);
				});
			},{
				widths[x] = y;
				voices[x].set(\t_trig,-1.9);
			});

			holding[x] = 1;
		},{
			holding[x] = 0;
		});

		dirtyGrid = 1;

	});

	redraw = Routine({
		var interval = 1/60; // 60fps
		loop{
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
			interval.yield;
		}
	});

	mainTimer = Routine({
		loop {
			if(playing == 1, {

				for(0, ~flinGrid.cols-1) {
					arg i;
					if(speeds[i] != (~flinGrid.rows-1)) {
						counts[i] = counts[i] + 1;
						if(counts[i] > speeds[i]) {
							if(positions[i] == 0, {
								var sIM = stepInterval * stepMultiplier;
								var duration = (((widths[i] + speeds[i]) * sIM) * (1/sIM)).clip(sIM,inf);
								voices[i].set(\decay, duration);
								voices[i].set(\t_trig,1);
							},{
								if((positions[i] - widths[i]) == 1,{
									voices[i].set(\t_trig,-10);
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

	});

	mainTimer.play(linkClock, quant: 1);
	redraw.play();

	// GUI:
	w = Window.new(
		name: "flin params",
		bounds: Rect(0,600,520,400)
	).front;
	w.view.decorator=FlowLayout(w.view.bounds);
	w.view.decorator.gap=2@2;

	for(0,15){
		arg i;
		EZSlider(w, 30@300, " n" + i,
			controlSpec: ControlSpec.new(minval: 0, maxval: 48, warp: 'lin', step: 1, default: notes[i]),
			action: { arg slider;
				notes[i] = slider.value.asInteger;
				voices[i].set(\freq, (notes[i] + base_note).midicps)
			},
			labelWidth: 70, numberWidth:60, layout:\vert, margin:1@0)
		.setColors(Color.grey,Color.white)
		.font_(Font("Open Sans",11));
	};

	w.view.decorator.nextLine;

	EZSlider(w,300@10).visible = false;

	w.view.decorator.nextLine;

	EZNumber(w, 100@20, "transpose",
		controlSpec: ControlSpec.new(minval: 0, maxval: 128, warp: 'lin', step: 1, default: base_note),
		action: { arg number;
			base_note = number.value.asInteger;
			for(0,15){
				arg i;
				voices[i].set(\freq, (notes[i] + base_note).midicps)
			};
		},
		labelWidth: 60, numberWidth:35)
	.font_(Font("Open Sans",11));

	Button(w, 18 @ 20).visible = false;

	linkStartStop = Button(w, 100 @ 20);
	linkStartStop.states = [
		["ext start/stop", Color.white, Color.blue(0.7)],
		["int start/stop", Color.black, Color.yellow(0.7)]
	];
	linkStartStop.action = {arg view;
		if (view.value == 1,{
			startButton.visible = true;
			quantGUI.visible = true;
		},{
			startButton.visible = false;
			quantGUI.visible = false;
		});
	};

	Button(w, 20 @ 20).visible = false;

	startButton = Button(w, 60 @ 20);
	startButton.states = [
		["Start", Color.black, Color.green(0.7)],
		["Stop", Color.white, Color.red(0.7)]
	];
	startButton.action = {|view|
		toggleTransport.value(view.value);
	};
	startButton.visible = false;

	quantGUI = PopUpMenu(w, Rect(10, 10, 130, 20))
	.items_([
		"launch quant: 1 bar",
		"launch quant: 1/4",
		"launch quant: 1/8",
		"launch quant: 1/16",
		"launch quant: none"
	]).font_(Font("Open Sans",11));

	quantGUI.action = { arg menu;
		launchQuant = launchQuants[menu.value];
	};

	quantGUI.visible = false;

	transportGUI = Routine {
		var bars, beats;
		loop {
			bars = linkClock.bar;
			beats = linkClock.beatInBar;
			{
				barsBox.value = bars;
				beatsBox.value = beats+1;
			}.defer(linkClock.latency);
			1.0.wait;
		}
	}.play(linkClock, quant: 1);

	w.view.decorator.nextLine;

	EZNumber(w,100@20, "length",
		controlSpec: ControlSpec.new(minval: 8, maxval: 128, warp: 'lin', step: 1, default: length),
		action: { arg number;
			length = number.value.asInteger;
		},
		layout:\horz,
	)
	.font_(Font("Open Sans",11));

	tempoGUI = EZNumber(w,110@20, "BPM",
		controlSpec: ControlSpec.new(minval: 1, maxval: 800, warp: 'lin', step: 1/100, default: bpm),
		action: { arg number;
			bpm = number.value;
			linkClock.tempo = bpm/60;
		},
		layout:\horz,
	).font_(Font("Open Sans",11));

	StaticText(w,35@20).font_(Font("Open Sans",11)).string = "  bars";
	barsBox = NumberBox(w,40@20).font_(Font("Open Sans",11));
	StaticText(w,42@20).font_(Font("Open Sans",11)).string = "  beats";
	beatsBox = NumberBox(w,30@20).font_(Font("Open Sans",11));

	w.view.decorator.nextLine;

	EZNumber(w,100@20, "mult",
		controlSpec: ControlSpec.new(minval: 1, maxval: 32, warp: 'lin', step: 1, default: stepMultiplier),
		action: { arg number;
			stepMultiplier = number.value.asInteger;
		},
		layout:\horz,
	)
	.font_(Font("Open Sans",11));

	// set defaults:
	linkStartStop.valueAction = 2; // internal clock
	quantGUI.valueAction = 4; // no launch quantization

});

)