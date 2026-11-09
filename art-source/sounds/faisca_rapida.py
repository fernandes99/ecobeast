"""Gera o som da Faísca Rápida (board-battle/15): o lançamento de uma faísca que
cruza o tabuleiro, em 0,35 s. Um estalo de ignição no começo, depois um chiado
agudo (ruído num passa-banda que sobe um pouco, como algo ganhando velocidade)
com crepitar (estalinhos soltos em instantes sorteados), que dura o voo e some.
O impacto não está aqui: na luta, o som de dano toca quando a faísca chega, a
qualquer distância. Tudo sai daqui: sem gravação de terceiros.

Uso, na raiz do repositório: python -I art-source/sounds/faisca_rapida.py
Escreve client/assets/sounds/skills/faisca_rapida.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
LENGTH = 0.35
SEED = 579
## O estalo de ignição: duração, centro do filtro em Hz, Q e peso.
IGNITION = (0.02, 1800.0, 0.9, 1.0)
## O chiado: o centro do filtro sobe de um para o outro, em Hz, com Q e peso.
HISS_SWEEP = (3200.0, 5200.0)
HISS_Q = 2.2
HISS_WEIGHT = 0.28
HISS_ATTACK = 0.03
## O voo mais longo (3 hexágonos a 0,09 s) termina aos 0,27 s: o chiado some depois.
HISS_RELEASE_FROM = 0.2
## O crepitar: quantos estalinhos por segundo, quanto dura cada um e o peso.
CRACKLES_PER_SECOND = 55.0
CRACKLE_SECONDS = 0.004
CRACKLE_WEIGHT = 0.45
PEAK = 0.7

OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds/skills/faisca_rapida.wav"


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


def hiss_envelope(t):
    rise = min(1.0, t / HISS_ATTACK)
    if t < HISS_RELEASE_FROM:
        return rise
    return rise * max(0.0, 1.0 - (t - HISS_RELEASE_FROM) / (LENGTH - HISS_RELEASE_FROM)) ** 1.5


def main():
    random_source = random.Random(SEED)
    count = int(LENGTH * RATE)
    mix = [0.0] * count

    # O estalo: um sopro curto de ruído, com queda rápida.
    ignition_count = int(IGNITION[0] * RATE)
    noise = [random_source.uniform(-1.0, 1.0) for _ in range(ignition_count)]
    for index, value in enumerate(band_pass(noise, IGNITION[1], IGNITION[1], IGNITION[2])):
        t = index / ignition_count
        mix[index] += value * IGNITION[3] * 4.0 * (1.0 - t) ** 3

    # O chiado.
    noise = [random_source.uniform(-1.0, 1.0) for _ in range(count)]
    for index, value in enumerate(band_pass(noise, HISS_SWEEP[0], HISS_SWEEP[1], HISS_Q)):
        mix[index] += value * HISS_WEIGHT * 4.0 * hiss_envelope(index / RATE)

    # O crepitar: estalinhos de ruído em instantes sorteados, seguindo o volume do chiado.
    crackle_count = int(CRACKLE_SECONDS * RATE)
    for _ in range(int(CRACKLES_PER_SECOND * LENGTH)):
        start = random_source.randrange(0, count - crackle_count)
        strength = random_source.uniform(0.4, 1.0) * hiss_envelope(start / RATE)
        for index in range(crackle_count):
            decay = (1.0 - index / crackle_count) ** 2
            mix[start + index] += random_source.uniform(-1.0, 1.0) * CRACKLE_WEIGHT * strength * decay

    mix = [math.tanh(value * 1.4) for value in mix]
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
