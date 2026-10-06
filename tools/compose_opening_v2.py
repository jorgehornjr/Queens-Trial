"""A new sustained orchestral opening, retaining the queen's epic brass motif.

Unlike the first arrangement, the final camera movement keeps a full harmonic
bed. The runtime crossfades into gameplay; the score never fades to silence.
"""
from pathlib import Path
import sys,json,random,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1]
TOOLS=ROOT/'.godot/qa/audio_tools'
sys.path.insert(0,str(TOOLS/'python_modules'))
import mido,numpy as np
from scipy.io import wavfile

OUT=ROOT/'art/audio/opening_v2'
QA=ROOT/'.godot/qa/presentation_update'
OUT.mkdir(parents=True,exist_ok=True);QA.mkdir(parents=True,exist_ok=True)
(OUT/'.gdignore').write_text('')
old=ROOT/'assets/audio/music/priest_opening.ogg'
backup=ROOT/'art/audio/priest_opening/legacy_opening.ogg'
if old.exists() and not backup.exists():shutil.copyfile(old,backup)
RATE=48000
rng=random.Random(5906)
midi=mido.MidiFile(ticks_per_beat=480)
track=mido.MidiTrack();midi.tracks.append(track)
track.append(mido.MetaMessage('set_tempo',tempo=500000,time=0))
track.append(mido.MetaMessage('time_signature',numerator=4,denominator=4,time=0))
instruments=[('Low strings',48,0,78,44),('Cello',42,1,74,51),('Violas',41,2,74,32),
    ('Horns',60,3,86,75),('Low brass',57,4,72,65),('Choir',52,5,73,58),
    ('Harp',46,6,44,40),('Tubular bells',14,7,37,81),('Timpani',47,8,78,63),
    ('Orchestral cymbal',0,9,46,64),('High strings',48,10,73,91)]
events={ch:[] for _,_,ch,_,_ in instruments}
def event(ch,time,**values):events[ch].append((time,mido.Message(channel=ch,**values)))
def note(ch,time,duration,pitch,velocity):
    time=max(0,time+rng.uniform(-.007,.007))
    event(ch,time,type='note_on',note=pitch,velocity=max(1,min(127,velocity+rng.randint(-2,2))))
    event(ch,time+duration,type='note_off',note=pitch,velocity=0)
def chord(ch,time,duration,pitches,velocity):
    for pitch in pitches:note(ch,time,duration,pitch,velocity)

harmonies=[(0,3.8,[38,45,50,53,57,64]),(3.8,8.2,[34,41,46,50,53,57]),
    (8.2,12.4,[31,38,43,46,50,57]),(12.4,16.8,[33,40,45,50,55,61]),
    (16.8,18.8,[39,46,51,55,58,65]),(18.8,22.1,[33,40,45,49,55,58]),
    (22.1,24.9,[38,45,50,53,57,62]),(24.9,28,[34,41,46,50,53,60]),
    (28,31,[31,38,43,46,50,57]),(31,33.2,[33,40,45,50,55,61]),
    (33.2,36,[38,45,50,53,57,62])]
for start,end,p in harmonies:
    queen=start>=22.1
    build=start>=18.8
    sustain=end-start-.025
    chord(0,start,sustain,p[2:5],82 if queen else (64 if build else 50))
    note(1,start,sustain,p[0],88 if queen else (68 if build else 59))
    note(1,start+.025,sustain-.03,p[1],65 if queen else 43)
    chord(10,start+.055,sustain-.06,[x+12 for x in p[3:5]],78 if queen else (52 if build else 38))
    if start>=16.8:chord(5,start+.07,sustain-.08,p[2:5],74 if queen else 49)
    if build:
        chord(3,start+.015,sustain-.02,p[2:5],96 if 22.1<=start<28 else (87 if queen else 58))
        chord(4,start,sustain,p[:2],79 if queen else 45)
    if 3.8<=start<16.8:
        for offset in [.35,1.55,2.8]:
            if start+offset<end-.5:
                for j,pitch in enumerate([p[2],p[4],p[3]+12]):note(6,start+offset+j*.12,.85,pitch,32)
    if not build:
        for offset in np.arange(0,end-start-.7,1.8):note(1,start+float(offset),.9,p[1],35)

# A deliberate new arrival theme: longer notes, less restless ornamentation.
for t,d,p,v in [(3.95,1.8,62,51),(6.05,1.7,65,54),(8.45,1.8,67,55),
    (10.65,1.45,65,50),(12.65,1.7,64,53),(14.65,1.7,61,56),(16.55,1.3,62,57)]:note(2,t,d,p,v)
# Preserve the dramatic queen statement, with a sustained answering phrase.
for t,d,p,v in [(22.1,1.5,69,96),(23.75,.9,65,90),(24.9,1.3,70,99),(26.45,1.3,69,92),
    (28.05,1.4,67,86),(29.65,1.1,65,83),(31.05,1.5,64,84),(32.8,2.6,62,80)]:
    note(3,t,d,p,v);note(10,t+.045,d,p+12,v-16)
