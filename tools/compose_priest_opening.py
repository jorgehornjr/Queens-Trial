"""Original 35-second orchestral cue, written to the existing camera timing.

Authoring only: requires mido/numpy/scipy in .godot/qa/audio_tools/python_modules,
FluidSynth and the MIT MuseScore General soundfont. Ships only the rendered OGG.
"""
from pathlib import Path
import sys,random,json,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1]
TOOLS=ROOT/'.godot/qa/audio_tools'
sys.path.insert(0,str(TOOLS/'python_modules'))
import mido
import numpy as np
from scipy.io import wavfile

OUT=ROOT/'art/audio/priest_opening'
OUT.mkdir(parents=True,exist_ok=True)
(ROOT/'art/audio/.gdignore').write_text('',encoding='utf-8')
SR=48000
rng=random.Random(317)
midi=mido.MidiFile(ticks_per_beat=480)
conductor=mido.MidiTrack();midi.tracks.append(conductor)
conductor.append(mido.MetaMessage('set_tempo',tempo=500000,time=0))
conductor.append(mido.MetaMessage('time_signature',numerator=4,denominator=4,time=0))
instruments=[('Low strings',48,0,78,44),('Cello',42,1,72,51),('Violas',41,2,70,32),('Horns',60,3,84,75),('Low brass',57,4,67,65),('Choir',52,5,72,58),('Harp',46,6,48,40),('Tubular bells',14,7,37,81),('Timpani',47,8,80,63),('Orchestral cymbal',0,9,48,64),('High strings',48,10,69,91)]
events={ch:[] for _,_,ch,_,_ in instruments}
def event(ch,t,**kwargs):events[ch].append((t,mido.Message(channel=ch,**kwargs)))
def note(ch,t,d,p,v):
    t=max(0,t+rng.uniform(-.012,.012))
    event(ch,t,type='note_on',note=p,velocity=min(127,max(1,v+rng.randint(-3,3))))
    event(ch,min(34.5,t+d),type='note_off',note=p,velocity=0)
def chord(ch,t,d,pitches,v):
    for n in pitches:note(ch,t,d,n,v)

# Suspended minor harmony, restrained pulse; the full orchestration is withheld
# until the queen's face appears. Seconds are camera cues, rather than a loop.
harmonies=[(0,4.6,[38,45,50,53,57,64]),(4.6,9.8,[34,41,46,50,57,60]),(9.8,13.4,[31,38,43,46,53,57]),(13.4,17.0,[33,40,45,50,53,57]),(17.0,18.8,[39,46,51,55,58,65]),(18.8,22.1,[33,40,45,49,55,58]),(22.1,24.9,[38,45,50,53,57,62]),(24.9,28.0,[34,41,46,50,53,60]),(28.0,30.9,[31,38,43,46,50,57]),(30.9,33.2,[33,40,45,50,55,61]),(33.2,34.6,[38,45,50,53,57,62])]
for start,end,pitches in harmonies:
    majestic=start>=22.1 and start<28
    chord(0,start,end-start+.08,pitches[2:5],48 if start<17 else (80 if majestic else 62))
    note(1,start,end-start-.05,pitches[0],54 if start<17 else (85 if majestic else 66))
    note(1,start+.035,end-start-.1,pitches[1],39 if start<17 else 62)
    chord(10,start+.08,end-start-.1,[n+12 for n in pitches[3:5]],36 if start<18.8 else (74 if majestic else 48))
    if start>=17:
        chord(5,start+.09,end-start-.16,[pitches[2],pitches[3],pitches[4]],44 if start<22.1 else (76 if majestic else 49))
    if start>=18.8:
        chord(3,start+.02,end-start-.16,pitches[2:5],43 if start<22.1 else (92 if majestic else 58))
        chord(4,start,end-start-.24,pitches[:2],32 if start<22.1 else (78 if majestic else 47))
    # The first harp sparkles sounded like a UI chime before the opening.
    # Keep the opening strings, and introduce harp only after the arrival cue.
    if 2.6<=start<18.8:
        for offset in [0.16,.96,1.88]:
            if start+offset<end-.3:
                for j,n in enumerate([pitches[2],pitches[3]+12,pitches[4]+12]):note(6,start+offset+j*.13,1.1,n,40)

# A short, deliberate theme accompanies the first foot through the portal and
# the two head turns. Its enlarged answer announces the antagonist.
for t,d,n,v in [(4.75,1.25,69,55),(6.22,1.1,65,50),(7.52,1.18,64,46),(8.80,.85,62,45),(10.15,1.35,67,53),(11.70,1.25,65,48),(13.2,1.35,64,48),(14.80,1.1,61,52),(16.05,.85,62,47)]:note(2,t,d,n,v)
for t,d,n,v in [(22.1,1.5,69,93),(23.75,.85,65,87),(24.9,1.25,70,95),(26.45,1.25,69,86),(28.05,1.35,67,64),(29.6,1.05,65,57),(30.95,1.35,64,54),(32.5,1.5,62,45)]:
    note(3,t,d,n,v);note(10,t+.07,d,n+12,max(32,v-15))
