"""Create original, reproducible paper and cloth foley. Requires only NumPy."""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 48000
RNG = np.random.default_rng(16102026)


def noise(size, low, high, pink=0.0):
    frequencies = np.fft.rfftfreq(size, 1 / RATE)
    spectrum = np.fft.rfft(RNG.normal(size=size))
    shape = (1 - np.exp(-(frequencies / low) ** 3)) * np.exp(-(frequencies / high) ** 4)
    shape /= np.maximum(frequencies, low) ** pink
    samples = np.fft.irfft(spectrum * shape, n=size)
    return samples / max(np.std(samples), 1e-9)


def write(name, samples, pan):
    edge = np.minimum(np.arange(len(samples)) / 600, (len(samples) - 1 - np.arange(len(samples))) / 900)
    samples *= np.clip(edge, 0, 1)
    samples *= min(1.0, 0.30 / max(abs(samples).max(), 1e-9))
    stereo = np.column_stack((samples * np.sqrt((1 - pan) / 2), samples * np.sqrt((1 + pan) / 2)))
    path = ROOT / "assets/audio/sfx/book" / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((np.clip(stereo, -1, 1) * 32767).astype("<i2").tobytes())
    return {"file": path.relative_to(ROOT).as_posix(), "seconds": len(samples) / RATE,
            "peak_dbfs": round(20 * np.log10(abs(stereo).max()), 2),
            "rms_dbfs": round(20 * np.log10(np.sqrt(np.mean(stereo ** 2))), 2)}


def main():
    t = np.arange(round(RATE * 1.04)) / RATE
    air = noise(len(t), 250, 6500, 0.38)
    fibers = noise(len(t), 900, 8500, 0.15)
    envelope = np.exp(-((t - 0.39) / 0.27) ** 2)
    soft_folds = sum(np.exp(-((t - center) / width) ** 2) * gain
                     for center, width, gain in [(0.13, 0.026, 0.013), (0.33, 0.038, 0.018), (0.59, 0.052, 0.012), (0.79, 0.035, 0.008)])
    page = air * envelope * 0.035 + fibers * soft_folds
    reports = [write("page_turn.wav", page, -0.12 + 0.24 * t / t[-1])]

    t = np.arange(round(RATE * 1.25)) / RATE
    rustle = noise(len(t), 180, 4500, 0.45) * np.exp(-((t - 0.46) / 0.27) ** 2) * 0.018
    contact = np.maximum(t - 1.02, 0)
    weight = (t >= 1.02) * (1 - np.exp(-contact * 1800)) * np.exp(-contact * 28)
    thud = (np.sin(contact * 2 * np.pi * 104) * 0.040 + noise(len(t), 65, 1200, 0.5) * 0.025) * weight
    reports.append(write("book_close.wav", rustle + thud, np.zeros_like(t)))
    report_path = ROOT / "art/audio/book_foley/report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps({"method": "Original filtered paper-fiber noise, soft folds and cloth contact; no sampled recordings.",
                                       "rate_hz": RATE, "channels": 2, "seed": 16102026, "assets": reports}, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(reports, indent=2))


if __name__ == "__main__":
    main()
