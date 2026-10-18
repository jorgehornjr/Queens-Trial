"""Original celestial menu score: one cinematic entrance, then a quiet ostinato.

Authoring uses the existing FluidSynth/MuseScore tools in .godot/qa/audio_tools.
No audio or notes are extracted from the Endwalker reference. Runtime needs only OGG.
"""
from pathlib import Path
import json
import random
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.godot/qa/audio_tools'
sys.path.insert(0, str(TOOLS / 'python_modules'))
import mido
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

RATE = 48000
DURATION = 148.0
BODY_START = 12.0
OUT = ROOT / 'art/audio/main_menu'
QA = ROOT / '.godot/qa/menu_score'
OUT.mkdir(parents=True, exist_ok=True)
QA.mkdir(parents=True, exist_ok=True)
DEST = ROOT / 'assets/audio/music/menu_orbits.ogg'
RNG = random.Random(41805)

score = mido.MidiFile(ticks_per_beat=480)
conductor = mido.MidiTrack()
score.tracks.append(conductor)
conductor.append(mido.MetaMessage('set_tempo', tempo=1000000))
conductor.append(mido.MetaMessage('time_signature', numerator=4, denominator=4))

# GM programs are zero based. Two alternating string channels allow soft overlaps.
parts = [
    ('Harp ostinato', 46, 0, 85, 48),
    ('Soft strings A', 49, 1, 58, 35),
    ('Soft strings B', 49, 2, 58, 87),
    ('Distant choir', 52, 3, 40, 70),
    ('Cello foundation', 42, 4, 52, 58),
    ('Entrance horns', 60, 5, 51, 76),
    ('Celesta light', 8, 6, 50, 85),
    ('Air flute', 73, 7, 48, 35),
    ('Entrance timpani', 47, 8, 58, 64),
    ('Entrance cymbal', 0, 9, 40, 74),
    ('Piano motif', 0, 10, 73, 68),
]
events = {ch: [] for _, _, ch, _, _ in parts}

def event(ch, t, **values):
    events[ch].append((t, mido.Message(channel=ch, **values)))

def note(ch, t, duration, pitch, velocity):
    t = max(0.0, t + RNG.uniform(-0.006, 0.006))
    event(ch, t, type='note_on', note=pitch, velocity=max(1, min(127, velocity + RNG.randint(-2, 2))))
    event(ch, t + duration, type='note_off', note=pitch, velocity=0)

def chord(ch, t, duration, pitches, velocity):
    for index, pitch in enumerate(pitches):
        note(ch, t + index * 0.008, duration, pitch, velocity)

def pad(index, t, duration, bass, voices, velocity):
    ch = 1 + index % 2
    chord(ch, t, duration + 0.24, voices, velocity)
    note(4, t, duration - 0.04, bass, velocity - 3)
    note(3, t + 0.10, duration - 0.15, voices[1], max(20, velocity - 14))
    # Swell each chord gently. Alternating channels preserve the reverb/legato tail.
    for offset in np.arange(0.0, duration + 0.30, 0.12):
        attack = min(float(offset) / 0.65, 1.0)
        release = min(max((duration + 0.30 - float(offset)) / 0.50, 0.0), 1.0)
        value = int(36 + 56 * min(attack, release))
        event(ch, t + float(offset), type='control_change', control=11, value=value)

# The entrance is written to the approved 11.5-second planetary movement.
pad(0, 0.0, 4.0, 40, [55, 59, 64, 66], 42)
pad(1, 4.0, 3.0, 36, [55, 59, 62, 64], 52)
pad(2, 7.0, 5.0, 43, [54, 59, 62, 69], 65)
for t, pitch in [(1.5, 52), (2.6, 59), (3.7, 66), (4.3, 67), (4.9, 71), (5.5, 74), (6.0, 76)]:
    note(0, t, 2.0, pitch, 41 + int(t * 2))
for index, pitch in enumerate([55, 59, 62, 67, 69, 74, 79, 83]):
    note(0, 6.50 + index * 0.063, 1.9, pitch, 58 + index * 2)
chord(5, 7.05, 3.9, [55, 59, 62], 62)
for t, pitch, velocity in [(7.02, 83, 75), (7.82, 78, 62), (8.72, 74, 55), (9.60, 79, 49)]:
    note(6, t, 2.5, pitch, velocity)
