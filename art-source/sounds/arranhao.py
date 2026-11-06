"""Gera o som da Arranhão (board-battle/09): três rasgos rápidos, um por garra,
dentro dos 0,45 s do efeito. Cada rasgo é ruído branco passando por um filtro
passa-banda cujo centro desce do agudo para o médio, com ataque curto e queda
rápida, mais um estalo no começo. Tudo sai daqui: sem gravação de terceiros.

Uso, na raiz do repositório: python -I art-source/sounds/arranhao.py
Escreve client/assets/sounds/skills/arranhao.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
LENGTH = 0.42
SEED = 447
## Quando cada garra passa, em segundos, e a força de cada uma.
SWIPES = [(0.02, 0.85), (0.085, 1.0), (0.15, 0.8)]
SWIPE_SECONDS = 0.11
## O centro do filtro desce de um para o outro durante o rasgo, em Hz.
SWEEP_FROM = 6200.0
SWEEP_TO = 1900.0
Q = 1.4
ATTACK = 0.004
DECAY = 0.035
CLICK_SECONDS = 0.003
PEAK = 0.7

OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds/skills/arranhao.wav"


def band_pass(samples, start_freq, end_freq):
    """Biquad passa-banda (receita RBJ), com o centro mudando a cada amostra."""
    out = []
    x1 = x2 = y1 = y2 = 0.0
    count = len(samples)
    for index, x in enumerate(samples):
        t = index / max(1, count - 1)
        freq = start_freq * (end_freq / start_freq) ** t
        w = 2.0 * math.pi * freq / RATE
        alpha = math.sin(w) / (2.0 * Q)
        b0, b2 = alpha, -alpha
        a0, a1, a2 = 1.0 + alpha, -2.0 * math.cos(w), 1.0 - alpha
        y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, x
        y2, y1 = y1, y
        out.append(y)
    return out


def swipe(random_source):
    count = int(SWIPE_SECONDS * RATE)
    noise = [random_source.uniform(-1.0, 1.0) for _ in range(count)]
    body = band_pass(noise, SWEEP_FROM, SWEEP_TO)
    out = []
    for index, value in enumerate(body):
        t = index / RATE
        envelope = min(1.0, t / ATTACK) * math.exp(-max(0.0, t - ATTACK) / DECAY)
        click = noise[index] * (1.0 - t / CLICK_SECONDS) * 0.6 if t < CLICK_SECONDS else 0.0
        out.append(value * envelope + click)
    return out


def main():
    random_source = random.Random(SEED)
    mix = [0.0] * int(LENGTH * RATE)
    for start, strength in SWIPES:
        first = int(start * RATE)
        for index, value in enumerate(swipe(random_source)):
            if first + index < len(mix):
                mix[first + index] += value * strength
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
