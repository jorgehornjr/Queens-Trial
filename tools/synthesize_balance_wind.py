"""Deterministic airy gusts for the scale cue and directional platform slide."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUTPUT = Path(__file__).resolve().parents[1] / '.godot/qa/rejected_balance_wind'
OUTPUT.mkdir(parents=True, exist_ok=True)


def render(name, duration, direction, seed):
    rng = random.Random(seed)
    slow = low = mid = high = 0.0
    samples = []
    for i in range(round(RATE * duration)):
        t = i / RATE
        white = rng.uniform(-1, 1)
        slow += 0.008 * (white - slow)
        low += 0.034 * (white - low)
        mid += 0.14 * (white - mid)
        high += 0.38 * (white - high)
        # Colored broadband air, without a pitched oscillator or vocal sound.
        air = slow * 1.4 + low * 1.1 + mid * 0.48 + (white - high) * 0.11
        attack = min(1.0, t / 0.18)
        release = min(1.0, (duration - t) / 0.50)
        envelope = math.sin(attack * math.pi / 2) ** 2 * math.sin(release * math.pi / 2) ** 2
        swell = 0.72 + 0.28 * math.sin(math.pi * t / duration)
        value = air * envelope * swell
        pan = direction * (0.15 + 0.55 * t / duration)
        samples.append((value * math.sqrt((1-pan)/2), value * math.sqrt((1+pan)/2)))
    peak = max(abs(v) for pair in samples for v in pair)
    gain = 0.78 / peak
    pcm = b''.join(struct.pack('<hh', *(round(v * gain * 32767) for v in pair)) for pair in samples)
    with wave.open(str(OUTPUT / name), 'wb') as stream:
        stream.setnchannels(2)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm)


for suffix, direction in [('left', -1), ('right', 1)]:
    render(f'weigh_{suffix}.wav', 0.95, direction, 812)
    render(f'slide_{suffix}.wav', 2.30, direction, 1307)
print('Prepared four original stereo wind cues in', OUTPUT)
