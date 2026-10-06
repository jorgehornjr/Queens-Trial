"""Portal noise atlas and archived synthetic Foley rejected by the user.

The game's burn sound is now prepared by prepare_card_burn_reference.py.
This script must never overwrite that reference-based asset.
"""
from pathlib import Path
import sys, wave, shutil
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.godot/qa/audio_tools/python_modules'))
import numpy as np
from scipy.ndimage import gaussian_filter
from scipy.signal import butter,sosfilt
from PIL import Image

SR=48000
DURATION=2.05
rng=np.random.default_rng(23024)
n=round(SR*DURATION);t=np.arange(n)/SR
def band(data,lo,hi):return sosfilt(butter(2,[lo,hi],btype='bandpass',fs=SR,output='sos'),data)
white=rng.normal(0,1,(n,2))
# Flame body, papery hiss and scattered dry crackles have separate envelopes.
flutter=.65+.20*np.sin(t*31)+.15*np.sin(t*53+.7)
fire=band(white,90,1700)*np.sin(np.pi*np.clip(t/1.95,0,1))[:,None]**.7*flutter[:,None]*.24
ignition=band(white,140,4600)*(np.clip(t/.05,0,1)*np.exp(-t*7))[:,None]*.21
paper=band(white,1800,10000)*(np.sin(np.pi*np.clip(t/1.88,0,1))**1.5)[:,None]*.034
crackles=np.zeros((n,2))
for _ in range(82):
    start=rng.uniform(.05,1.83);length=rng.uniform(.007,.058)
    k=min(round(length*SR),n-round(start*SR));x=np.arange(k)/SR
    envelope=np.exp(-x*rng.uniform(90,240))*(1-np.exp(-x*2400))
    burst=band(rng.normal(0,1,k),600,9500)*envelope
    pan=rng.uniform(-.6,.6);gain=rng.uniform(.035,.20)*(1.15-.30*start)
    a=round(start*SR);crackles[a:a+k,0]+=burst*gain*np.sqrt((1-pan)/2);crackles[a:a+k,1]+=burst*gain*np.sqrt((1+pan)/2)
audio=fire+ignition+paper+crackles
fade=np.clip((DURATION-t)/.27,0,1)*np.clip(t/.012,0,1)
audio*=fade[:,None];audio*=.80/max(np.max(np.abs(audio)),1e-9)
output=ROOT/'.godot/qa/card_burn_reference/rejected_synthetic.wav';output.parent.mkdir(parents=True,exist_ok=True)
with wave.open(str(output),'wb') as f:
    f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.round(audio*32767).astype('<i2').tobytes())

rng=np.random.default_rng(703)
texture=[]
for scales,weights in [([25,10,3],[.60,.26,.14]),([10,3,1],[.42,.40,.18]),([4,1],[.62,.38])]:
    noise=sum(gaussian_filter(rng.normal(0,1,(256,256)),scale,mode='wrap')/scale**-.8*weight for scale,weight in zip(scales,weights))
    noise=(noise-noise.min())/(noise.max()-noise.min());texture.append(np.round(noise*255).astype('uint8'))
atlas=ROOT/'assets/textures/effects/priest_rift_noise.png';atlas.parent.mkdir(parents=True,exist_ok=True)
Image.fromarray(np.stack(texture,axis=2)).save(atlas)
licenses=ROOT/'art/audio/priest_opening';licenses.mkdir(parents=True,exist_ok=True)
for name in ['MuseScore_General_License.md','MuseScore_General_Sample_Sources.csv']:
    shutil.copyfile(ROOT/'.godot/qa/audio_tools'/name,licenses/name)
print('ARCHIVED_REJECTED_SYNTHETIC_FIRE',output)
print('CREATED_RIFT_NOISE',atlas)