note(8, 7.04, 2.0, 43, 47)
note(9, 6.94, 2.4, 49, 31)
for t in np.arange(0.0, 12.0, 0.12):
    expression = np.interp(t, [0, 4, 6.8, 7.2, 9.7, 12], [28, 54, 77, 111, 90, 60])
    for ch in [3, 4, 5]:
        event(ch, float(t), type='control_change', control=11, value=int(expression))

# An original four-bar cycle: Em9, Cmaj9, Gmaj9, D(add9).
# Only this restrained musical material repeats; the entrance effects never recur.
harmonies = [
    (40, [55, 59, 64, 66], [52, 59, 64, 66, 67, 71, 76, 71]),
    (36, [55, 59, 62, 64], [48, 55, 59, 62, 64, 67, 74, 67]),
    (43, [54, 59, 62, 69], [55, 62, 66, 69, 71, 74, 78, 74]),
    (38, [57, 62, 64, 66], [50, 57, 62, 64, 66, 69, 76, 69]),
]
melody = [(0.0, 76, 1.4), (2.0, 71, 1.7), (4.0, 74, 2.2), (7.0, 72, 1.4),
          (9.0, 71, 1.9), (12.0, 69, 1.7), (14.0, 66, 1.7)]
for cycle in range(8):
    start = BODY_START + cycle * 16.0
    for block, (bass, voices, arpeggio) in enumerate(harmonies):
        t = start + block * 4.0
        pad(3 + cycle * 4 + block, t, 4.0, bass, voices, 48 + (cycle % 3))
        for step, pitch in enumerate(arpeggio):
            # A soft, steady eighth-note wave, with alternating hand accents.
            velocity = 51 + (5 if step in [0, 4] else 0)
            note(0, t + step * 0.5, 1.25, pitch, velocity)
    for offset, pitch, duration in melody:
        note(10, start + offset, duration, pitch, 46 if cycle % 2 == 0 else 43)
    if cycle % 2 == 1:
        for offset, pitch in [(0.2, 64), (4.2, 67), (8.2, 66), (12.2, 64)]:
            note(7, start + offset, 2.8, pitch, 38)
    for t in np.arange(start, start + 16.0, 0.15):
        breath = 72 + 6 * np.sin((t - start) * np.pi / 8.0)
        for ch in [3, 4, 7]:
            event(ch, float(t), type='control_change', control=11, value=int(breath))

for name, program, ch, volume, pan in parts:
    track = mido.MidiTrack()
    score.tracks.append(track)
    track.append(mido.MetaMessage('track_name', name=name))
    track.append(mido.Message('program_change', channel=ch, program=program))
    for controller, value in [(7, volume), (10, pan), (91, 46), (93, 0), (11, 85)]:
        track.append(mido.Message('control_change', channel=ch, control=controller, value=value))
    previous = 0
    for t, message in sorted(events[ch], key=lambda pair: (pair[0], pair[1].type == 'note_on')):
        tick = round(t * 480)
        message.time = tick - previous
        track.append(message)
        previous = tick
    track.append(mido.MetaMessage('end_of_track', time=max(0, round(DURATION * 480) - previous)))
mid = OUT / 'menu_orbits.mid'
score.save(mid)

raw = QA / 'orchestra.wav'
subprocess.run([str(next(TOOLS.rglob('fluidsynth.exe'))), '-ni', '-F', str(raw), '-r', str(RATE), '-g', '0.65',
    '-o', 'synth.reverb.room-size=0.82', '-o', 'synth.reverb.damp=0.36',
    '-o', 'synth.reverb.width=94', '-o', 'synth.reverb.level=0.38',
    '-o', 'synth.chorus.active=0', str(TOOLS / 'MuseScore_General.sf3'), str(mid)], check=True)
rate, pcm = wavfile.read(raw)
mix = np.zeros((int(DURATION * RATE), 2), dtype=np.float64)
count = min(len(mix), len(pcm))
mix[:count] = pcm[:count].astype(np.float64) / 32768.0
time = np.arange(len(mix)) / RATE