for t,n,v in [(18.8,45,54),(20.5,45,57),(22.1,38,91),(24.9,34,85),(28,31,56),(33.2,38,42)]:note(8,t,1.65,n,v)
for t,n,v in [(22.16,62,62),(24.96,58,54)]:note(7,t,2.4,n,v)
note(9,22.12,3.0,49,48)

def expression(t):
    keys=[(0,38),(2.5,55),(4.6,65),(10,67),(16.5,65),(18.8,76),(21.7,98),(22.1,112),(24.9,127),(27.3,111),(28,83),(31,66),(33.2,48),(34.4,8)]
    return int(np.interp(t,[x[0] for x in keys],[x[1] for x in keys]))
for name,program,ch,volume,pan in instruments:
    track=mido.MidiTrack();midi.tracks.append(track)
    track.append(mido.MetaMessage('track_name',name=name,time=0))
    track.append(mido.Message('program_change',channel=ch,program=program,time=0))
    for controller,value in [(7,volume),(10,pan),(91,40),(93,8)]:track.append(mido.Message('control_change',channel=ch,control=controller,value=value,time=0))
    if ch!=9:
        for t in np.arange(0,34.5,.2):event(ch,float(t),type='control_change',control=11,value=expression(t))
    previous=0
    for t,message in sorted(events[ch],key=lambda x:(x[0],x[1].type=='note_on')):
        tick=round(t*960);message.time=tick-previous;track.append(message);previous=tick
    track.append(mido.MetaMessage('end_of_track',time=max(0,round(35*960)-previous)))
midi_path=OUT/'priest_opening.mid';midi.save(midi_path)
fluidsynth=next(TOOLS.rglob('fluidsynth.exe'))
raw=ROOT/'.godot/qa/priest_opening_raw.wav'
subprocess.run([str(fluidsynth),'-ni','-F',str(raw),'-r',str(SR),'-g','0.65','-o','synth.reverb.room-size=0.72','-o','synth.reverb.damp=0.40','-o','synth.reverb.width=95','-o','synth.reverb.level=0.32','-o','synth.chorus.active=0',str(TOOLS/'MuseScore_General.sf3'),str(midi_path)],check=True)
# Preserve the score's dynamic range: automatic loudness compression would
# raise the entrance and flatten the queen's musical statement. Ride the mix
# smoothly against the camera cues, then apply a single static peak gain.
rate,pcm=wavfile.read(raw)
mix=pcm[:SR*35].astype(np.float64)/32768.0
t=np.arange(len(mix))/rate
keys=[(0,5.5),(4.6,7.5),(16.5,7.5),(18.8,1.5),(21.65,1.0),(22.1,1.1),(24.55,1.3),(24.9,1.72),(27.25,1.6),(28.0,.9),(30.9,.75),(33.2,.68),(34.0,.6),(35,.6)]
gain=np.interp(t,[k[0] for k in keys],[k[1] for k in keys])
mix*=gain[:,None]
mix*=0.86/np.max(np.abs(mix))
mix_path=ROOT/'.godot/qa/priest_opening_mix.wav'
wavfile.write(mix_path,rate,mix.astype(np.float32))
output=OUT/'legacy_opening.ogg'
shutil.copyfile(TOOLS/'MuseScore_General_License.md',output.with_name('priest_opening_license.txt'))
subprocess.run(['ffmpeg','-y','-v','warning','-i',str(mix_path),'-af','highpass=f=36,equalizer=f=280:t=q:w=1:g=-1.5,afade=t=in:d=0.22,afade=t=out:st=33.75:d=1.25','-ar',str(SR),'-c:a','libvorbis','-q:a','6',str(output)],check=True)
# Check the encoded delivery, including lossy-codec peak overshoot.
decoded=subprocess.check_output(['ffmpeg','-v','error','-i',str(output),'-f','f32le','-ac','2','-ar',str(SR),'pipe:1'])
samples=np.frombuffer(decoded,dtype='<f4').reshape(-1,2)
rms=[float(np.sqrt(np.mean(samples[i:i+SR//2]**2))) for i in range(0,len(samples),SR//2)]
peak_time=float(np.argmax(rms))*.5
report={'duration':len(samples)/SR,'peak':float(np.max(np.abs(samples))),'rms_halfseconds':rms,'largest_halfsecond_at':peak_time,'queen_climax_verified':22.1<=peak_time<28.0}
(ROOT/'.godot/qa/audio_music_qa.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
assert report['queen_climax_verified'] and report['peak']<.98,report
(OUT/'cue_sheet.json').write_text(json.dumps({'title':'O Limiar da Rainha','duration_seconds':35,'original_score':True,'tonality':'D minor','cues':[{'time':2.6,'scene':'portal opens','music':'suspended strings and harp'},{'time':4.6,'scene':'priest enters','music':'quiet viola theme'},{'time':18.8,'scene':'queen revealed','music':'crescendo and unresolved dominant'},{'time':22.1,'scene':'queen face then zoom out','music':'full low brass, horns, choir and timpani'},{'time':24.9,'scene':'zoom out from queen','music':'largest orchestral statement'},{'time':33.75,'scene':'return to board','music':'cadence and fade to gameplay'}]},indent=2),encoding='utf-8')
print('COMPOSED_ORIGINAL_OPENING',output,flush=True)
