"""Add eight seconds of quiet strings before the approved 35-second score.

Only the opening join is blended. Every later cue retains the approved music,
shifted by eight seconds, including the queen's climax and gameplay handoff.
"""
from pathlib import Path
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.godot/qa/audio_tools'
sys.path.insert(0, str(TOOLS / 'python_modules'))
import mido
import numpy as np
from scipy.io import wavfile

RATE = 48000
EXTRA = 8.0
OUT = ROOT / 'art/audio/opening_v2'
QA = ROOT / '.godot/qa/serene_opening'


def decode(path):
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path),
        '-f', 'f32le', '-ac', '2', '-ar', str(RATE), 'pipe:1'])
    return np.frombuffer(raw, dtype='<f4').reshape(-1, 2).copy()


def extend_opening(refresh_base=False):
    QA.mkdir(parents=True, exist_ok=True)
    output = ROOT / 'assets/audio/music/priest_opening.ogg'
    base = OUT / 'approved_walk_opening.ogg'
    base_report = OUT / 'approved_walk_verification.json'
    if refresh_base or not base.exists():
        assert abs(len(decode(output)) / RATE - 35.0) < .02
        shutil.copyfile(output, base)
        shutil.copyfile(OUT / 'verification_report.json', base_report)

    midi = mido.MidiFile(ticks_per_beat=480)
    tempo = mido.MidiTrack()
    tempo.append(mido.MetaMessage('set_tempo', tempo=500000))
    midi.tracks.append(tempo)
    # The same D-minor/add-nine harmony as the existing first chord.
    for channel, program, volume, pan, notes in [
        (0, 48, 65, 42, [(0, 9.6, 50, 42), (.12, 9.4, 53, 34), (.24, 9.2, 57, 32)]),
        (1, 42, 60, 54, [(0, 9.6, 38, 48), (0, 9.6, 45, 33)]),
        (2, 48, 48, 83, [(1.0, 8.6, 62, 29), (4.8, 4.8, 64, 26)]),
    ]:
        part = mido.MidiTrack()
        midi.tracks.append(part)
        part.append(mido.Message('program_change', channel=channel, program=program))
        for control, value in [(7, volume), (10, pan), (91, 50), (11, 62)]:
            part.append(mido.Message('control_change', channel=channel, control=control, value=value))
        events = []
        for start, length, pitch, velocity in notes:
            events.append((start, mido.Message('note_on', channel=channel, note=pitch, velocity=velocity)))
            events.append((start + length, mido.Message('note_off', channel=channel, note=pitch, velocity=0)))
        previous = 0
        for time, event in sorted(events, key=lambda item: item[0]):
            tick = round(time * 960)
            event.time = tick - previous
            previous = tick
            part.append(event)
        part.append(mido.MetaMessage('end_of_track', time=round(11 * 960) - previous))
    midi_path = OUT / 'serene_prelude.mid'
    midi.save(midi_path)
    raw = QA / 'prelude_raw.wav'
    subprocess.run([str(next(TOOLS.rglob('fluidsynth.exe'))), '-ni', '-F', str(raw),
        '-r', str(RATE), '-g', '0.65', '-o', 'synth.reverb.room-size=0.78',
        '-o', 'synth.reverb.damp=0.40', '-o', 'synth.reverb.width=95',
        '-o', 'synth.reverb.level=0.34', '-o', 'synth.chorus.active=0',
        str(TOOLS / 'MuseScore_General.sf3'), str(midi_path)], check=True)
    rate, pcm = wavfile.read(raw)
    assert rate == RATE
    prefix = pcm[:9 * RATE].astype(np.float64) / 32768
    # Match the restrained opening rather than normalizing to the brass peak.
    rms = np.sqrt(np.mean(prefix[2 * RATE:7 * RATE] ** 2))
    prefix *= .025 / max(float(rms), 1e-9)
    t = np.arange(len(prefix)) / RATE
    prefix *= np.sin(np.minimum(t / 1.2, 1.0) * np.pi / 2)[:, None]
    prefix *= np.cos(np.clip(t - EXTRA, 0, 1) * np.pi / 2)[:, None]
    body = decode(base)
    offset = round(EXTRA * RATE)
    mix = np.zeros((offset + len(body), 2), dtype=np.float64)
    mix[:len(prefix)] += prefix
    body[:RATE] *= np.sin(np.arange(RATE) / RATE * np.pi / 2)[:, None]
    mix[offset:] += body
    assert np.max(np.abs(mix)) < .98
    assert np.array_equal(mix[offset + RATE:], body[RATE:])
    wave_path = QA / 'serene_opening_mix.wav'
    wavfile.write(wave_path, RATE, mix.astype(np.float32))
    subprocess.run(['ffmpeg', '-y', '-v', 'warning', '-i', str(wave_path),
        '-ar', str(RATE), '-c:a', 'libvorbis', '-q:a', '8', str(output)], check=True)
    audio = decode(output)
    original = decode(base)
    unchanged = np.corrcoef(audio[(offset + RATE):].ravel(), original[RATE:].ravel())[0, 1]
    windows = [float(np.sqrt(np.mean(audio[i:i + RATE // 2] ** 2)))
        for i in range(0, len(audio), RATE // 2)]
    report = json.loads(base_report.read_text())
    report.update(duration=len(audio) / RATE, extra_atmosphere_seconds=EXTRA,
        peak=float(abs(audio).max()), rms_halfseconds=windows,
        largest_halfsecond_at=float(np.argmax(windows)) * .5,
        approved_body_correlation=float(unchanged), approved_body_offset_seconds=EXTRA)
    assert abs(report['duration'] - 43) < .02 and unchanged > .999
    assert 30.1 <= report['largest_halfsecond_at'] < 36
    (OUT / 'verification_report.json').write_text(json.dumps(report, indent=2))
    (OUT / 'cue_sheet.json').write_text(json.dumps({
        'title': report['title'], 'duration': 43,
        'cues': [
            {'time': 0, 'scene': 'serene world establishing shot', 'music': 'quiet sustained D-minor strings'},
            {'time': 5.2, 'scene': 'second empty-board shot', 'music': 'add-nine harmony and natural orchestral join'},
            {'time': 11.8, 'scene': 'native slow walk', 'music': 'approved viola and cello theme'},
            {'time': 26.8, 'scene': 'queen reveal', 'music': 'approved crescendo'},
            {'time': 30.1, 'scene': 'queen close-up', 'music': 'approved epic brass, choir and timpani'},
            {'time': 32.9, 'scene': 'queen zoom out', 'music': 'approved largest statement'},
            {'time': 41.4, 'scene': 'return to board', 'music': 'equal-power crossfade to gameplay'},
        ]}, indent=2))
    print('SERENE_OPENING', report['duration'], report['largest_halfsecond_at'], unchanged)


if __name__ == '__main__':
    extend_opening()