# Quiet orbital air, followed by a short glass-like sheen at the logo's entrance.
# These synthesized one-shot layers are separate from the repeated musical phrase.
noise_rng = np.random.default_rng(92714)
air_len = int(7.0 * RATE)
air = sosfilt(butter(2, [140, 2400], btype='bandpass', fs=RATE, output='sos'), noise_rng.normal(0, 1, air_len))
air_time = np.arange(air_len) / RATE
air_env = np.sin(np.pi * np.clip(air_time / 7.0, 0, 1)) ** 2 * (0.3 + 0.7 * air_time / 7.0)
air *= air_env * 0.016
offset = int(0.55 * RATE)
mix[offset:offset + air_len, 0] += air
mix[offset:offset + air_len, 1] += np.roll(air, int(0.018 * RATE)) * 0.9
duration = 3.7
glint_time = np.arange(int(duration * RATE)) / RATE
glint = np.zeros(len(glint_time))
for frequency, decay, gain in [(1318.51, 2.5, .024), (1975.53, 3.8, .016), (2637.02, 5.0, .008), (3951.07, 6.0, .004)]:
    glint += np.sin(2 * np.pi * frequency * glint_time) * np.exp(-glint_time * decay) * gain
glint *= np.minimum(glint_time / 0.004, 1.0)
for delay, gain in [(0.0, 1.0), (0.22, .28), (0.48, .13)]:
    offset = int((7.0 + delay) * RATE)
    mix[offset:offset + len(glint), 0] += glint * gain
    mix[offset:offset + len(glint), 1] += np.roll(glint, int(.011 * RATE)) * gain * 0.9

# One static mastering gain keeps the entrance dynamic; the score ends once.
mix *= np.clip(time / 0.65, 0, 1)[:, None]
mix *= (1.0 - np.clip((time - 136.0) / 12.0, 0, 1))[:, None]
body_rms = float(np.sqrt(np.mean(mix[int(20 * RATE):int(132 * RATE)] ** 2)))
peak = float(np.max(np.abs(mix)))
mix *= min(0.10 / max(body_rms, 1e-8), 0.84 / max(peak, 1e-8))
wave = QA / 'master.wav'
wavfile.write(wave, RATE, mix.astype(np.float32))
subprocess.run(['ffmpeg', '-y', '-v', 'warning', '-i', str(wave), '-af', 'highpass=f=35',
    '-c:a', 'libvorbis', '-q:a', '6', str(DEST)], check=True)
subprocess.run(['ffmpeg', '-y', '-v', 'warning', '-i', str(DEST), '-c:a', 'libmp3lame', '-q:a', '2',
    str(ROOT / 'docs/previews/main_menu/menu_orbits.mp3')], check=True)
decoded = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(DEST), '-f', 'f32le', '-ac', '2', '-ar', str(RATE), 'pipe:1'])
audio = np.frombuffer(decoded, dtype='<f4').reshape(-1, 2)
windows = [float(np.sqrt(np.mean(audio[i:i + RATE] ** 2))) for i in range(0, len(audio), RATE)]
report = {
    'title': 'Entre Duas Órbitas', 'duration_seconds': len(audio) / RATE,
    'original_composition': True, 'reference_audio_used': False, 'runtime_loop': False,
    'body_starts_at': BODY_START, 'motif_seconds': 16.0, 'motif_repetitions': 8,
    'logo_sheen_at': 7.0, 'peak': float(np.max(np.abs(audio))),
    'rms_each_second': windows,
    'body_rms': float(np.sqrt(np.mean(audio[int(20 * RATE):int(132 * RATE)] ** 2))),
    'body_min_second_rms': min(windows[14:132]), 'end_rms': windows[-1],
}
assert abs(report['duration_seconds'] - DURATION) < .05
assert report['peak'] < .98 and report['body_min_second_rms'] > .008
assert report['end_rms'] < .002
(OUT / 'verification_report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
(OUT / 'cue_sheet.json').write_text(json.dumps({
    'title': report['title'], 'duration_seconds': DURATION, 'key': 'E minor / relative G major',
    'cues': [
        {'time': 0.0, 'music': 'quiet strings and distant choir'},
        {'time': 0.55, 'music': 'orbital air rising beneath the score'},
        {'time': 6.5, 'music': 'harp glissando into the light'},
        {'time': 7.0, 'music': 'single crystalline logo sheen, horns and celesta'},
        {'time': 12.0, 'music': 'continuous harp, piano motif, strings and choir; no entrance effects'},
        {'time': 136.0, 'music': 'final fade and reverb tail'},
        {'time': 148.0, 'music': 'end; no automatic restart'},
    ],
}, indent=2), encoding='utf-8')
print('MENU_SCORE', report['duration_seconds'], 'seconds; peak', report['peak'], 'body RMS', report['body_rms'], flush=True)
