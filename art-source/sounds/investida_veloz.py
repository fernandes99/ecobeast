"""Gera o som da Investida Veloz (board-battle/14): um avanço rápido que termina num
baque, dentro dos 0,45 s do efeito. Primeiro, um zunido de vento: ruído passando
por um passa-banda cujo centro sobe do médio para o agudo, com o volume crescendo.
Depois, no quadro em que o risco do efeito está maior, o baque: um grave que cai
de altura e some rápido, com um estalo curto por cima. Tudo sai daqui: sem
gravação de terceiros.

Uso, na raiz do repositório: python -I art-source/sounds/investida_veloz.py
Escreve client/assets/sounds/skills/investida_veloz.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
LENGTH = 0.42
SEED = 333
## O zunido: quando começa e termina, em segundos, e o centro do filtro, em Hz.
WHOOSH_FROM = 0.0
WHOOSH_TO = 0.17
WHOOSH_SWEEP = (700.0, 4200.0)
WHOOSH_Q = 1.1
WHOOSH_WEIGHT = 0.55
## O baque: quando acontece, a altura do grave caindo, em Hz, e quanto ele dura.
HIT_AT = 0.16
THUMP_SWEEP = (150.0, 52.0)
THUMP_DECAY = 0.07
THUMP_WEIGHT = 1.0
## O estalo por cima do baque: centro do filtro, Q, duração e peso.
CRACK = (2600.0, 1.5, 0.025, 0.7)
PEAK = 0.75

OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds/skills/investida_veloz.wav"


def band_pass(samples, start_freq, end_freq, q):
    """Biquad passa-banda (receita RBJ), com o centro indo de um valor ao outro."""
    out = []
    x1 = x2 = y1 = y2 = 0.0
    count = len(samples)
    for index, x in enumerate(samples):
        t = index / max(1, count - 1)
        freq = start_freq * (end_freq / start_freq) ** t
        w = 2.0 * math.pi * freq / RATE
        alpha = math.sin(w) / (2.0 * q)
        b0, b2 = alpha, -alpha
        a0, a1, a2 = 1.0 + alpha, -2.0 * math.cos(w), 1.0 - alpha
        y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, x
        y2, y1 = y1, y
        out.append(y)
    return out


def main():
    random_source = random.Random(SEED)
    count = int(LENGTH * RATE)
    mix = [0.0] * count

    # O zunido cresce até o baque e corta logo depois dele.
    start, end = int(WHOOSH_FROM * RATE), int(WHOOSH_TO * RATE)
    noise = [random_source.uniform(-1.0, 1.0) for _ in range(end - start)]
    whoosh = band_pass(noise, WHOOSH_SWEEP[0], WHOOSH_SWEEP[1], WHOOSH_Q)
    for index, value in enumerate(whoosh):
        t = index / max(1, len(whoosh) - 1)
        mix[start + index] += value * WHOOSH_WEIGHT * 4.0 * t ** 1.8 * (1.0 - t ** 12)

    # O baque: um seno cuja altura cai, com queda exponencial do volume.
    hit = int(HIT_AT * RATE)
    phase = 0.0
    for index in range(count - hit):
        t = index / RATE
        freq = THUMP_SWEEP[1] + (THUMP_SWEEP[0] - THUMP_SWEEP[1]) * math.exp(-t / 0.03)
        phase += freq / RATE
        attack = min(1.0, t / 0.002)
        mix[hit + index] += math.sin(2.0 * math.pi * phase) * THUMP_WEIGHT * attack * math.exp(-t / THUMP_DECAY)

    # O estalo: um sopro curto de ruído agudo no instante do baque.
    crack_count = int(CRACK[2] * RATE)
    crack = band_pass([random_source.uniform(-1.0, 1.0) for _ in range(crack_count)], CRACK[0], CRACK[0], CRACK[1])
    for index, value in enumerate(crack):
        t = index / crack_count
        mix[hit + index] += value * CRACK[3] * 4.0 * (1.0 - t) ** 2

    mix = [math.tanh(value * 1.6) for value in mix]
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
