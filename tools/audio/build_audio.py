"""Synthesises the story and combat sound effects with the standard library only.

Writes mono 16-bit 22.05 kHz WAV files to assets/audio. Each sound is a few oscillators, noise and
an envelope; nothing is sampled from outside the repository.
"""

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "audio"
RATE = 22050


def seconds(count):
    return int(RATE * count)


def tone(freq, length, decay=4.0, volume=1.0, start=0.0, sweep=0.0):
    """A sine with an exponential tail; `sweep` bends the pitch (Hz per second)."""
    out = []
    phase = 0.0
    for i in range(seconds(length)):
        t = i / RATE
        f = freq + sweep * t
        phase += 2 * math.pi * f / RATE
        attack = min(1.0, t / 0.004)
        out.append(math.sin(phase) * math.exp(-decay * t) * volume * attack)
    return [0.0] * seconds(start) + out


def noise(length, decay=6.0, volume=1.0, smooth=0.0, seed=1):
    rng = random.Random(seed)
    out = []
    last = 0.0
    for i in range(seconds(length)):
        t = i / RATE
        value = rng.uniform(-1, 1)
        last = last * smooth + value * (1 - smooth)
        out.append(last * math.exp(-decay * t) * volume)
    return out


def mix(*tracks):
    size = max(len(t) for t in tracks)
    out = [0.0] * size
    for track in tracks:
        for i, v in enumerate(track):
            out[i] += v
    return out


def bell(freq, length=2.4, volume=0.5, start=0.0):
    partials = [
        (1.0, 1.0, 1.6),
        (2.0, 0.6, 2.2),
        (2.76, 0.45, 2.8),
        (4.07, 0.25, 3.6),
        (5.4, 0.15, 4.4),
    ]
    return mix(*[tone(freq * r, length, d, volume * a, start) for r, a, d in partials])


def save(name, samples, gain=0.85):
    peak = max(1e-6, max(abs(v) for v in samples))
    scale = gain / peak if peak > gain else 1.0
    path = OUTPUT / (name + ".wav")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(
            b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32000)) for v in samples)
        )
    print("wrote", path.name, len(samples) / RATE)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    save("bell", mix(bell(196.0), bell(98.0, 2.6, 0.3)))
    save("chime", mix(bell(880.0, 1.1, 0.5), bell(1320.0, 0.9, 0.3, 0.12)))
    lantern = mix(
        tone(420.0, 0.9, 3.0, 0.5, sweep=520.0),
        noise(0.9, 4.0, 0.12, smooth=0.9, seed=3),
        tone(1180.0, 0.6, 5.0, 0.25, 0.25),
    )
    save("lantern", lantern)
    water = noise(1.4, 0.6, 0.55, smooth=0.86, seed=5)
    water = [v * (0.7 + 0.3 * math.sin(i / RATE * 9.0)) for i, v in enumerate(water)]
    save("water", water)
    crowd = noise(1.6, 1.4, 0.45, smooth=0.72, seed=9)
    crowd = [v * (0.6 + 0.4 * abs(math.sin(i / RATE * 11.0))) for i, v in enumerate(crowd)]
    save("cheer", mix(crowd, tone(660.0, 0.5, 3.0, 0.2, 0.1, 240.0)))
    notes = [523.25, 659.25, 783.99, 1046.5]
    save("wedding", mix(*[bell(f, 1.5, 0.35, 0.28 * i) for i, f in enumerate(notes)]))
    save("hit", mix(noise(0.16, 28.0, 0.9, smooth=0.3, seed=11), tone(120.0, 0.2, 18.0, 0.8)))
    save("rumble", mix(noise(1.3, 1.8, 0.5, smooth=0.95, seed=13), tone(48.0, 1.3, 1.6, 0.7)))
    save("tick", mix(tone(1900.0, 0.05, 60.0, 0.7), tone(1300.0, 0.05, 60.0, 0.5, 0.24)))
    save("swing", noise(0.16, 14.0, 0.5, smooth=0.55, seed=17))
    save("hurt", mix(tone(320.0, 0.28, 8.0, 0.7, sweep=-700.0), noise(0.1, 30.0, 0.4, seed=19)))
    save(
        "defeat",
        mix(
            *[
                tone(f, 0.32, 7.0, 0.45, 0.07 * i)
                for i, f in enumerate([660.0, 520.0, 400.0, 300.0])
            ]
        ),
    )


if __name__ == "__main__":
    main()
