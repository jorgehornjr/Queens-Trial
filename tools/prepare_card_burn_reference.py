"""Reproduce the archived AHS excerpt without overwriting the current Candle.

Authoring dependencies: NumPy/SciPy in .godot/qa/audio_tools/python_modules.
Source audio stays in the ignored QA folder. Only the short treated excerpt
is archived in QA; the game now uses the user's Candle recording.
"""
from pathlib import Path
import argparse, json, sys, hashlib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.godot/qa/audio_tools/python_modules'))
import numpy as np
from scipy.io import wavfile
from scipy import signal, ndimage

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, default=ROOT / '.godot/qa/card_burn_reference/source_audio.wav')
parser.add_argument('--start', type=float, default=25.82)
parser.add_argument('--duration', type=float, default=2.05)
args = parser.parse_args()
qa = ROOT / '.godot/qa/card_burn_reference'
qa.mkdir(parents=True, exist_ok=True)
rate, source = wavfile.read(args.source)
if np.issubdtype(source.dtype, np.integer):
    source = source.astype(np.float64) / (float(np.iinfo(source.dtype).max) + 1)
else:
    source = source.astype(np.float64)
assert rate == 48000 and source.ndim == 2 and source.shape[1] == 2
begin = round(args.start * rate)
end = begin + round(args.duration * rate)
assert 0 <= begin < end <= len(source)

# Learn the repetitive soundtrack from the adjacent shots, excluding the book
# and its immediate transition. Nearest spectral frames give a conservative
# background estimate, rather than inventing replacement crackles.
context_begin = max(0, begin - round(9.5 * rate))
context_end = min(len(source), end + round(7.5 * rate))
context = source[context_begin:context_end]
spectra = []
for channel in range(2):
    freq, times, z = signal.stft(context[:, channel], fs=rate, nperseg=2048,
                                 noverlap=1536, boundary='zeros')
    spectra.append(z)
magnitude = np.sqrt((np.abs(spectra[0])**2 + np.abs(spectra[1])**2) / 2)
absolute_times = times + context_begin / rate
outside = (absolute_times < args.start - .45) | (absolute_times > args.start + args.duration + .45)
target_frames = np.where((absolute_times >= args.start - .1) &
                         (absolute_times <= args.start + args.duration + .1))[0]
candidate_frames = np.where(outside)[0]
band = (freq >= 100) & (freq <= 9000)
scale = np.maximum(np.median(magnitude[band][:, candidate_frames], axis=1), 1e-6)
features = np.log1p(magnitude[band] / scale[:, None])
features /= np.maximum(np.linalg.norm(features, axis=0), 1e-12)
similarities = features[:, candidate_frames].T @ features[:, target_frames]
background = magnitude.copy()
for j, frame in enumerate(target_frames):
    nearest = candidate_frames[np.argpartition(similarities[:, j], -18)[-18:]]
    estimate = np.median(magnitude[:, nearest], axis=1)
    ratio = magnitude[band, frame] / np.maximum(estimate[band], 1e-8)
    estimate *= np.clip(np.quantile(ratio, .3), .4, 2.0)
    background[:, frame] = np.minimum(magnitude[:, frame], estimate)

harmonic = ndimage.median_filter(magnitude, size=(1, 31))
percussive = ndimage.median_filter(magnitude, size=(25, 1))
transient_mask = percussive**2 / np.maximum(percussive**2 + 1.5*harmonic**2, 1e-16)
novelty_mask = np.maximum(0, magnitude**2 - .85*background**2) / np.maximum(magnitude**2, 1e-16)
effect_mask = ndimage.gaussian_filter(.72*novelty_mask + .28*transient_mask, (.7, .6))

raw = source[begin:end].copy()
def finish(samples, name, peak=.72):
    samples = samples.copy()
    n = len(samples)
    fade_in = min(n, round(.008*rate))
    fade_out = min(n, round(.075*rate))
    samples[:fade_in] *= np.linspace(0, 1, fade_in)[:, None]
    samples[-fade_out:] *= np.linspace(1, 0, fade_out)[:, None]
    samples *= peak / max(float(np.max(np.abs(samples))), 1e-9)
    path = qa / name
    wavfile.write(path, rate, np.round(samples*32767).astype('<i2'))
    return path, samples

raw_path, raw_finished = finish(raw, 'reference_excerpt.wav')
variants = {}
for name, floor in [('treated_light', .48), ('treated_stronger', .24)]:
    # Shared stereo mask preserves phase and stereo image. A gain floor avoids
    # the watery/metallic artifacts of aggressive spectral gating.
    mask = floor + (1-floor)*effect_mask
    channels = []
    for z in spectra:
        _, reconstructed = signal.istft(z*mask, fs=rate, nperseg=2048,
                                         noverlap=1536, boundary=True)
        channels.append(reconstructed[begin-context_begin:end-context_begin])
    audio = np.stack(channels, axis=1)
    audio = signal.sosfiltfilt(signal.butter(2, 65, fs=rate, btype='highpass', output='sos'), audio, axis=0)
    path, samples = finish(audio, name+'.wav')
    variants[name] = {
        'path': str(path),
        'rms': float(np.sqrt(np.mean(samples**2))),
        'waveform_correlation_to_reference': float(np.corrcoef(raw_finished.reshape(-1), samples.reshape(-1))[0, 1]),
        'minimum_spectral_gain_db': float(20*np.log10(floor)),
    }
    if name == 'treated_light':
        destination = qa / 'legacy_ahs_treated.wav'
        destination.write_bytes(path.read_bytes())

report = {
    'source_url': 'https://www.youtube.com/watch?v=o7MXJvhDEQY',
    'source_title': 'American Horror Story: 13 | Title Sequence - Season 13 | FX',
    'source_start_seconds': args.start,
    'source_end_seconds': args.start + args.duration,
    'book_visible_approximately': [25.8, 27.1],
    'duration': args.duration, 'sample_rate': rate, 'channels': 2,
    'original_synthesis': False, 'source_phase_preserved': True,
    'installed_variant': 'treated_light',
    'variants': variants,
    'reference_excerpt': str(raw_path),
    'sha256': hashlib.sha256((qa/'legacy_ahs_treated.wav').read_bytes()).hexdigest(),
    'limitation': 'Background music and sound effect overlap; this is reduced music, not a clean isolated production stem.',
}
(qa / 'processing_report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
