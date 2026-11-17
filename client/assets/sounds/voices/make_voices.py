"""As vozes da caixa de fala (.specs/dialogue-voices/02-voice-blips.md).

Cada voz é um bipe curto de chip de videogame antigo, tocado enquanto o texto
aparece. O timbre mora aqui; o ritmo (letras por segundo, letras por bipe e
quanto a altura varia) mora no catálogo, na tabela `voices`.

    python client/assets/sounds/voices/make_voices.py

Gera, ao lado deste arquivo, um `<slug>.wav` por voz de VOICES: mono,
22.050 Hz, 16 bits, com um ataque de 4 ms e um decaimento exponencial até o
fim. Para mudar um timbre, mude a linha dele em VOICES e rode de novo. Só usa
a biblioteca padrão do Python, e rodar de novo dá os mesmos arquivos.
"""

from __future__ import annotations

import math
import os
import wave
from array import array
from dataclasses import dataclass

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
ATTACK_SECONDS = 0.004
# Quanto o decaimento cai até o fim do bipe: e^-5, perto de 0,7%.
DECAY = 5.0


@dataclass(frozen=True)
class Voice:
    slug: str
    # square, pulse25, triangle ou sine
    wave: str
    hz: float
    ms: int
    volume: float
    # A frequência no fim, para a voz que sobe (o Pio); 0 fica na mesma.
    end_hz: float = 0.0


VOICES = [
    Voice("narration", "triangle", 330, 50, 0.55),
    Voice("tamer", "square", 440, 35, 0.30),
    Voice("low", "square", 170, 55, 0.34),
    Voice("medium", "square", 390, 40, 0.30),
    Voice("high", "pulse25", 760, 30, 0.30),
    Voice("chirp", "sine", 900, 70, 0.55, end_hz=1440),
]


def _shape(kind: str, phase: float) -> float:
    if kind == "square":
        return 1.0 if phase < 0.5 else -1.0
    if kind == "pulse25":
        return 1.0 if phase < 0.25 else -1.0
    if kind == "triangle":
        return 4.0 * phase - 1.0 if phase < 0.5 else 3.0 - 4.0 * phase
    return math.sin(2.0 * math.pi * phase)


def render(voice: Voice) -> array:
    count = round(RATE * voice.ms / 1000)
    attack = round(RATE * ATTACK_SECONDS)
    samples = array("h")
    phase = 0.0
    for i in range(count):
        t = i / count
        hz = voice.hz + (voice.end_hz - voice.hz) * t if voice.end_hz else voice.hz
        envelope = math.exp(-DECAY * t)
        if i < attack:
            envelope *= i / attack
        value = _shape(voice.wave, phase) * envelope * voice.volume
        samples.append(round(value * 32767))
        phase = (phase + hz / RATE) % 1.0
    return samples


def write(voice: Voice) -> None:
    path = os.path.join(HERE, f"{voice.slug}.wav")
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(render(voice).tobytes())


if __name__ == "__main__":
    for voice in VOICES:
        write(voice)
        print(f"{voice.slug}.wav")
