"""Crop the provided Wind/Candle recordings to their actual visual cue lengths."""
from pathlib import Path
import sys,json,shutil,hashlib,subprocess
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.godot/qa/audio_tools/python_modules'))
import numpy as np
from scipy.io import wavfile

ART=ROOT/'art/audio/user_presentation'
QA=ROOT/'.godot/qa/presentation_update'
ART.mkdir(parents=True,exist_ok=True);QA.mkdir(parents=True,exist_ok=True)
(ART/'.gdignore').write_text('')
report={'sources':{},'cues':{}}
for name in ['wind','candle']:
    source=Path.home()/'Downloads'/(name+'.mp3')
    shutil.copyfile(source,ART/source.name)
    decoded=QA/(name+'_decoded.wav')
    subprocess.run(['ffmpeg','-y','-v','error','-i',str(source),'-ar','48000','-ac','2','-c:a','pcm_f32le',str(decoded)],check=True)
    report['sources'][name]={'file':source.name,'sha256':hashlib.sha256(source.read_bytes()).hexdigest()}

def crop(name,target,start,duration,gain,attack,release,pan=0.0):
    rate,samples=wavfile.read(QA/(name+'_decoded.wav'))
    first=round(start*rate);length=round(duration*rate)
    clip=samples[first:first+length].astype(np.float64).copy()
    assert len(clip)==length
    t=np.arange(length)/rate
    envelope=np.sin(np.minimum(1,t/attack)*np.pi/2)**2 * np.sin(np.minimum(1,(duration-t)/release)*np.pi/2)**2
    clip*=envelope[:,None]
    applied_gain=min(gain,.70/max(float(abs(clip).max()),1e-9))
    clip*=applied_gain
    if pan<0:clip[:,1]*=1+pan
    if pan>0:clip[:,0]*=1-pan
    assert abs(clip).max()<.95
    target.parent.mkdir(parents=True,exist_ok=True)
    wavfile.write(target,rate,np.int16(np.clip(clip,-1,1)*32767))
    report['cues'][str(target.relative_to(ROOT))]={'source':name,'start':start,'duration':duration,
        'gain':applied_gain,'peak':float(abs(clip).max()),'rms':float(np.sqrt(np.mean(clip**2))),
        'fade_in':attack,'fade_out':release,'pan':pan}

# Calm portions of the provided gust; the existing runtime fades/cancels it
# when the platform finishes, falls, pauses or is reset.
for side,direction in [('left',-1),('right',1)]:
    crop('wind',ROOT/f'assets/audio/sfx/balance/weigh_{side}.wav',.8,.95,3.0,.10,.25,direction*.12)
    crop('wind',ROOT/f'assets/audio/sfx/balance/slide_{side}.wav',2.0,2.3,3.0,.14,.30,direction*.15)
# Use the steady flame, excluding the large blow-out transient near 7 s.
old=ROOT/'assets/audio/sfx/cards/paper_burn.wav'
backup=ROOT/'art/audio/card_burn/legacy_ahs.wav'
if old.exists() and not backup.exists():shutil.copyfile(old,backup)
crop('candle',old,1.0,1.65,5.0,.025,.16)
(ART/'preparation_report.json').write_text(json.dumps(report,indent=2))
print('PREPARED_USER_WIND_AND_CANDLE',report['cues'])