for t,p,v in [(18.8,45,55),(20.5,45,61),(22.1,38,88),(24.9,34,83),(28,31,76),(31,33,69),(33.2,38,64)]:note(8,t,1.7,p,v)
for t,p,v in [(22.16,62,60),(24.96,58,54)]:note(7,t,2.5,p,v)
note(9,22.12,3.4,49,47)

expression=[(0,51),(3.8,64),(8.2,66),(12.4,69),(16.8,74),(18.8,88),(21.7,107),
    (22.1,119),(24.9,127),(27.3,123),(28,119),(31,116),(33.2,113),(36,113)]
for name,program,ch,volume,pan in instruments:
    part=mido.MidiTrack();midi.tracks.append(part)
    part.append(mido.MetaMessage('track_name',name=name,time=0))
    part.append(mido.Message('program_change',channel=ch,program=program,time=0))
    for controller,value in [(7,volume),(10,pan),(91,43),(93,5)]:part.append(mido.Message('control_change',channel=ch,control=controller,value=value,time=0))
    if ch!=9:
        for t in np.arange(0,36,.15):event(ch,float(t),type='control_change',control=11,value=int(np.interp(t,[x[0] for x in expression],[x[1] for x in expression])))
    previous=0
    for t,message in sorted(events[ch],key=lambda x:(x[0],x[1].type=='note_on')):
        tick=round(t*960);message.time=tick-previous;part.append(message);previous=tick
    part.append(mido.MetaMessage('end_of_track',time=max(0,round(38*960)-previous)))
midi_path=OUT/'opening_v2.mid';midi.save(midi_path)
raw=QA/'opening_v2_raw.wav'
subprocess.run([str(next(TOOLS.rglob('fluidsynth.exe'))),'-ni','-F',str(raw),'-r',str(RATE),'-g','0.65',
    '-o','synth.reverb.room-size=0.78','-o','synth.reverb.damp=0.40','-o','synth.reverb.width=95',
    '-o','synth.reverb.level=0.34','-o','synth.chorus.active=0',str(TOOLS/'MuseScore_General.sf3'),str(midi_path)],check=True)
rate,pcm=wavfile.read(raw);mix=pcm[:RATE*35].astype(np.float64)/32768
t=np.arange(len(mix))/rate
gain=[(0,4.8),(3.8,5.6),(16.8,5.6),(18.8,1.4),(21.7,1.0),
    (22.1,1.10),(24.9,1.35),(27.5,1.28),(31,1.22),(35,1.22)]
mix*=np.interp(t,[x[0] for x in gain],[x[1] for x in gain])[:,None]
mix*=.88/max(float(np.max(np.abs(mix))),1e-9)
wave_path=QA/'opening_v2_mix.wav';wavfile.write(wave_path,rate,mix.astype(np.float32))
output=ROOT/'assets/audio/music/priest_opening.ogg'
# Anti-click boundary only. The runtime provides the musical crossfade.
subprocess.run(['ffmpeg','-y','-v','warning','-i',str(wave_path),'-af',
    'highpass=f=36,equalizer=f=280:t=q:w=1:g=-1.0,afade=t=in:d=0.25,afade=t=out:st=34.965:d=0.035',
    '-ar',str(RATE),'-c:a','libvorbis','-q:a','6',str(output)],check=True)
decoded=subprocess.check_output(['ffmpeg','-v','error','-i',str(output),'-f','f32le','-ac','2','-ar',str(RATE),'pipe:1'])
audio=np.frombuffer(decoded,dtype='<f4').reshape(-1,2)
windows=[float(np.sqrt(np.mean(audio[i:i+RATE//2]**2))) for i in range(0,len(audio),RATE//2)]
climax=max(windows[44:56]);tail=float(np.mean(windows[62:68]));peak_time=float(np.argmax(windows))*.5
report={'title':'O Chamado da Rainha','duration':len(audio)/RATE,'peak':float(abs(audio).max()),
    'rms_halfseconds':windows,'largest_halfsecond_at':peak_time,'tail_to_climax_rms':tail/climax,
    'queen_climax_verified':22.1<=peak_time<28.0,'sustained_final_camera':tail/climax>=.60,
    'runtime_crossfade_seconds':1.6}
(OUT/'verification_report.json').write_text(json.dumps(report,indent=2))
(OUT/'cue_sheet.json').write_text(json.dumps({'title':report['title'],'duration':35,
    'cues':[{'time':3.8,'scene':'confident arrival','music':'restrained viola and cello theme'},
            {'time':18.8,'scene':'queen reveal','music':'crescendo and darker harmony'},
            {'time':22.1,'scene':'queen close-up','music':'epic brass, choir, timpani'},
            {'time':24.9,'scene':'queen zoom out','music':'largest statement'},
            {'time':28,'scene':'final camera movement','music':'sustained full orchestration'},
            {'time':33.4,'scene':'return to board','music':'equal-power crossfade to gameplay'}]},indent=2))
assert report['peak']<.98 and report['queen_climax_verified'] and report['sustained_final_camera'],report
print('COMPOSED_OPENING_V2',report['largest_halfsecond_at'],report['tail_to_climax_rms'],flush=True)
# The final opening includes the new empty-board atmosphere before this score.
from extend_opening_atmosphere import extend_opening
extend_opening(refresh_base=True)
