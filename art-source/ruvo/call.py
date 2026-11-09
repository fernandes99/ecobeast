"""Gera o som característico do Ruvo (creature-sounds/02): um "ru-vo" rápido de chip
de videogame antigo, em 0,34 s, sem imitar um bicho de verdade.

- "ru": uma nota curta de pulso, subindo um pouco.
- "vo": logo depois, só um pouco mais alta e no mesmo volume, sem acento: um vibrato
  leve, o timbre do pulso afinando (25%, 12,5%) e uma queda suave no fim.
- Um triângulo de 16 degraus, uma oitava abaixo, dá corpo às duas sílabas.
- Um estalo de brasa curto (ruído de registrador LFSR, no modo metálico) no começo do
  "vo" e uns estalinhos soltos depois lembram o fogo.

O som de chip vem de calcular tudo a 11 025 Hz e repetir cada amostra (sample-and-hold),
com o volume em poucos degraus. Tudo sai daqui: nada gravado nem tirado de outro jogo.

Uso, na raiz do repositório: python -I art-source/ruvo/call.py
Escreve client/assets/creatures/ruvo/call.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
## O "chip" calcula uma amostra a cada HOLD amostras do arquivo: 11 025 Hz.
HOLD = 4
LENGTH = 0.34
SEED = 1
PEAK = 0.7
## Quantos degraus de volume a mistura tem, como um chip de 6 bits.
LEVELS = 64

## "ru": início, fim, frequência inicial e final em Hz, largura do pulso e peso.
RU = (0.0, 0.08, 370.0, 415.3, 0.25, 0.9)
## "vo": início e fim; um arpejo antes da nota (vazio: sem arpejo, para não acentuar).
VO = (0.1, 0.34)
VO_ARPEGGIO = ()
## A nota do "vo", só um pouco acima do fim do "ru" (lá).
VO_HOLD_FREQ = 440.0
## Do lá, a nota cai até o fá sustenido a partir deste instante (em segundos, dentro do "vo").
VO_FALL_FROM = 0.08
VO_FALL_FREQ = 370.0
## O vibrato: quantas vezes por segundo, e a profundidade máxima (fração da frequência).
VIBRATO_RATE = 12.0
VIBRATO_DEPTH = 0.012
## As larguras do pulso ao longo do "vo": (a partir de quando, largura).
VO_DUTIES = ((0.0, 0.25), (0.1, 0.125))
VO_WEIGHT = 0.85
## O triângulo, uma oitava abaixo do pulso.
TRIANGLE_WEIGHT = 0.45
## O estalo de brasa: início, duração, quantas amostras do chip por passo do LFSR e peso.
EMBER = (0.1, 0.05, 3, 0.25)
## Os estalinhos soltos depois: quantos, duração de cada um e peso.
SPARKS = (3, 0.01, 0.15)
SPARKS_FROM = 0.08

OUT = Path(__file__).resolve().parents[2] / "client/assets/creatures/ruvo/call.wav"
CHIP_RATE = RATE / HOLD


def envelope(t, length, attack, release, sustain=1.0):
    """Sobe em `attack`, cai devagar até `sustain` e some nos últimos `release` segundos."""
    if t < 0.0 or t >= length:
        return 0.0
    level = min(1.0, t / attack) if attack > 0.0 else 1.0
    level *= 1.0 - (1.0 - sustain) * (t / length)
    if t > length - release:
        level *= max(0.0, (length - t) / release)
    return level


def pulse(phase, duty):
    return 1.0 if phase % 1.0 < duty else -1.0


def triangle(phase):
    """Triângulo em 16 degraus, como o canal de triângulo de um chip antigo."""
    value = 1.0 - 4.0 * abs(phase % 1.0 - 0.5)
    return round(value * 7.5) / 7.5


def vo_frequency(t):
    """A frequência do "vo" em `t` segundos depois do começo dele."""
    start = 0.0
    for freq, duration in VO_ARPEGGIO:
        if t < start + duration:
            return freq
        start += duration
    if t < VO_FALL_FROM:
        base = VO_HOLD_FREQ
    else:
        fall = min(1.0, (t - VO_FALL_FROM) / (VO[1] - VO[0] - VO_FALL_FROM))
        base = VO_HOLD_FREQ * (VO_FALL_FREQ / VO_HOLD_FREQ) ** (fall * fall)
    # O vibrato cresce do fim do arpejo em diante.
    grow = min(1.0, max(0.0, (t - start) / 0.2))
    return base * (1.0 + VIBRATO_DEPTH * grow * math.sin(2.0 * math.pi * VIBRATO_RATE * (t - start)))


def vo_duty(t):
    duty = VO_DUTIES[0][1]
    for since, width in VO_DUTIES:
        if t >= since:
            duty = width
    return duty


class Lfsr:
    """O registrador de ruído de 15 bits; no modo curto, o ruído fica metálico."""

    def __init__(self, short):
        self.state = 1
        self.tap = 6 if short else 1

    def step(self):
        bit = (self.state ^ (self.state >> self.tap)) & 1
        self.state = (self.state >> 1) | (bit << 14)
        return 1.0 if self.state & 1 else -1.0


def main():
    random_source = random.Random(SEED)
    chip_count = int(LENGTH * CHIP_RATE)
    chip = [0.0] * chip_count

    ru_phase = vo_phase = 0.0
    ru_length = RU[1] - RU[0]
    vo_length = VO[1] - VO[0]
    for index in range(chip_count):
        t = index / CHIP_RATE

        # "ru"
        local = t - RU[0]
        if 0.0 <= local < ru_length:
            progress = local / ru_length
            freq = RU[2] * (RU[3] / RU[2]) ** progress
            ru_phase += freq / CHIP_RATE
            level = envelope(local, ru_length, 0.005, 0.03, 0.8)
            chip[index] += RU[5] * level * pulse(ru_phase, RU[4])
            chip[index] += TRIANGLE_WEIGHT * level * triangle(ru_phase / 2.0)

        # "vo"
        local = t - VO[0]
        if 0.0 <= local < vo_length:
            vo_phase += vo_frequency(local) / CHIP_RATE
            level = envelope(local, vo_length, 0.008, 0.1, 0.6)
            chip[index] += VO_WEIGHT * level * pulse(vo_phase, vo_duty(local))
            chip[index] += TRIANGLE_WEIGHT * level * triangle(vo_phase / 2.0)

    # O estalo de brasa: o LFSR curto, com queda rápida.
    noise = Lfsr(short=True)
    value = noise.step()
    start = int(EMBER[0] * CHIP_RATE)
    length = int(EMBER[1] * CHIP_RATE)
    for offset in range(length):
        if offset % EMBER[2] == 0:
            value = noise.step()
        chip[start + offset] += EMBER[3] * value * (1.0 - offset / length) ** 2

    # Os estalinhos: o LFSR longo, em instantes sorteados no fim do "vo".
    noise = Lfsr(short=False)
    spark_length = int(SPARKS[1] * CHIP_RATE)
    for _ in range(SPARKS[0]):
        start = random_source.randrange(int((VO[0] + SPARKS_FROM) * CHIP_RATE), chip_count - spark_length)
        for offset in range(spark_length):
            chip[start + offset] += SPARKS[2] * noise.step() * (1.0 - offset / spark_length) ** 3

    loudest = max(abs(sample) for sample in chip) or 1.0
    chip = [round(sample / loudest * (LEVELS / 2 - 1)) / (LEVELS / 2 - 1) for sample in chip]
    samples = [sample for sample in chip for _ in range(HOLD)]
    frames = b"".join(struct.pack("<h", int(sample * PEAK * 32767)) for sample in samples)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)
    print("ok:", OUT, "%.2f s" % (len(samples) / RATE))


main()
