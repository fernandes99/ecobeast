"""O som da máquina de cura do Refúgio (.specs/interiors/04-refuge-hospital.md).

Um arpejo curto e subindo de chip de videogame antigo, com um brilho no fim.

    python client/assets/sounds/refuge/make_heal_sound.py

Gera `heal.wav` ao lado deste arquivo: mono, 22.050 Hz, 16 bits. Só usa a
biblioteca padrão do Python, e rodar de novo dá o mesmo arquivo.
"""

from __future__ import annotations

import math
import os
import wave
from array import array

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
VOLUME = 0.32
ATTACK_SECONDS = 0.004
# Dó, mi, sol e dó da oitava de cima, e o brilho em mi e sol mais altos.
NOTES = [(523.25, 0.085), (659.25, 0.085), (783.99, 0.085), (1046.5, 0.16)]
SHIMMER = [(1318.5, 0.07), (1568.0, 0.07)] * 3
SHIMMER_VOLUME = 0.45


def pulse(phase: float, duty: float) -> float:
    return 1.0 if phase % 1.0 < duty else -1.0


def note(hz: float, seconds: float, volume: float, duty: float, decay: float) -> list[float]:
    count = int(RATE * seconds)
    samples = []
    for index in range(count):
        time = index / RATE
        envelope = min(1.0, time / ATTACK_SECONDS) * math.exp(-decay * index / count)
        samples.append(pulse(hz * time, duty) * envelope * volume)
    return samples


def build() -> array:
    samples: list[float] = []
    for hz, seconds in NOTES:
        samples += note(hz, seconds, VOLUME, 0.5, 2.0)
    for index, (hz, seconds) in enumerate(SHIMMER):
        fade = 1.0 - index / len(SHIMMER)
        samples += note(hz, seconds, VOLUME * SHIMMER_VOLUME * fade, 0.25, 3.0)
    return array("h", (int(max(-1.0, min(1.0, value)) * 32767) for value in samples))


def main() -> None:
    path = os.path.join(HERE, "heal.wav")
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(build().tobytes())
    print(f"Gravei {path}")


if __name__ == "__main__":
    main()
