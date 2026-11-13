"""Gera o som das 22 Técnicas da board-battle/18 (board-battle/19), por síntese:
ruído em filtros, tons com a altura mudando e saturação leve. Cada som dura mais
ou menos o efeito da Técnica, porque os dois começam juntos; o impacto fica com o
som de dano. Tudo sai daqui: sem gravação de terceiros.

Uso, na raiz do repositório: python -I art-source/sounds/element_skills.py [slugs]
Escreve client/assets/sounds/skills/<slug>.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import sys
import wave
import zlib
from pathlib import Path

RATE = 44100
PEAK = 0.7
## A cada quantas amostras o filtro recalcula o centro, quando ele muda.
FILTER_STEP = 16
OUT_DIR = Path(__file__).resolve().parents[2] / "client/assets/sounds/skills"

C5, E5, G5, C6 = 523.25, 659.26, 783.99, 1046.5
G4, B4, D5, G5_ = 392.0, 493.88, 587.33, 783.99
PENTATONIC = [1046.5, 1174.7, 1318.5, 1568.0, 1760.0, 2093.0, 2349.3, 2637.0]


# --- peças -----------------------------------------------------------------


def count_of(seconds):
    return int(seconds * RATE)


def curve(points, t):
    """Valor em t de uma linha por pontos (tempo, valor); um número vale para todo t."""
    if not isinstance(points, (list, tuple)):
        return points
    if t <= points[0][0]:
        return points[0][1]
    for (t0, v0), (t1, v1) in zip(points, points[1:]):
        if t <= t1:
            return v0 + (v1 - v0) * (t - t0) / (t1 - t0)
    return points[-1][1]


def noise(rng, seconds):
    return [rng.uniform(-1.0, 1.0) for _ in range(count_of(seconds))]


def _biquad(samples, freq, q, kind):
    out = []
    x1 = x2 = y1 = y2 = 0.0
    b0 = b1 = b2 = a1 = a2 = 0.0
    for index, x in enumerate(samples):
        if index % FILTER_STEP == 0:
            f = min(curve(freq, index / RATE), RATE * 0.45)
            w = 2.0 * math.pi * f / RATE
            alpha = math.sin(w) / (2.0 * q)
            cos_w = math.cos(w)
            a0 = 1.0 + alpha
            if kind == "band":
                b0, b1, b2 = alpha / a0, 0.0, -alpha / a0
            elif kind == "low":
                b0 = b2 = (1.0 - cos_w) / 2.0 / a0
                b1 = (1.0 - cos_w) / a0
            else:
                b0 = b2 = (1.0 + cos_w) / 2.0 / a0
                b1 = -(1.0 + cos_w) / a0
            a1, a2 = -2.0 * cos_w / a0, (1.0 - alpha) / a0
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, x
        y2, y1 = y1, y
        out.append(y)
    return out


def band(samples, freq, q=1.0):
    """Passa-banda (receita RBJ, pico de 0 dB); o centro pode ser uma linha por pontos."""
    return _biquad(samples, freq, q, "band")


def low(samples, freq, q=0.707):
    return _biquad(samples, freq, q, "low")


def high(samples, freq, q=0.707):
    return _biquad(samples, freq, q, "high")


def tone(seconds, freq, harmonics=(1.0,), vibrato=(0.0, 0.0)):
    """Soma de harmônicos com a altura numa linha por pontos e um vibrato (Hz, fração)."""
    out = []
    phase = 0.0
    for index in range(count_of(seconds)):
        t = index / RATE
        f = curve(freq, t) * (1.0 + vibrato[1] * math.sin(2.0 * math.pi * vibrato[0] * t))
        phase += f / RATE
        out.append(sum(weight * math.sin(2.0 * math.pi * phase * (k + 1)) for k, weight in enumerate(harmonics)))
    return out


def shape(samples, points):
    """Multiplica pelo envelope de uma linha por pontos (tempo, volume)."""
    return [value * curve(points, index / RATE) for index, value in enumerate(samples)]


def decay(samples, seconds, attack=0.003):
    """Envelope de batida: sobe em `attack` e cai pela metade a cada `seconds` / 4."""
    out = []
    for index, value in enumerate(samples):
        t = index / RATE
        rise = min(1.0, t / attack) if attack > 0 else 1.0
        out.append(value * rise * math.exp(-t * 2.8 / seconds))
    return out


def flutter(rng, samples, speed, depth):
    """Volume que treme ao acaso (um ruído lento), para água e fogo não soarem parados."""
    out = []
    level = 0.0
    pull = speed / RATE
    for value in samples:
        level += (rng.uniform(-1.0, 1.0) - level) * pull
        out.append(value * (1.0 - depth + depth * (0.5 + 1.6 * level)))
    return out


def ping(freq, seconds, partials=((1.0, 1.0), (2.0, 0.3))):
    """Uma batida de sino ou cristal: parciais (múltiplo, peso) que somem juntas."""
    out = []
    for index in range(count_of(seconds)):
        t = index / RATE
        out.append(sum(weight * math.sin(2.0 * math.pi * freq * mult * t) for mult, weight in partials))
    return decay(out, seconds, 0.004)


def bubble(f0, seconds):
    """Uma bolha: um tom curto que sobe de altura e some."""
    return decay(tone(seconds, [(0.0, f0), (seconds, f0 * 1.9)]), seconds, 0.002)


def thud(f0, f1, seconds):
    """Um baque grave: um tom que desce e some."""
    return decay(tone(seconds, [(0.0, f0), (seconds, f1)], (1.0, 0.25)), seconds, 0.002)


def click(rng, freq, seconds, q=1.2):
    return decay(band(noise(rng, seconds), freq, q), seconds, 0.001)


def crackles(rng, length, per_second, start=0.0, end=None, weight=1.0, freq=3500.0):
    """Estalinhos de brasa em instantes sorteados."""
    end = length if end is None else end
    mix = [0.0] * count_of(length)
    for _ in range(int(per_second * (end - start))):
        at = rng.uniform(start, end - 0.01)
        add(mix, click(rng, rng.uniform(freq * 0.6, freq * 1.4), 0.006, 0.9), at, weight * rng.uniform(0.3, 1.0))
    return mix


def add(mix, layer, at=0.0, weight=1.0):
    start = count_of(at)
    for index, value in enumerate(layer):
        if start + index >= len(mix):
            break
        mix[start + index] += value * weight
    return mix


def silence(length):
    return [0.0] * count_of(length)


# --- os sons ---------------------------------------------------------------


def mordida_brasa(rng):
    """Mordida de lobo: um rosnado áspero que sobe, o estalo dos dentes se fechando com
    um baque, o rosnado que volta mais baixo e a brasa chiando."""
    length = 0.65
    mix = silence(length)
    growl = growl_voice(rng, 0.26, [(0.0, 95.0), (0.18, 150.0), (0.26, 175.0)])
    add(mix, shape(growl, [(0.0, 0.0), (0.04, 0.7), (0.2, 1.0), (0.26, 0.2)]), 0.0, 0.7)
    add(mix, click(rng, 3200.0, 0.02, 1.5), 0.22, 1.8)
    add(mix, click(rng, 4600.0, 0.015, 1.5), 0.236, 1.2)
    add(mix, thud(170.0, 50.0, 0.15), 0.22, 1.4)
    add(mix, decay(band(noise(rng, 0.09), 1800.0, 0.9), 0.08, 0.001), 0.22, 0.9)
    snarl = growl_voice(rng, 0.3, [(0.0, 130.0), (0.3, 80.0)])
    add(mix, shape(snarl, [(0.0, 0.0), (0.05, 0.6), (0.3, 0.0)]), 0.3, 0.7)
    sizzle = shape(band(noise(rng, 0.38), 4500.0, 1.5), [(0.0, 0.0), (0.03, 1.0), (0.38, 0.0)])
    add(mix, flutter(rng, sizzle, 40.0, 0.6), 0.25, 0.45)
    add(mix, crackles(rng, length, 50.0, 0.25, 0.6), 0.0, 0.7)
    return mix, 2.4


def growl_voice(rng, seconds, pitch):
    """Rosnado: dente de serra com a altura tremendo, volume vibrando (aspereza) e duas
    faixas de garganta, com um ruído rouco por cima."""
    voice = []
    phase = 0.0
    wobble = 0.0
    for index in range(count_of(seconds)):
        t = index / RATE
        wobble = wobble * 0.999 + rng.uniform(-1.0, 1.0) * 0.002
        phase = (phase + curve(pitch, t) * (1.0 + wobble) / RATE) % 1.0
        rasp = 1.0 - 0.55 * (0.5 + 0.5 * math.sin(2.0 * math.pi * 38.0 * t))
        voice.append((2.0 * phase - 1.0) * rasp)
    out = [value * 0.35 for value in voice]
    for freq, q, weight in ((500.0, 2.0, 3.0), (1300.0, 3.0, 1.6)):
        for index, value in enumerate(band(voice, freq, q)):
            out[index] += value * weight
    for index, value in enumerate(band(noise(rng, seconds), 1200.0, 1.2)):
        out[index] += value * 0.9
    return out


def fumaca_densa(rng):
    length = 0.6
    puff = low(noise(rng, length), [(0.0, 400.0), (0.2, 1400.0), (0.6, 500.0)], 0.9)
    mix = shape(puff, [(0.0, 0.0), (0.12, 1.0), (0.35, 0.7), (0.6, 0.0)])
    add(mix, shape(band(noise(rng, length), 900.0, 0.8), [(0.0, 0.0), (0.15, 0.6), (0.6, 0.0)]), 0.0, 0.5)
    return mix, 1.3


def presa_ignea(rng):
    length = 0.7
    mix = silence(length)
    add(mix, shape(band(noise(rng, 0.11), [(0.0, 1200.0), (0.11, 3000.0)], 1.4), [(0.0, 0.0), (0.1, 1.0), (0.11, 0.0)]), 0.0, 0.5)
    add(mix, thud(190.0, 50.0, 0.14), 0.12, 1.1)
    add(mix, click(rng, 3600.0, 0.025), 0.12, 1.5)
    add(mix, ping(1900.0, 0.09, ((1.0, 1.0), (1.39, 0.7))), 0.12, 0.25)
    roar = band(noise(rng, 0.56), 650.0, 0.9)
    roar = [a + b for a, b in zip(roar, low(noise(rng, 0.56), 900.0))]
    roar = shape(roar, [(0.0, 0.0), (0.1, 1.0), (0.3, 0.7), (0.56, 0.0)])
    add(mix, flutter(rng, roar, 25.0, 0.5), 0.14, 0.9)
    add(mix, crackles(rng, length, 60.0, 0.15, 0.6), 0.0, 0.8)
    return mix, 1.8


def chama_espiral(rng):
    length = 0.4
    mix = silence(length)
    add(mix, thud(120.0, 70.0, 0.07), 0.0, 0.6)
    whoosh = shape(band(noise(rng, length), [(0.0, 500.0), (0.3, 2600.0)], 1.2), [(0.0, 0.0), (0.04, 1.0), (0.25, 0.8), (0.4, 0.0)])
    add(mix, whoosh, 0.0, 1.0)
    roar = low(noise(rng, length), 700.0)
    roar = [value * (0.7 + 0.3 * math.sin(2.0 * math.pi * 18.0 * index / RATE)) for index, value in enumerate(roar)]
    add(mix, shape(roar, [(0.0, 0.0), (0.05, 1.0), (0.28, 0.7), (0.4, 0.0)]), 0.0, 0.7)
    add(mix, crackles(rng, length, 50.0, 0.02, 0.34), 0.0, 0.6)
    return mix, 1.6


def couraca_de_cinzas(rng):
    length = 0.9
    mix = silence(length)
    rise = [(0.0, 220.0), (0.6, 440.0)]
    for detune in (1.0, 1.006, 1.5):
        layer = tone(length, [(t, f * detune) for t, f in rise], (1.0, 0.35, 0.12), (12.0, 0.004))
        add(mix, shape(layer, [(0.0, 0.0), (0.1, 0.5), (0.6, 0.8), (0.75, 0.3), (0.9, 0.0)]), 0.0, 0.35)
    add(mix, crackles(rng, length, 30.0, 0.05, 0.7, freq=3000.0), 0.0, 0.5)
    add(mix, ping(1760.0, 0.28, ((1.0, 1.0), (1.5, 0.5), (2.76, 0.2))), 0.62, 0.7)
    return mix, 1.2


def erupcao_solar(rng):
    length = 0.65
    mix = silence(length)
    add(mix, decay(tone(0.45, [(0.0, 90.0), (0.45, 35.0)], (1.0, 0.3)), 0.4, 0.002), 0.0, 1.2)
    add(mix, decay(low(noise(rng, 0.2), 320.0), 0.18), 0.0, 1.4)
    rumble = shape(low(noise(rng, length), [(0.0, 180.0), (0.65, 110.0)], 1.2), [(0.0, 0.0), (0.03, 1.0), (0.5, 0.5), (0.65, 0.0)])
    add(mix, rumble, 0.0, 1.6)
    sizzle = shape(band(noise(rng, 0.6), 3000.0, 1.2), [(0.0, 0.0), (0.04, 1.0), (0.6, 0.0)])
    add(mix, flutter(rng, sizzle, 40.0, 0.6), 0.05, 0.35)
    add(mix, crackles(rng, length, 85.0, 0.05, 0.6, freq=2800.0), 0.0, 1.0)
    return mix, 2.0


def jato_de_mare(rng):
    length = 0.65
    mix = silence(length)
    jet = band(noise(rng, 0.5), [(0.0, 2200.0), (0.4, 3400.0)], 0.9)
    jet = shape(jet, [(0.0, 0.0), (0.02, 1.0), (0.38, 0.8), (0.5, 0.0)])
    add(mix, flutter(rng, jet, 30.0, 0.5), 0.0, 1.0)
    add(mix, decay(band(noise(rng, 0.22), 1500.0, 0.7), 0.2, 0.004), 0.42, 0.9)
    for _ in range(5):
        add(mix, bubble(rng.uniform(1500.0, 2600.0), 0.035), rng.uniform(0.44, 0.6), 0.25)
    return mix, 1.3


def espuma_densa(rng):
    length = 0.6
    mix = silence(length)
    for _ in range(22):
        add(mix, bubble(rng.uniform(500.0, 1400.0), rng.uniform(0.03, 0.06)), rng.uniform(0.0, 0.5), rng.uniform(0.4, 0.9))
    add(mix, shape(band(noise(rng, length), 5000.0, 1.0), [(0.0, 0.0), (0.1, 1.0), (0.6, 0.0)]), 0.0, 0.15)
    return mix, 1.1


def garra_de_mare(rng):
    length = 0.65
    mix = silence(length)
    for at in (0.04, 0.18, 0.32):
        swipe = band(noise(rng, 0.12), [(0.0, 3000.0), (0.12, 900.0)], 2.0)
        add(mix, decay(swipe, 0.12, 0.004), at, 1.0)
        for _ in range(2):
            add(mix, bubble(rng.uniform(1200.0, 2400.0), 0.035), at + rng.uniform(0.05, 0.12), 0.3)
    return mix, 2.5


def casca_fechada(rng):
    length = 0.65
    mix = silence(length)
    rise = low(tone(0.38, [(0.0, 300.0), (0.35, 700.0)], (1.0, 0.4, 0.15)), 1200.0)
    add(mix, shape(rise, [(0.0, 0.0), (0.3, 0.6), (0.38, 0.0)]), 0.0, 0.7)
    add(mix, decay(band(noise(rng, 0.2), 260.0, 8.0), 0.18, 0.002), 0.38, 3.0)
    add(mix, thud(110.0, 70.0, 0.16), 0.38, 1.0)
    add(mix, click(rng, 600.0, 0.03, 4.0), 0.38, 0.8)
    add(mix, ping(520.0, 0.25, ((1.0, 1.0), (2.0, 0.2))), 0.4, 0.25)
    return mix, 1.3


def lamina_d_agua(rng):
    length = 0.6
    mix = silence(length)
    swish = band(noise(rng, 0.22), [(0.0, 6000.0), (0.22, 1200.0)], 3.0)
    add(mix, shape(swish, [(0.0, 0.0), (0.06, 1.0), (0.22, 0.0)]), 0.0, 1.3)
    add(mix, decay(tone(0.12, [(0.0, 2400.0), (0.12, 1600.0)]), 0.1, 0.01), 0.02, 0.15)
    add(mix, decay(band(noise(rng, 0.35), 1800.0, 0.8), 0.3, 0.004), 0.2, 0.8)
    for _ in range(4):
        add(mix, bubble(rng.uniform(1300.0, 2500.0), 0.035), rng.uniform(0.24, 0.5), 0.25)
    return mix, 1.4


def mare_restauradora(rng):
    length = 0.9
    mix = silence(length)
    for index, freq in enumerate((C5, E5, G5, C6)):
        note = decay(tone(0.5, freq, (1.0, 0.3), (5.0, 0.004)), 0.5, 0.005)
        add(mix, note, index * 0.12, 0.5)
    for _ in range(10):
        add(mix, bubble(rng.uniform(1500.0, 3000.0), 0.04), rng.uniform(0.1, 0.75), 0.15)
    add(mix, shape(band(noise(rng, length), 2500.0, 1.0), [(0.0, 0.0), (0.4, 1.0), (0.9, 0.0)]), 0.0, 0.06)
    return mix, 1.0


def torrente(rng):
    length = 0.6
    rush = low(noise(rng, length), [(0.0, 800.0), (0.25, 2500.0), (0.6, 1200.0)], 0.9)
    rush = [a + b * 0.6 for a, b in zip(rush, band(noise(rng, length), 400.0, 0.7))]
    mix = flutter(rng, shape(rush, [(0.0, 0.0), (0.08, 1.0), (0.4, 0.9), (0.6, 0.0)]), 20.0, 0.4)
    add(mix, shape(low(noise(rng, length), 120.0), [(0.0, 0.0), (0.1, 1.0), (0.6, 0.0)]), 0.0, 1.6)
    return mix, 1.6


def muralha_de_coral(rng):
    length = 1.0
    mix = silence(length)
    add(mix, thud(150.0, 90.0, 0.12), 0.0, 0.6)
    for index, freq in enumerate(PENTATONIC[:7]):
        add(mix, ping(freq * 0.85, 0.2, ((1.0, 1.0), (2.76, 0.4))), index * 0.1, 0.45)
        add(mix, click(rng, 5000.0, 0.008), index * 0.1, 0.3)
    add(mix, thud(150.0, 90.0, 0.12), 0.62, 0.5)
    add(mix, shape(band(noise(rng, 0.4), 6000.0, 1.5), [(0.0, 0.0), (0.05, 1.0), (0.4, 0.0)]), 0.6, 0.12)
    return mix, 1.1


def maremoto(rng):
    length = 0.6
    mix = silence(length)
    swell = low(noise(rng, 0.34), [(0.0, 200.0), (0.32, 1800.0)], 1.0)
    add(mix, shape(swell, [(0.0, 0.0), (0.3, 1.0), (0.34, 0.6)]), 0.0, 1.0)
    add(mix, shape(tone(0.4, [(0.0, 60.0), (0.3, 90.0), (0.4, 50.0)]), [(0.0, 0.0), (0.28, 1.0), (0.4, 0.0)]), 0.0, 0.7)
    crash = high(noise(rng, 0.3), 300.0)
    crash = [a + b for a, b in zip(crash, band(noise(rng, 0.3), 1200.0, 0.7))]
    add(mix, flutter(rng, decay(crash, 0.3, 0.005), 30.0, 0.4), 0.3, 1.0)
    return mix, 1.8


def chicote_de_raiz(rng):
    length = 0.6
    mix = silence(length)
    swish = band(noise(rng, 0.26), [(0.0, 500.0), (0.26, 3500.0)], 2.0)
    add(mix, shape(swish, [(0.0, 0.0), (0.24, 1.0), (0.26, 0.0)]), 0.0, 1.8)
    add(mix, decay(noise(rng, 0.004), 0.004, 0.0), 0.26, 1.5)
    add(mix, decay(band(noise(rng, 0.05), 2500.0, 1.0), 0.04, 0.001), 0.26, 1.4)
    add(mix, thud(200.0, 120.0, 0.06), 0.26, 0.4)
    add(mix, shape(band(noise(rng, 0.3), 4000.0, 1.0), [(0.0, 0.5), (0.3, 0.0)]), 0.28, 0.4)
    return mix, 3.0


def esporos_sonolentos(rng):
    length = 0.7
    mix = silence(length)
    add(mix, shape(low(noise(rng, 0.18), 900.0), [(0.0, 0.0), (0.04, 1.0), (0.18, 0.0)]), 0.0, 0.8)
    sleepy = [(0.0, 880.0), (0.6, 440.0)]
    for ratio, weight in ((1.0, 0.45), (2.0 / 3.0, 0.3)):
        layer = tone(length, [(t, f * ratio) for t, f in sleepy], (1.0, 0.15), (5.0, 0.02))
        add(mix, shape(layer, [(0.0, 0.0), (0.08, 0.6), (0.5, 0.5), (0.7, 0.0)]), 0.0, weight)
    add(mix, shape(band(noise(rng, length), 7000.0, 1.5), [(0.0, 0.0), (0.2, 1.0), (0.7, 0.0)]), 0.0, 0.08)
    return mix, 1.0


def seiva_vital(rng):
    length = 0.6
    mix = silence(length)
    for at in (0.0, 0.04, 0.09, 0.13):
        add(mix, decay(band(noise(rng, 0.04), rng.uniform(600.0, 800.0), 8.0), 0.035, 0.002), at, 2.0)
    slurp = tone(0.5, [(0.0, 700.0), (0.3, 250.0), (0.5, 600.0)], (1.0, 0.3), (9.0, 0.03))
    add(mix, shape(slurp, [(0.0, 0.0), (0.06, 0.7), (0.4, 0.7), (0.5, 0.0)]), 0.0, 0.6)
    add(mix, ping(1568.0, 0.15), 0.42, 0.35)
    add(mix, ping(2093.0, 0.15), 0.47, 0.3)
    return mix, 1.3


def folha_navalha(rng):
    length = 0.45
    mix = silence(length)
    for at in (0.0, 0.1, 0.2):
        cut = band(noise(rng, 0.07), [(0.0, 7500.0), (0.07, 3000.0)], 4.0)
        add(mix, decay(cut, 0.07, 0.002), at, 1.6)
    add(mix, shape(band(noise(rng, 0.4), 3500.0, 0.8), [(0.0, 0.0), (0.1, 1.0), (0.4, 0.0)]), 0.0, 0.25)
    return mix, 3.0


def banho_de_sol(rng):
    length = 0.8
    mix = silence(length)
    for index, freq in enumerate((G4, B4, D5, G5_)):
        note = decay(tone(0.5, freq, (1.0, 0.35, 0.12), (4.0, 0.003)), 0.5, 0.02)
        add(mix, note, index * 0.1, 0.45)
    add(mix, ping(2349.3, 0.25), 0.4, 0.2)
    add(mix, ping(3136.0, 0.25), 0.5, 0.15)
    add(mix, shape(band(noise(rng, length), 1200.0, 0.6), [(0.0, 0.0), (0.3, 1.0), (0.8, 0.0)]), 0.0, 0.1)
    return mix, 1.0


def tempestade_de_petalas(rng):
    length = 0.5
    swirl = [(t, 1500.0 + 900.0 * math.sin(2.0 * math.pi * 7.0 * t)) for t in [i / 200.0 for i in range(101)]]
    mix = shape(band(noise(rng, length), swirl, 2.0), [(0.0, 0.0), (0.06, 1.0), (0.35, 0.8), (0.5, 0.0)])
    for _ in range(5):
        add(mix, ping(rng.choice(PENTATONIC[2:]), 0.12), rng.uniform(0.05, 0.38), 0.18)
    return mix, 1.2


def explosao_florida(rng):
    length = 0.6
    mix = silence(length)
    add(mix, thud(160.0, 50.0, 0.25), 0.0, 1.2)
    add(mix, decay(low(noise(rng, 0.15), 1500.0), 0.12, 0.002), 0.0, 1.0)
    for index, freq in enumerate((1046.5, 1318.5, 1568.0, 2093.0, 2637.0)):
        add(mix, ping(freq, 0.2), 0.08 + index * 0.07, 0.3)
    add(mix, decay(band(noise(rng, 0.4), 3000.0, 0.8), 0.35, 0.01), 0.02, 0.3)
    return mix, 1.4


SOUNDS = {
    "mordida_brasa": mordida_brasa,
    "fumaca_densa": fumaca_densa,
    "presa_ignea": presa_ignea,
    "chama_espiral": chama_espiral,
    "couraca_de_cinzas": couraca_de_cinzas,
    "erupcao_solar": erupcao_solar,
    "jato_de_mare": jato_de_mare,
    "espuma_densa": espuma_densa,
    "garra_de_mare": garra_de_mare,
    "casca_fechada": casca_fechada,
    "lamina_d_agua": lamina_d_agua,
    "mare_restauradora": mare_restauradora,
    "torrente": torrente,
    "muralha_de_coral": muralha_de_coral,
    "maremoto": maremoto,
    "chicote_de_raiz": chicote_de_raiz,
    "esporos_sonolentos": esporos_sonolentos,
    "seiva_vital": seiva_vital,
    "folha_navalha": folha_navalha,
    "banho_de_sol": banho_de_sol,
    "tempestade_de_petalas": tempestade_de_petalas,
    "explosao_florida": explosao_florida,
}


def write(slug, mix, drive):
    mix = [math.tanh(value * drive) for value in mix]
    # Uma rampa de 3 ms no fim evita o estalo do corte.
    fade = count_of(0.003)
    for index in range(fade):
        mix[-1 - index] *= index / fade
    loudest = max(abs(value) for value in mix) or 1.0
    frames = b"".join(struct.pack("<h", int(value / loudest * PEAK * 32767)) for value in mix)
    out = OUT_DIR / (slug + ".wav")
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)
    print("ok: %s %.2f s" % (out.name, len(mix) / RATE))


def main():
    only = sys.argv[1:]
    for slug, make in SOUNDS.items():
        if only and slug not in only:
            continue
        mix, drive = make(random.Random(zlib.crc32(slug.encode())))
        write(slug, mix, drive)


main()
