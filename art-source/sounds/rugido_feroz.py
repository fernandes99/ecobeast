"""Gera o som da Rugido Feroz (board-battle/11): um rugido curto de 0,6 s. A base é
um grave em dente de serra cuja altura sobe e desce, com uma vibração lenta no
volume que deixa o som áspero. Dois filtros passa-banda dão a cor de garganta, um
ruído rouco vai por cima, e uma saturação leve junta tudo. Tudo sai daqui: sem
gravação de terceiros.

Uso, na raiz do repositório: python -I art-source/sounds/rugido_feroz.py
Escreve client/assets/sounds/skills/rugido_feroz.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
LENGTH = 0.6
SEED = 398
## A altura do grave, em Hz, nos instantes dados em segundos: sobe e desce.
PITCH = [(0.0, 82.0), (0.14, 128.0), (0.36, 104.0), (0.6, 66.0)]
## Quanto a altura treme, para não soar como uma máquina.
JITTER = 0.04
## A vibração do volume (aspereza), em Hz, e quanto ela pesa.
RASP_HZ = 31.0
RASP_DEPTH = 0.45
## As duas faixas que dão a cor de garganta: centro em Hz, Q e peso.
FORMANTS = [(480.0, 2.0, 1.0), (1150.0, 3.0, 0.55)]
DRY = 0.35
## O ruído rouco: faixa em Hz, Q e peso.
BREATH = (1100.0, 1.2, 0.45)
ATTACK = 0.045
RELEASE_FROM = 0.34
DRIVE = 2.2
PEAK = 0.75

OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds/skills/rugido_feroz.wav"


def band_pass(samples, freq, q):
    """Biquad passa-banda (receita RBJ), com o centro fixo."""
    w = 2.0 * math.pi * freq / RATE
    alpha = math.sin(w) / (2.0 * q)
    b0, b2 = alpha, -alpha
    a0, a1, a2 = 1.0 + alpha, -2.0 * math.cos(w), 1.0 - alpha
    out = []
    x1 = x2 = y1 = y2 = 0.0
    for x in samples:
        y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, x
        y2, y1 = y1, y
        out.append(y)
    return out


def pitch_at(t):
    for (t0, f0), (t1, f1) in zip(PITCH, PITCH[1:]):
        if t <= t1:
            return f0 + (f1 - f0) * (t - t0) / (t1 - t0)
    return PITCH[-1][1]


def envelope(t):
    rise = min(1.0, t / ATTACK)
    if t < RELEASE_FROM:
        return rise
    return rise * max(0.0, 1.0 - (t - RELEASE_FROM) / (LENGTH - RELEASE_FROM)) ** 1.6


def main():
    random_source = random.Random(SEED)
    count = int(LENGTH * RATE)
    voice = []
    phase = 0.0
    wobble = 0.0
    for index in range(count):
        t = index / RATE
        # O tremor da altura muda devagar: um passeio aleatório puxado de volta a zero.
        wobble = wobble * 0.999 + random_source.uniform(-1.0, 1.0) * 0.002
        phase = (phase + pitch_at(t) * (1.0 + JITTER * wobble * 20.0) / RATE) % 1.0
        saw = 2.0 * phase - 1.0
        rasp = 1.0 - RASP_DEPTH * (0.5 + 0.5 * math.sin(2.0 * math.pi * RASP_HZ * t))
        voice.append(saw * rasp)
    mix = [value * DRY for value in voice]
    for freq, q, weight in FORMANTS:
        for index, value in enumerate(band_pass(voice, freq, q)):
            mix[index] += value * weight * 3.0
    noise = band_pass([random_source.uniform(-1.0, 1.0) for _ in range(count)], BREATH[0], BREATH[1])
    for index in range(count):
        t = index / RATE
        mix[index] = math.tanh((mix[index] + noise[index] * BREATH[2] * 2.0) * DRIVE) * envelope(t)
    loudest = max(abs(value) for value in mix) or 1.0
    frames = b"".join(struct.pack("<h", int(value / loudest * PEAK * 32767)) for value in mix)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)
    print("ok:", OUT, "%.2f s" % LENGTH)


main()
