"""Gera o som das Técnicas da board-battle/18 e /20 a /22 e /25 a /27 e /29 a /32 (board-battle/19 a /22, /25 a /27 e /29 a /32), por síntese:
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


def uivo(rng):
    """Uivo de lobo: uma voz que sobe, segura com vibrato e cai no fim, com cor de "u"
    e um sopro por cima."""
    length = 0.9
    pitch = [(0.0, 300.0), (0.18, 560.0), (0.55, 640.0), (0.9, 420.0)]
    voice = tone(length, pitch, (1.0, 0.45, 0.2, 0.08), (5.5, 0.015))
    mix = [value * 0.4 for value in voice]
    for freq, q, weight in ((380.0, 2.5, 2.0), (900.0, 3.0, 0.8)):
        add(mix, band(voice, freq, q), 0.0, weight)
    add(mix, band(noise(rng, length), [(0.0, 900.0), (0.9, 1400.0)], 1.5), 0.0, 0.35)
    return shape(mix, [(0.0, 0.0), (0.08, 0.7), (0.2, 1.0), (0.65, 0.9), (0.9, 0.0)]), 1.0


def patada(rng):
    """Patada: um zunido curto da pata vindo, um baque pesado e um estalo de impacto."""
    length = 0.45
    mix = silence(length)
    swing = band(noise(rng, 0.1), [(0.0, 600.0), (0.1, 1800.0)], 1.5)
    add(mix, shape(swing, [(0.0, 0.0), (0.09, 1.0), (0.1, 0.0)]), 0.0, 0.8)
    add(mix, thud(140.0, 45.0, 0.2), 0.1, 1.5)
    add(mix, decay(low(noise(rng, 0.12), 900.0), 0.1, 0.001), 0.1, 1.2)
    add(mix, click(rng, 2400.0, 0.02, 1.0), 0.1, 1.0)
    add(mix, crackles(rng, length, 40.0, 0.12, 0.3, freq=2000.0), 0.0, 0.5)
    return mix, 2.2


def olhar_manhoso(rng):
    """Olhar Manhoso: um brilho agudo do olhar, um tom grave e sinuoso que desce e a
    defesa trincando em cacos."""
    length = 0.9
    mix = silence(length)
    add(mix, ping(2637.0, 0.25, ((1.0, 1.0), (1.5, 0.4))), 0.0, 0.5)
    sly = tone(0.6, [(0.0, 330.0), (0.6, 196.0)], (1.0, 0.3), (3.0, 0.03))
    add(mix, shape(sly, [(0.0, 0.0), (0.1, 0.6), (0.45, 0.5), (0.6, 0.0)]), 0.05, 0.6)
    add(mix, click(rng, 3800.0, 0.03, 1.2), 0.45, 1.3)
    for _ in range(7):
        add(mix, ping(rng.uniform(2800.0, 5200.0), 0.08, ((1.0, 1.0), (2.4, 0.3))), rng.uniform(0.46, 0.62), 0.3)
    add(mix, decay(band(noise(rng, 0.2), 5000.0, 1.0), 0.15, 0.002), 0.45, 0.5)
    return mix, 1.3


def lufada_cortante(rng):
    """Lufada Cortante: uma rajada que corta rápido do agudo para o médio, com um
    assobio de lâmina."""
    length = 0.45
    mix = silence(length)
    gust = band(noise(rng, 0.4), [(0.0, 5500.0), (0.4, 1400.0)], 2.5)
    add(mix, shape(gust, [(0.0, 0.0), (0.04, 1.0), (0.2, 0.6), (0.4, 0.0)]), 0.0, 1.4)
    add(mix, shape(tone(0.3, [(0.0, 2200.0), (0.3, 900.0)]), [(0.0, 0.0), (0.03, 1.0), (0.3, 0.0)]), 0.0, 0.25)
    add(mix, shape(low(noise(rng, 0.4), 500.0), [(0.0, 0.0), (0.05, 1.0), (0.4, 0.0)]), 0.0, 0.5)
    return mix, 1.6


def danca_do_vento(rng):
    """Dança do Vento: um vento que gira em volta, com o filtro indo e vindo, e notas leves
    que sobem."""
    length = 0.7
    swirl = [(t, 1300.0 + 700.0 * math.sin(2.0 * math.pi * 5.0 * t)) for t in [i / 200.0 for i in range(141)]]
    mix = shape(band(noise(rng, length), swirl, 2.0), [(0.0, 0.0), (0.1, 1.0), (0.5, 0.8), (0.7, 0.0)])
    for index, freq in enumerate((1318.5, 1568.0, 1760.0, 2093.0)):
        add(mix, ping(freq, 0.18), 0.1 + index * 0.1, 0.22)
    return mix, 2.0


def ciclone(rng):
    """Ciclone: um redemoinho que ronca e gira rápido, com um assobio que sobe."""
    length = 0.7
    spin = [(t, 900.0 + 600.0 * math.sin(2.0 * math.pi * 11.0 * t)) for t in [i / 200.0 for i in range(141)]]
    roar = band(noise(rng, length), spin, 1.5)
    mix = shape(roar, [(0.0, 0.0), (0.08, 1.0), (0.5, 0.9), (0.7, 0.0)])
    add(mix, shape(low(noise(rng, length), 160.0), [(0.0, 0.0), (0.1, 1.0), (0.7, 0.0)]), 0.0, 1.5)
    whistle = tone(length, [(0.0, 700.0), (0.6, 1500.0)], (1.0,), (11.0, 0.03))
    add(mix, shape(whistle, [(0.0, 0.0), (0.15, 0.6), (0.55, 0.6), (0.7, 0.0)]), 0.0, 0.18)
    return mix, 2.6


def lamina_sombria(rng):
    """Lâmina Sombria: um "shing" de lâmina, um corte que desce e um zumbido grave e
    sombrio que pulsa e some."""
    length = 0.5
    mix = silence(length)
    add(mix, ping(3200.0, 0.12, ((1.0, 1.0), (1.47, 0.6), (2.31, 0.3))), 0.0, 0.35)
    cut = band(noise(rng, 0.2), [(0.0, 4500.0), (0.2, 900.0)], 2.5)
    add(mix, shape(cut, [(0.0, 0.0), (0.04, 1.0), (0.2, 0.0)]), 0.02, 1.3)
    add(mix, shape(low(noise(rng, 0.4), 300.0), [(0.0, 0.0), (0.06, 1.0), (0.4, 0.0)]), 0.02, 1.0)
    dark = [a + b for a, b in zip(tone(0.45, 110.0, (1.0, 0.4)), tone(0.45, 116.0, (1.0, 0.4)))]
    add(mix, shape(dark, [(0.0, 0.0), (0.08, 0.5), (0.45, 0.0)]), 0.05, 0.4)
    return mix, 1.7


def pinca_de_aco(rng):
    """Pinça de Aço: um rangido de metal abrindo, o estalo da pinça fechando com um
    tinido e o aperto rangendo."""
    length = 0.7
    mix = silence(length)
    creak = band(noise(rng, 0.25), [(0.0, 900.0), (0.25, 1600.0)], 6.0)
    add(mix, shape(creak, [(0.0, 0.0), (0.05, 1.0), (0.25, 0.6)]), 0.0, 2.0)
    add(mix, ping(900.0, 0.3, ((1.0, 1.0), (1.49, 0.7), (2.33, 0.45))), 0.26, 0.8)
    add(mix, thud(150.0, 60.0, 0.12), 0.26, 1.0)
    add(mix, click(rng, 3000.0, 0.02, 1.2), 0.26, 1.4)
    grind = band(noise(rng, 0.3), 2500.0, 3.0)
    add(mix, flutter(rng, shape(grind, [(0.0, 0.0), (0.05, 1.0), (0.3, 0.0)]), 60.0, 0.7), 0.34, 0.8)
    return mix, 1.8


def garra_de_picareta(rng):
    """Garra de Picareta: três garras de metal raspando, o golpe cravando na pedra e o
    chão se partindo em lascas."""
    length = 0.6
    mix = silence(length)
    for at in (0.0, 0.05, 0.1):
        scrape = band(noise(rng, 0.08), [(0.0, 6000.0), (0.08, 2500.0)], 5.0)
        add(mix, decay(scrape, 0.08, 0.002), at, 1.6)
    add(mix, thud(130.0, 45.0, 0.2), 0.15, 1.4)
    add(mix, click(rng, 1800.0, 0.03, 1.0), 0.15, 1.2)
    add(mix, ping(1800.0, 0.2, ((1.0, 1.0), (2.7, 0.3))), 0.15, 0.3)
    add(mix, crackles(rng, length, 90.0, 0.16, 0.45, freq=1500.0), 0.0, 1.0)
    return mix, 2.0


def beliscao(rng):
    """Beliscão: o estalo seco de uma pinça pequena se fechando duas vezes, com um
    guinchinho."""
    length = 0.4
    mix = silence(length)
    for at in (0.02, 0.14):
        add(mix, click(rng, 2800.0, 0.015, 1.5), at, 1.5)
        add(mix, thud(240.0, 120.0, 0.05), at, 0.5)
    add(mix, decay(tone(0.07, [(0.0, 1200.0), (0.07, 1800.0)]), 0.07, 0.005), 0.15, 0.25)
    return mix, 3.2


def couraca(rng):
    """Couraça: um zumbido metálico que sobe enquanto o corpo endurece e uma batida de
    bigorna no fim."""
    length = 0.65
    mix = silence(length)
    hum = tone(0.36, [(0.0, 200.0), (0.34, 420.0)], (1.0, 0.5, 0.33, 0.25), (14.0, 0.01))
    add(mix, shape(low(hum, 1800.0), [(0.0, 0.0), (0.1, 0.5), (0.34, 0.8), (0.36, 0.0)]), 0.0, 0.6)
    add(mix, ping(600.0, 0.3, ((1.0, 1.0), (2.5, 0.6), (4.0, 0.3))), 0.35, 0.9)
    add(mix, thud(120.0, 60.0, 0.12), 0.35, 1.0)
    add(mix, click(rng, 2500.0, 0.02, 1.0), 0.35, 1.0)
    return mix, 1.5


def geada_silenciosa(rng):
    """Geada Silenciosa: um chiado de gelo bem baixo se espalhando e tinidos de cristal
    leves e soltos."""
    length = 0.5
    mix = shape(band(noise(rng, length), [(0.0, 6000.0), (0.5, 8000.0)], 2.0), [(0.0, 0.0), (0.1, 1.0), (0.5, 0.0)])
    mix = [value * 0.35 for value in mix]
    for _ in range(9):
        add(mix, ping(rng.uniform(3000.0, 6000.0), 0.1, ((1.0, 1.0), (2.76, 0.3))), rng.uniform(0.0, 0.4), rng.uniform(0.15, 0.35))
    return mix, 1.0


def nuvem_de_poeira(rng):
    """Nuvem de Poeira: um sopro seco que levanta e se espalha, com grãos de areia
    chiando."""
    length = 0.6
    puff = low(noise(rng, length), [(0.0, 500.0), (0.2, 2200.0), (0.6, 800.0)], 0.8)
    mix = shape(puff, [(0.0, 0.0), (0.08, 1.0), (0.35, 0.6), (0.6, 0.0)])
    add(mix, crackles(rng, length, 260.0, 0.03, 0.55, weight=0.25, freq=5000.0), 0.0, 1.0)
    add(mix, shape(band(noise(rng, length), 3000.0, 1.0), [(0.0, 0.0), (0.1, 0.5), (0.6, 0.0)]), 0.0, 0.4)
    return mix, 1.5


def floco_cortante(rng):
    """Floco Cortante: um "tsing" de cristal, um corte agudo e rápido e cacos de gelo
    tilintando."""
    length = 0.4
    mix = silence(length)
    add(mix, ping(4200.0, 0.2, ((1.0, 1.0), (1.41, 0.6), (2.76, 0.3))), 0.0, 0.6)
    cut = band(noise(rng, 0.1), [(0.0, 8000.0), (0.1, 4000.0)], 4.0)
    add(mix, decay(cut, 0.1, 0.002), 0.02, 1.5)
    for _ in range(6):
        add(mix, ping(rng.uniform(3500.0, 6500.0), 0.06, ((1.0, 1.0), (2.4, 0.3))), rng.uniform(0.08, 0.25), 0.3)
    return mix, 1.6


def arremesso_de_torrao(rng):
    """Arremesso de Torrão: o zunido do torrão voando, o baque pesado de terra e o
    torrão se desfazendo."""
    length = 0.55
    mix = silence(length)
    throw = band(noise(rng, 0.16), [(0.0, 400.0), (0.16, 1200.0)], 1.5)
    add(mix, shape(throw, [(0.0, 0.0), (0.14, 1.0), (0.16, 0.0)]), 0.0, 0.8)
    add(mix, thud(120.0, 40.0, 0.22), 0.15, 1.5)
    add(mix, decay(low(noise(rng, 0.15), 700.0), 0.12, 0.001), 0.15, 1.3)
    add(mix, crackles(rng, length, 110.0, 0.16, 0.45, freq=900.0), 0.0, 0.9)
    return mix, 2.2


def manto_de_neve(rng):
    """Manto de Neve: neve girando em volta, macia, com sininhos de gelo que descem."""
    length = 0.7
    swirl = [(t, 5000.0 + 1500.0 * math.sin(2.0 * math.pi * 4.0 * t)) for t in [i / 200.0 for i in range(141)]]
    mix = shape(band(noise(rng, length), swirl, 1.8), [(0.0, 0.0), (0.12, 1.0), (0.5, 0.8), (0.7, 0.0)])
    for index, freq in enumerate((2637.0, 2349.3, 2093.0, 1760.0)):
        add(mix, ping(freq, 0.25, ((1.0, 1.0), (2.76, 0.25))), 0.08 + index * 0.11, 0.3)
    add(mix, shape(low(noise(rng, length), 400.0), [(0.0, 0.0), (0.2, 1.0), (0.7, 0.0)]), 0.0, 0.3)
    return mix, 1.2


def eco_mental(rng):
    """Eco Mental: um tom estranho e trêmulo que se repete três vezes, cada vez mais baixo
    e mais longe."""
    length = 0.6
    mix = silence(length)
    voice = tone(0.22, [(0.0, 520.0), (0.11, 780.0), (0.22, 600.0)], (1.0, 0.4, 0.2), (13.0, 0.03))
    ring = [value * math.sin(2.0 * math.pi * 90.0 * index / RATE) for index, value in enumerate(voice)]
    call = shape([a * 0.6 + b * 0.5 for a, b in zip(voice, ring)], [(0.0, 0.0), (0.03, 1.0), (0.18, 0.6), (0.22, 0.0)])
    for index, weight in enumerate((1.0, 0.55, 0.3)):
        add(mix, low(call, 4000.0 - index * 1200.0), index * 0.15, weight)
    add(mix, shape(band(noise(rng, length), 6000.0, 1.5), [(0.0, 0.0), (0.2, 1.0), (0.6, 0.0)]), 0.0, 0.08)
    return mix, 1.3


def garra_de_pedra(rng):
    """Garra de Pedra: um golpe pesado de garra e pedra rangendo e se partindo."""
    length = 0.55
    mix = silence(length)
    swipe = band(noise(rng, 0.16), [(0.0, 2500.0), (0.16, 600.0)], 2.0)
    add(mix, decay(swipe, 0.16, 0.004), 0.0, 1.3)
    add(mix, thud(110.0, 45.0, 0.18), 0.08, 1.3)
    add(mix, crackles(rng, length, 140.0, 0.08, 0.4, freq=1200.0), 0.0, 1.0)
    grind = band(noise(rng, 0.25), 900.0, 3.0)
    add(mix, flutter(rng, shape(grind, [(0.0, 0.0), (0.04, 1.0), (0.25, 0.0)]), 50.0, 0.7), 0.1, 0.8)
    return mix, 2.2


def garra_do_eclipse(rng):
    """Garra do Eclipse: a escuridão puxando o ar para dentro, um risco fundo de garra e
    um zumbido grave e desafinado que fica no ar."""
    length = 0.6
    mix = silence(length)
    pull = band(noise(rng, 0.18), [(0.0, 300.0), (0.18, 1400.0)], 1.2)
    add(mix, shape(pull, [(0.0, 0.0), (0.16, 1.0), (0.18, 0.0)]), 0.0, 0.7)
    for at in (0.16, 0.2):
        slash = band(noise(rng, 0.12), [(0.0, 3500.0), (0.12, 700.0)], 2.5)
        add(mix, decay(slash, 0.12, 0.002), at, 1.3)
    add(mix, thud(95.0, 40.0, 0.2), 0.17, 1.1)
    dark = [a + b for a, b in zip(tone(0.42, 82.0, (1.0, 0.5, 0.25)), tone(0.42, 87.0, (1.0, 0.5, 0.25)))]
    add(mix, shape(low(dark, 900.0), [(0.0, 0.0), (0.06, 0.6), (0.42, 0.0)]), 0.18, 0.5)
    return mix, 1.8


def martelo_de_ferro(rng):
    """Martelo de Ferro: o punho pesado cortando o ar, a pancada de ferro na bigorna,
    que ressoa, e as faíscas estalando."""
    length = 0.6
    mix = silence(length)
    swing = band(noise(rng, 0.12), [(0.0, 300.0), (0.12, 900.0)], 1.2)
    add(mix, shape(swing, [(0.0, 0.0), (0.11, 1.0), (0.12, 0.0)]), 0.0, 0.7)
    add(mix, thud(140.0, 38.0, 0.22), 0.12, 1.6)
    add(mix, click(rng, 2200.0, 0.025, 1.0), 0.12, 1.6)
    add(mix, ping(780.0, 0.45, ((1.0, 1.0), (2.76, 0.6), (5.4, 0.35), (8.9, 0.15))), 0.12, 0.8)
    add(mix, crackles(rng, length, 120.0, 0.13, 0.4, weight=0.8, freq=5500.0), 0.0, 1.0)
    return mix, 2.0


def lanca_de_cristal(rng):
    """Lança de Cristal: o cristal crescendo num brilho que sobe, a ponta furando o ar
    num estalo agudo e a lança se desfazendo em cacos."""
    length = 0.65
    mix = silence(length)
    grow = tone(0.2, [(0.0, 1800.0), (0.2, 3600.0)], (1.0, 0.3), (22.0, 0.01))
    add(mix, shape(grow, [(0.0, 0.0), (0.18, 1.0), (0.2, 0.0)]), 0.0, 0.25)
    add(mix, shape(band(noise(rng, 0.2), [(0.0, 3000.0), (0.2, 7000.0)], 3.0), [(0.0, 0.0), (0.2, 1.0)]), 0.0, 0.6)
    add(mix, decay(band(noise(rng, 0.06), 6500.0, 3.0), 0.06, 0.001), 0.2, 1.6)
    add(mix, ping(3500.0, 0.25, ((1.0, 1.0), (1.41, 0.6), (2.76, 0.3))), 0.2, 0.6)
    for _ in range(9):
        add(mix, ping(rng.uniform(3000.0, 6500.0), 0.07, ((1.0, 1.0), (2.4, 0.3))), rng.uniform(0.32, 0.55), rng.uniform(0.2, 0.4))
    return mix, 1.6


def inverno_mudo(rng):
    """Inverno Mudo: uma rajada gelada que cresce e se corta de repente, deixando um
    brilho fino e o gelo estalando no silêncio."""
    length = 0.7
    mix = silence(length)
    gust = band(noise(rng, 0.3), [(0.0, 900.0), (0.28, 3500.0)], 1.0)
    add(mix, shape(gust, [(0.0, 0.0), (0.26, 1.0), (0.3, 0.0)]), 0.0, 1.0)
    add(mix, shape(low(noise(rng, 0.3), 500.0), [(0.0, 0.0), (0.26, 1.0), (0.3, 0.0)]), 0.0, 0.6)
    hush = shape(tone(0.4, 4186.0, (1.0,), (6.0, 0.004)), [(0.0, 0.0), (0.05, 1.0), (0.4, 0.0)])
    add(mix, hush, 0.3, 0.12)
    for index, at in enumerate((0.32, 0.41, 0.53)):
        add(mix, click(rng, 2500.0 - index * 400.0, 0.03, 2.0), at, 0.9 - index * 0.2)
        add(mix, ping(rng.uniform(3500.0, 5000.0), 0.08, ((1.0, 1.0), (2.76, 0.3))), at, 0.2)
    return mix, 1.5


def grito_congelado(rng):
    """Grito Congelado: um grito fantasma que desce e treme, preso num eco gelado, com o
    gelo chiando por baixo."""
    length = 0.75
    mix = silence(length)
    pitch = [(0.0, 700.0), (0.08, 900.0), (0.45, 420.0)]
    voice = tone(0.45, pitch, (1.0, 0.6, 0.45, 0.3, 0.2), (9.0, 0.05))
    scream = [0.0] * len(voice)
    for freq, q, weight in ((900.0, 3.0, 1.0), (2600.0, 4.0, 0.7)):
        for index, value in enumerate(band(voice, freq, q)):
            scream[index] += value * weight
    for index, value in enumerate(band(noise(rng, 0.45), 2200.0, 1.5)):
        scream[index] += value * 0.4
    scream = shape(scream, [(0.0, 0.0), (0.04, 1.0), (0.3, 0.7), (0.45, 0.0)])
    for index, weight in enumerate((1.0, 0.4, 0.18)):
        add(mix, low(scream, 6000.0 - index * 2000.0), index * 0.13, weight)
    frost = shape(band(noise(rng, length), 7000.0, 2.0), [(0.0, 0.0), (0.15, 1.0), (0.75, 0.0)])
    add(mix, frost, 0.0, 0.25)
    return mix, 1.6


def palavra_guardada(rng):
    """Palavra Guardada: um sussurro baixinho e um acorde calmo que se abre, nota a nota,
    com um brilho que sobe no fim."""
    length = 0.75
    mix = silence(length)
    whisper = shape(band(noise(rng, 0.22), 2500.0, 1.8), [(0.0, 0.0), (0.06, 1.0), (0.22, 0.0)])
    add(mix, flutter(rng, whisper, 30.0, 0.6), 0.0, 0.35)
    for index, freq in enumerate((C5, E5, G5, C6)):
        note = shape(tone(0.6 - index * 0.08, freq, (1.0, 0.25), (5.0, 0.004)), [(0.0, 0.0), (0.05, 1.0), (0.5 - index * 0.08, 0.0)])
        add(mix, note, 0.12 + index * 0.08, 0.32)
    for index, freq in enumerate(PENTATONIC[3:]):
        add(mix, ping(freq, 0.12, ((1.0, 1.0), (2.0, 0.2))), 0.45 + index * 0.04, 0.15)
    return mix, 1.2


def pena_afiada(rng):
    """Pena Afiada: um "fiu" curto e agudo da pena cortando o ar e um tique seco quando ela
    crava."""
    length = 0.45
    mix = silence(length)
    dart = band(noise(rng, 0.25), [(0.0, 3000.0), (0.25, 7000.0)], 3.0)
    add(mix, shape(dart, [(0.0, 0.0), (0.03, 1.0), (0.18, 0.5), (0.25, 0.0)]), 0.0, 1.3)
    add(mix, shape(tone(0.2, [(0.0, 1800.0), (0.2, 3200.0)]), [(0.0, 0.0), (0.02, 1.0), (0.2, 0.0)]), 0.0, 0.18)
    add(mix, click(rng, 4200.0, 0.06), 0.24, 0.9)
    add(mix, decay(band(noise(rng, 0.15), 1200.0, 1.2), 0.1, 0.002), 0.24, 0.35)
    return mix, 1.6


def vento_a_favor(rng):
    """Vento a Favor: uma brisa que cresce por trás, com o filtro subindo, e três notas leves
    que sobem, o empurrão do vento."""
    length = 0.65
    breeze = band(noise(rng, length), [(0.0, 700.0), (0.45, 2600.0), (0.65, 3200.0)], 1.6)
    mix = shape(breeze, [(0.0, 0.0), (0.2, 1.0), (0.45, 0.8), (0.65, 0.0)])
    add(mix, shape(low(noise(rng, length), 300.0), [(0.0, 0.0), (0.2, 1.0), (0.65, 0.0)]), 0.0, 0.6)
    for index, freq in enumerate((G5, C6, PENTATONIC[4])):
        add(mix, ping(freq, 0.2), 0.18 + index * 0.1, 0.24)
    return mix, 1.8


def rajada_de_penas(rng):
    """Rajada de Penas: quatro "fius" de pena em seguida, cada um um pouco mais agudo, com
    o farfalhar das penas por baixo."""
    length = 0.65
    mix = silence(length)
    for index in range(4):
        start = 1800.0 + index * 400.0
        dart = band(noise(rng, 0.16), [(0.0, start), (0.16, start * 2.2)], 3.0)
        add(mix, shape(dart, [(0.0, 0.0), (0.02, 1.0), (0.16, 0.0)]), index * 0.12, 1.0)
        add(mix, click(rng, 3800.0, 0.04), index * 0.12 + 0.12, 0.45)
    rustle = flutter(rng, band(noise(rng, length), 4500.0, 0.8), 40.0, 0.8)
    add(mix, shape(rustle, [(0.0, 0.0), (0.05, 1.0), (0.5, 0.6), (0.65, 0.0)]), 0.0, 0.3)
    return mix, 1.6


def nuvem_de_penas(rng):
    """Nuvem de Penas: um sopro que espalha as penas e um farfalhar macio que treme e vai
    caindo devagar."""
    length = 0.75
    mix = silence(length)
    puff = band(noise(rng, 0.3), [(0.0, 900.0), (0.3, 2200.0)], 1.2)
    add(mix, shape(puff, [(0.0, 0.0), (0.05, 1.0), (0.3, 0.0)]), 0.0, 0.9)
    rustle = flutter(rng, band(noise(rng, 0.7), [(0.0, 5000.0), (0.7, 2500.0)], 1.0), 24.0, 0.9)
    add(mix, shape(rustle, [(0.0, 0.0), (0.12, 1.0), (0.45, 0.7), (0.7, 0.0)]), 0.05, 0.8)
    for index, freq in enumerate((PENTATONIC[6], PENTATONIC[4], PENTATONIC[2])):
        add(mix, ping(freq, 0.14, ((1.0, 1.0),)), 0.25 + index * 0.13, 0.1)
    return mix, 1.5


def vendaval(rng):
    """Vendaval: uma ventania forte que ronca e cresce, com um uivo de vento que treme e
    desce, e o rumor grave do redemoinho que fica."""
    length = 0.8
    gust = band(noise(rng, length), [(0.0, 600.0), (0.25, 1800.0), (0.8, 900.0)], 1.2)
    mix = shape(gust, [(0.0, 0.0), (0.12, 1.0), (0.55, 0.9), (0.8, 0.0)])
    add(mix, shape(low(noise(rng, length), 140.0), [(0.0, 0.0), (0.15, 1.0), (0.8, 0.0)]), 0.0, 1.6)
    howl = tone(0.65, [(0.0, 900.0), (0.25, 1250.0), (0.65, 700.0)], (1.0, 0.3), (7.0, 0.04))
    add(mix, shape(howl, [(0.0, 0.0), (0.12, 0.7), (0.5, 0.5), (0.65, 0.0)]), 0.05, 0.16)
    return mix, 2.4


def rasante(rng):
    """Rasante: o assobio do mergulho, que desce de altura como quem passa rápido, e o
    tapa pesado das asas abertas no fim."""
    length = 0.55
    mix = silence(length)
    dive = band(noise(rng, 0.35), [(0.0, 4200.0), (0.35, 1200.0)], 2.2)
    add(mix, shape(dive, [(0.0, 0.0), (0.2, 1.0), (0.35, 0.3)]), 0.0, 1.1)
    add(mix, shape(tone(0.32, [(0.0, 1600.0), (0.32, 650.0)]), [(0.0, 0.0), (0.18, 0.8), (0.32, 0.0)]), 0.0, 0.16)
    flap = shape(low(noise(rng, 0.18), 900.0), [(0.0, 0.0), (0.008, 1.0), (0.18, 0.0)])
    add(mix, flap, 0.33, 1.4)
    add(mix, thud(160.0, 70.0, 0.2), 0.33, 0.8)
    return mix, 1.8


def bicada_de_folha(rng):
    """Bicada de Folha: um farfalhar curto das folhas do bico vindo e a bicada seca, de
    madeira, com um baque leve."""
    length = 0.4
    mix = silence(length)
    rustle = flutter(rng, band(noise(rng, 0.18), 3500.0, 1.0), 45.0, 0.8)
    add(mix, shape(rustle, [(0.0, 0.0), (0.04, 1.0), (0.18, 0.0)]), 0.0, 0.8)
    add(mix, click(rng, 1900.0, 0.05, 2.0), 0.16, 1.2)
    add(mix, ping(820.0, 0.08, ((1.0, 1.0), (2.7, 0.4))), 0.16, 0.35)
    add(mix, thud(240.0, 110.0, 0.12), 0.16, 0.6)
    return mix, 1.6


def garra_de_espinho(rng):
    """Garra de Espinho: o ramo de espinhos rangendo, três arranhões rápidos e o estalo dos
    espinhos cravando."""
    length = 0.6
    mix = silence(length)
    creak = shape(tone(0.25, [(0.0, 180.0), (0.25, 140.0)], (1.0, 0.6, 0.4), (23.0, 0.05)), [(0.0, 0.0), (0.05, 1.0), (0.25, 0.0)])
    add(mix, band(creak, 600.0, 1.0), 0.0, 0.5)
    for index in range(3):
        scratch = band(noise(rng, 0.09), [(0.0, 5200.0), (0.09, 2600.0)], 2.0)
        add(mix, shape(scratch, [(0.0, 0.0), (0.01, 1.0), (0.09, 0.0)]), 0.14 + index * 0.08, 1.0)
    add(mix, crackles(rng, 0.25, 60.0, weight=0.7, freq=2800.0), 0.36, 1.0)
    add(mix, thud(200.0, 90.0, 0.14), 0.36, 0.5)
    return mix, 1.7


def asa_semeadora(rng):
    """Asa Semeadora: a batida larga da asa, as sementes chovendo em estalinhos e os
    espinhos brotando do chão num ranger que sobe."""
    length = 0.8
    mix = silence(length)
    wing = band(noise(rng, 0.3), [(0.0, 500.0), (0.15, 1400.0), (0.3, 700.0)], 1.0)
    add(mix, shape(wing, [(0.0, 0.0), (0.08, 1.0), (0.3, 0.0)]), 0.0, 1.2)
    add(mix, crackles(rng, 0.35, 45.0, weight=0.6, freq=4200.0), 0.18, 1.0)
    sprout = shape(tone(0.3, [(0.0, 160.0), (0.3, 330.0)], (1.0, 0.7, 0.5, 0.3), (31.0, 0.04)), [(0.0, 0.0), (0.06, 1.0), (0.3, 0.0)])
    add(mix, band(sprout, 900.0, 0.9), 0.45, 0.7)
    add(mix, thud(150.0, 80.0, 0.18), 0.45, 0.5)
    return mix, 1.6


def zap(seconds, freq, wobble):
    """Zumbido elétrico: um dente de serra áspero com a altura tremendo rápido."""
    return tone(seconds, freq, (1.0, 0.6, 0.45, 0.35, 0.28, 0.22, 0.18), (wobble, 0.06))


def faisca_de_alga(rng):
    """Faísca de Alga: um estalo elétrico curto que chia pelas folhas e uma faísca aguda no
    fim."""
    length = 0.45
    mix = silence(length)
    buzz = shape(zap(0.3, [(0.0, 220.0), (0.3, 330.0)], 37.0), [(0.0, 0.0), (0.01, 1.0), (0.3, 0.0)])
    add(mix, high(buzz, 400.0), 0.0, 0.5)
    add(mix, crackles(rng, 0.3, 90.0, weight=0.8, freq=5000.0), 0.0, 1.0)
    add(mix, shape(band(noise(rng, 0.12), 6500.0, 1.5), [(0.0, 0.0), (0.005, 1.0), (0.12, 0.0)]), 0.0, 0.8)
    add(mix, ping(2600.0, 0.12, ((1.0, 1.0), (2.0, 0.3))), 0.28, 0.25)
    return mix, 1.8


def corrente_viva(rng):
    """Corrente Viva: a água correndo e uma corrente elétrica que zumbe e viaja, subindo de
    altura, com estalos pelo caminho."""
    length = 0.75
    flow = band(noise(rng, length), [(0.0, 700.0), (0.75, 1600.0)], 1.0)
    mix = shape(flutter(rng, flow, 18.0, 0.5), [(0.0, 0.0), (0.08, 1.0), (0.6, 0.8), (0.75, 0.0)])
    buzz = shape(zap(0.65, [(0.0, 150.0), (0.65, 300.0)], 29.0), [(0.0, 0.0), (0.06, 1.0), (0.55, 0.8), (0.65, 0.0)])
    add(mix, high(buzz, 300.0), 0.05, 0.45)
    add(mix, crackles(rng, 0.6, 50.0, weight=0.7, freq=4600.0), 0.08, 1.0)
    return mix, 1.9


def mare_eletrica(rng):
    """Maré Elétrica: uma onda que se espalha baixa e um zumbido elétrico grave que fica na
    água, com estalos esparsos."""
    length = 0.8
    wash = band(noise(rng, length), [(0.0, 400.0), (0.3, 1100.0), (0.8, 600.0)], 0.9)
    mix = shape(wash, [(0.0, 0.0), (0.15, 1.0), (0.5, 0.6), (0.8, 0.0)])
    hum = shape(zap(0.7, 110.0, 13.0), [(0.0, 0.0), (0.15, 1.0), (0.55, 0.7), (0.7, 0.0)])
    add(mix, band(hum, 700.0, 0.8), 0.1, 0.6)
    add(mix, crackles(rng, 0.65, 22.0, weight=0.6, freq=4000.0), 0.12, 1.0)
    return mix, 1.8


def desabamento(rng):
    """Desabamento: a pedra se soltando num estalo, um ronco que cai, as pedras batendo umas
    nas outras e o baque grande no fim."""
    length = 0.85
    mix = silence(length)
    add(mix, click(rng, 1400.0, 0.05, 1.5), 0.0, 1.2)
    rumble = shape(low(noise(rng, 0.7), [(0.0, 300.0), (0.7, 160.0)]), [(0.0, 0.0), (0.1, 1.0), (0.55, 0.8), (0.7, 0.0)])
    add(mix, rumble, 0.03, 1.4)
    for _ in range(9):
        at = rng.uniform(0.12, 0.6)
        add(mix, click(rng, rng.uniform(900.0, 2200.0), 0.04, 1.8), at, rng.uniform(0.5, 1.0))
        add(mix, thud(rng.uniform(180.0, 260.0), 90.0, 0.08), at, 0.4)
    add(mix, thud(130.0, 45.0, 0.25), 0.55, 1.6)
    add(mix, decay(low(noise(rng, 0.2), 700.0), 0.2, 0.002), 0.55, 1.0)
    return mix, 1.8


def abalo_profundo(rng):
    """Abalo Profundo: um ronco grave que vem do fundo e treme cada vez mais forte, o chão
    rachando num estalo seco e o baque que sacode tudo."""
    length = 0.9
    rumble = flutter(rng, low(noise(rng, length), 140.0, 1.2), 14.0, 0.7)
    mix = shape(rumble, [(0.0, 0.0), (0.4, 1.0), (0.6, 1.0), (0.9, 0.0)])
    add(mix, shape(tone(0.6, [(0.0, 42.0), (0.6, 55.0)], (1.0, 0.5)), [(0.0, 0.0), (0.3, 1.0), (0.6, 0.0)]), 0.1, 0.8)
    add(mix, crackles(rng, 0.25, 40.0, weight=0.8, freq=1800.0), 0.38, 1.0)
    add(mix, click(rng, 1100.0, 0.06, 1.2), 0.42, 1.4)
    add(mix, thud(110.0, 35.0, 0.35), 0.42, 1.8)
    return mix, 1.1


def tempestade_de_algas(rng):
    """Tempestade de Algas: a chuva chiando, o zumbido elétrico que cresce e o trovão que
    estala e ronca, com faíscas espalhadas."""
    length = 0.95
    rain = shape(band(noise(rng, length), 5200.0, 0.7), [(0.0, 0.0), (0.1, 1.0), (0.8, 0.8), (0.95, 0.0)])
    mix = flutter(rng, rain, 25.0, 0.4)
    buzz = shape(zap(0.3, [(0.0, 160.0), (0.3, 260.0)], 33.0), [(0.0, 0.0), (0.25, 1.0), (0.3, 0.0)])
    add(mix, high(buzz, 300.0), 0.0, 0.45)
    add(mix, decay(high(noise(rng, 0.12), 2500.0), 0.1, 0.001), 0.28, 1.6)
    thunder = shape(low(noise(rng, 0.6), [(0.0, 900.0), (0.6, 200.0)]), [(0.0, 0.0), (0.02, 1.0), (0.2, 0.7), (0.6, 0.0)])
    add(mix, flutter(rng, thunder, 20.0, 0.6), 0.29, 1.4)
    add(mix, crackles(rng, 0.6, 45.0, weight=0.7, freq=4800.0), 0.3, 1.0)
    return mix, 1.4


def esguicho(rng):
    """Esguicho: um esguicho fino e rápido de água, que chia e sobe de altura, e o respingo
    com gotas no fim."""
    length = 0.5
    mix = silence(length)
    squirt = band(noise(rng, 0.3), [(0.0, 2800.0), (0.3, 4200.0)], 1.6)
    add(mix, flutter(rng, shape(squirt, [(0.0, 0.0), (0.015, 1.0), (0.24, 0.8), (0.3, 0.0)]), 40.0, 0.4), 0.0, 1.0)
    add(mix, decay(band(noise(rng, 0.16), 1700.0, 0.8), 0.14, 0.003), 0.28, 0.9)
    for _ in range(6):
        add(mix, bubble(rng.uniform(1600.0, 2800.0), 0.03), rng.uniform(0.3, 0.45), 0.3)
    return mix, 1.3


def poca_d_agua(rng):
    """Poça d'Água: a água caindo e se espalhando pelo chão num chiado largo, e as gotas
    pingando na poça."""
    length = 0.75
    pour = band(noise(rng, 0.45), [(0.0, 900.0), (0.45, 1800.0)], 0.8)
    mix = shape(flutter(rng, pour, 22.0, 0.5), [(0.0, 0.0), (0.05, 1.0), (0.3, 0.7), (0.45, 0.0)])
    mix += silence(length - 0.45)
    add(mix, decay(low(noise(rng, 0.2), 600.0), 0.18, 0.003), 0.05, 0.9)
    for _ in range(7):
        add(mix, bubble(rng.uniform(900.0, 1900.0), rng.uniform(0.04, 0.07)), rng.uniform(0.25, 0.68), rng.uniform(0.35, 0.7))
    return mix, 1.3


def laco_de_raizes(rng):
    """Laço de Raízes: as raízes brotando num farfalhar de terra, rangendo enquanto se
    enrolam e subindo de altura, e o aperto num estalo de madeira."""
    length = 0.7
    mix = silence(length)
    soil = flutter(rng, band(noise(rng, 0.2), 1200.0, 0.8), 35.0, 0.7)
    add(mix, shape(soil, [(0.0, 0.0), (0.03, 1.0), (0.2, 0.0)]), 0.0, 0.8)
    creak = shape(tone(0.4, [(0.0, 120.0), (0.4, 230.0)], (1.0, 0.7, 0.5, 0.35), (19.0, 0.06)), [(0.0, 0.0), (0.06, 1.0), (0.34, 0.9), (0.4, 0.0)])
    add(mix, band(creak, 700.0, 0.9), 0.1, 0.8)
    rustle = flutter(rng, band(noise(rng, 0.35), 3600.0, 1.0), 45.0, 0.8)
    add(mix, shape(rustle, [(0.0, 0.0), (0.05, 1.0), (0.35, 0.0)]), 0.12, 0.4)
    add(mix, click(rng, 1600.0, 0.05, 2.0), 0.5, 1.3)
    add(mix, thud(190.0, 90.0, 0.14), 0.5, 0.6)
    return mix, 1.7


def brotar(rng):
    """Brotar: um farfalhar macio de folhas abrindo e notas claras que sobem, uma a uma,
    como brotos crescendo."""
    length = 0.75
    rustle = flutter(rng, band(noise(rng, 0.5), 3000.0, 0.9), 35.0, 0.7)
    mix = shape(rustle, [(0.0, 0.0), (0.08, 1.0), (0.5, 0.0)]) + silence(length - 0.5)
    for index, freq in enumerate([PENTATONIC[0], PENTATONIC[2], PENTATONIC[3], PENTATONIC[5]]):
        add(mix, ping(freq, 0.3, ((1.0, 1.0), (2.0, 0.2))), 0.08 + index * 0.11, 0.35)
    return mix, 1.3


def semear_jardim(rng):
    """Semear Jardim: as sementes caindo na terra em batidinhas, a terra se mexendo e um
    acorde claro que se abre, como o jardim brotando."""
    length = 0.85
    mix = silence(length)
    for _ in range(10):
        at = rng.uniform(0.0, 0.3)
        add(mix, click(rng, rng.uniform(1800.0, 3200.0), 0.02, 1.5), at, rng.uniform(0.4, 0.8))
    soil = shape(low(noise(rng, 0.3), 700.0), [(0.0, 0.0), (0.05, 1.0), (0.3, 0.0)])
    add(mix, soil, 0.2, 0.7)
    for index, freq in enumerate([G4, B4, D5, G5_]):
        add(mix, ping(freq, 0.45, ((1.0, 1.0), (2.0, 0.25), (3.0, 0.1))), 0.32 + index * 0.06, 0.3)
    return mix, 1.3


def lama_grudenta(rng):
    """Lama Grudenta: a lama arremessada num chiado molhado, o espalhar pesado no chão e as
    bolhas grossas estourando devagar."""
    length = 0.8
    mix = silence(length)
    throw = band(noise(rng, 0.2), [(0.0, 900.0), (0.2, 1800.0)], 0.9)
    add(mix, shape(throw, [(0.0, 0.0), (0.03, 1.0), (0.2, 0.0)]), 0.0, 0.7)
    splat = decay(low(noise(rng, 0.3), 500.0), 0.28, 0.003)
    add(mix, splat, 0.16, 1.4)
    add(mix, thud(150.0, 60.0, 0.2), 0.16, 0.8)
    for _ in range(9):
        add(mix, bubble(rng.uniform(180.0, 420.0), rng.uniform(0.05, 0.09)), rng.uniform(0.25, 0.7), rng.uniform(0.5, 1.0))
    return mix, 1.6


def areia_movedica(rng):
    """Areia Movediça: a areia escorrendo num chiado que gira e afunda, com grãos batendo e
    a sucção grave no fim."""
    length = 0.85
    pour = band(noise(rng, length), [(0.0, 4200.0), (0.7, 1500.0)], 0.8)
    pour = flutter(rng, pour, 9.0, 0.6)
    mix = shape(pour, [(0.0, 0.0), (0.1, 1.0), (0.6, 0.8), (0.85, 0.0)])
    add(mix, crackles(rng, 0.6, 35.0, weight=0.5, freq=3000.0), 0.05, 1.0)
    suck = shape(tone(0.3, [(0.0, 160.0), (0.3, 55.0)], (1.0, 0.4)), [(0.0, 0.0), (0.08, 1.0), (0.3, 0.0)])
    add(mix, suck, 0.5, 0.9)
    return mix, 1.5


def chao_de_geada(rng):
    """Chão de Geada: o gelo se espalhando pelo chão em estalinhos que correm, um chiado
    frio e notas de cristal no fim."""
    length = 0.75
    hiss = shape(high(noise(rng, length), 5500.0), [(0.0, 0.0), (0.1, 1.0), (0.5, 0.6), (0.75, 0.0)])
    mix = flutter(rng, hiss, 30.0, 0.4)
    add(mix, crackles(rng, 0.5, 80.0, weight=0.8, freq=6000.0), 0.0, 1.0)
    for index, freq in enumerate([2349.3, 3136.0, 2637.0]):
        add(mix, ping(freq, 0.22, ((1.0, 1.0), (2.76, 0.3))), 0.4 + index * 0.07, 0.25)
    return mix, 1.4


def espinho_venenoso(rng):
    """Espinho Venenoso: o espinho furando num estalo seco e o veneno borbulhando e chiando
    em seguida."""
    length = 0.55
    mix = silence(length)
    add(mix, band(noise(rng, 0.06), [(0.0, 5000.0), (0.06, 2500.0)], 2.0), 0.0, 0.8)
    add(mix, click(rng, 2200.0, 0.04, 2.0), 0.05, 1.3)
    add(mix, thud(220.0, 100.0, 0.1), 0.05, 0.6)
    fizz = shape(band(noise(rng, 0.4), 3800.0, 1.2), [(0.0, 0.0), (0.04, 1.0), (0.4, 0.0)])
    add(mix, flutter(rng, fizz, 40.0, 0.6), 0.1, 0.5)
    for _ in range(8):
        add(mix, bubble(rng.uniform(500.0, 1100.0), rng.uniform(0.03, 0.06)), rng.uniform(0.12, 0.45), rng.uniform(0.4, 0.8))
    return mix, 1.5


def poca_toxica(rng):
    """Poça Tóxica: o veneno grosso derramando e se espalhando no chão, e bolhas pesadas
    estourando com um chiado ácido."""
    length = 0.75
    pour = band(noise(rng, 0.42), [(0.0, 600.0), (0.42, 1100.0)], 0.9)
    mix = shape(flutter(rng, pour, 18.0, 0.6), [(0.0, 0.0), (0.05, 1.0), (0.3, 0.6), (0.42, 0.0)])
    mix += silence(length - 0.42)
    add(mix, decay(low(noise(rng, 0.2), 450.0), 0.18, 0.003), 0.05, 0.8)
    fizz = shape(band(noise(rng, 0.45), 4200.0, 1.4), [(0.0, 0.0), (0.06, 1.0), (0.45, 0.0)])
    add(mix, flutter(rng, fizz, 35.0, 0.6), 0.2, 0.35)
    for _ in range(7):
        add(mix, bubble(rng.uniform(320.0, 800.0), rng.uniform(0.05, 0.09)), rng.uniform(0.2, 0.66), rng.uniform(0.45, 0.85))
    return mix, 1.4


def pena_sombria(rng):
    """Pena Sombria: a pena escura cortando o ar num "fiu" mais grave, um zumbido sombrio
    que vai junto e o tique quando ela crava."""
    length = 0.5
    mix = silence(length)
    dart = band(noise(rng, 0.26), [(0.0, 1800.0), (0.26, 4200.0)], 2.5)
    add(mix, shape(dart, [(0.0, 0.0), (0.03, 1.0), (0.18, 0.5), (0.26, 0.0)]), 0.0, 1.3)
    dark = [a + b for a, b in zip(tone(0.3, 140.0, (1.0, 0.4)), tone(0.3, 147.0, (1.0, 0.4)))]
    add(mix, shape(dark, [(0.0, 0.0), (0.05, 0.6), (0.3, 0.0)]), 0.0, 0.35)
    add(mix, click(rng, 3200.0, 0.06), 0.26, 0.9)
    add(mix, decay(band(noise(rng, 0.15), 900.0, 1.2), 0.1, 0.002), 0.26, 0.4)
    return mix, 1.6


def olhar_da_lua(rng):
    """Olhar da Lua: um brilho frio que se acende em notas de vidro, um tom trêmulo e
    estranho que prende e um anel que se abre e some."""
    length = 0.7
    mix = silence(length)
    for index, freq in enumerate((1568.0, 2093.0, 2637.0)):
        add(mix, ping(freq, 0.3, ((1.0, 1.0), (2.76, 0.25))), index * 0.05, 0.3)
    stare = tone(0.45, [(0.0, 660.0), (0.45, 620.0)], (1.0, 0.3, 0.15), (7.0, 0.02))
    add(mix, shape(stare, [(0.0, 0.0), (0.06, 0.7), (0.35, 0.6), (0.45, 0.0)]), 0.08, 0.4)
    ring = band(noise(rng, 0.4), [(0.0, 5000.0), (0.4, 2200.0)], 3.0)
    add(mix, shape(ring, [(0.0, 0.0), (0.05, 1.0), (0.4, 0.0)]), 0.25, 0.35)
    add(mix, shape(tone(0.5, 98.0, (1.0, 0.4)), [(0.0, 0.0), (0.1, 0.5), (0.5, 0.0)]), 0.15, 0.35)
    return mix, 1.4


def voo_silencioso(rng):
    """Voo Silencioso: duas batidas de asa abafadas, quase sem som, e notas escuras e
    baixas que sobem, a coruja se preparando."""
    length = 0.7
    mix = silence(length)
    for at in (0.0, 0.22):
        wing = low(noise(rng, 0.2), [(0.0, 300.0), (0.1, 900.0), (0.2, 300.0)])
        add(mix, shape(wing, [(0.0, 0.0), (0.08, 1.0), (0.2, 0.0)]), at, 0.9)
    for index, freq in enumerate((392.0, 466.2, 587.3)):
        add(mix, low(ping(freq, 0.22), 1600.0), 0.3 + index * 0.1, 0.35)
    add(mix, shape(band(noise(rng, 0.5), 2500.0, 1.0), [(0.0, 0.0), (0.2, 1.0), (0.5, 0.0)]), 0.15, 0.08)
    return mix, 1.6


def eclipse_lunar(rng):
    """Eclipse Lunar: a luz sendo puxada para dentro, um zumbido grave que cresce e
    desafina, e a escuridão estourando num baque fundo com um anel que some."""
    length = 0.8
    mix = silence(length)
    pull = band(noise(rng, 0.3), [(0.0, 3000.0), (0.3, 400.0)], 1.5)
    add(mix, shape(pull, [(0.0, 0.0), (0.25, 1.0), (0.3, 0.0)]), 0.0, 0.7)
    drone = [a + b for a, b in zip(tone(0.6, [(0.0, 70.0), (0.6, 60.0)], (1.0, 0.5, 0.3)), tone(0.6, [(0.0, 74.0), (0.6, 62.0)], (1.0, 0.5, 0.3)))]
    add(mix, shape(low(drone, 800.0), [(0.0, 0.0), (0.28, 1.0), (0.6, 0.0)]), 0.05, 0.7)
    add(mix, thud(110.0, 35.0, 0.3), 0.3, 1.3)
    add(mix, decay(low(noise(rng, 0.3), 500.0), 0.25, 0.002), 0.3, 0.8)
    ring = band(noise(rng, 0.4), [(0.0, 2400.0), (0.4, 900.0)], 2.0)
    add(mix, shape(ring, [(0.0, 0.0), (0.04, 1.0), (0.4, 0.0)]), 0.32, 0.3)
    return mix, 1.0


def bote(rng):
    """Bote: um chiado curto de cobra, o avanço num sopro rápido e as presas fechando num
    estalo seco com um baque."""
    length = 0.45
    mix = silence(length)
    hiss = shape(high(noise(rng, 0.16), 4000.0), [(0.0, 0.0), (0.03, 1.0), (0.12, 0.8), (0.16, 0.0)])
    add(mix, hiss, 0.0, 0.5)
    lunge = band(noise(rng, 0.1), [(0.0, 800.0), (0.1, 2600.0)], 1.5)
    add(mix, shape(lunge, [(0.0, 0.0), (0.06, 1.0), (0.1, 0.0)]), 0.12, 1.0)
    add(mix, click(rng, 3600.0, 0.02, 1.5), 0.21, 1.8)
    add(mix, click(rng, 5000.0, 0.015, 1.5), 0.225, 1.1)
    add(mix, thud(180.0, 60.0, 0.14), 0.21, 1.2)
    return mix, 2.0


def presa_venenosa(rng):
    """Presa Venenosa: as presas cravando num estalo duplo com um baque, e o veneno
    entrando num borbulhar grosso que chia."""
    length = 0.55
    mix = silence(length)
    add(mix, band(noise(rng, 0.05), [(0.0, 2500.0), (0.05, 4500.0)], 2.0), 0.0, 0.6)
    add(mix, click(rng, 3000.0, 0.02, 1.5), 0.05, 1.7)
    add(mix, click(rng, 4400.0, 0.015, 1.5), 0.066, 1.1)
    add(mix, thud(160.0, 55.0, 0.14), 0.05, 1.2)
    fizz = shape(band(noise(rng, 0.38), 3400.0, 1.2), [(0.0, 0.0), (0.04, 1.0), (0.38, 0.0)])
    add(mix, flutter(rng, fizz, 38.0, 0.6), 0.12, 0.45)
    for _ in range(6):
        add(mix, bubble(rng.uniform(380.0, 900.0), rng.uniform(0.04, 0.08)), rng.uniform(0.14, 0.46), rng.uniform(0.4, 0.8))
    return mix, 1.7


def constricao(rng):
    """Constrição: o corpo da cobra deslizando em escamas e se enrolando, o aperto num
    rangido que cresce e o estalo no fim."""
    length = 0.75
    mix = silence(length)
    slide = flutter(rng, band(noise(rng, 0.4), [(0.0, 1600.0), (0.4, 2600.0)], 1.2), 28.0, 0.7)
    add(mix, shape(slide, [(0.0, 0.0), (0.06, 1.0), (0.32, 0.8), (0.4, 0.0)]), 0.0, 0.8)
    squeeze = shape(tone(0.35, [(0.0, 90.0), (0.35, 150.0)], (1.0, 0.7, 0.5, 0.35), (17.0, 0.05)), [(0.0, 0.0), (0.1, 0.8), (0.3, 1.0), (0.35, 0.0)])
    add(mix, band(squeeze, 600.0, 0.9), 0.3, 0.9)
    add(mix, click(rng, 1400.0, 0.05, 2.0), 0.64, 1.2)
    add(mix, thud(150.0, 70.0, 0.1), 0.64, 0.6)
    return mix, 1.7


def cuspe_acido(rng):
    """Cuspe Ácido: um chiado de cobra, o cuspe saindo num sopro molhado e o ácido
    espirrando e chiando no alvo."""
    length = 0.6
    mix = silence(length)
    add(mix, shape(high(noise(rng, 0.12), 4500.0), [(0.0, 0.0), (0.03, 1.0), (0.12, 0.0)]), 0.0, 0.45)
    spit = band(noise(rng, 0.12), [(0.0, 900.0), (0.12, 2400.0)], 1.4)
    add(mix, shape(spit, [(0.0, 0.0), (0.02, 1.0), (0.12, 0.0)]), 0.1, 1.1)
    add(mix, decay(band(noise(rng, 0.12), 1400.0, 1.0), 0.1, 0.002), 0.24, 0.8)
    acid = shape(band(noise(rng, 0.34), 4800.0, 1.4), [(0.0, 0.0), (0.03, 1.0), (0.34, 0.0)])
    add(mix, flutter(rng, acid, 45.0, 0.6), 0.25, 0.55)
    for _ in range(5):
        add(mix, bubble(rng.uniform(700.0, 1400.0), rng.uniform(0.03, 0.05)), rng.uniform(0.28, 0.55), rng.uniform(0.35, 0.6))
    return mix, 1.6


def golpe_de_foice(rng):
    """Golpe de Foice: um "shing" de lâmina, o corte rápido que desce em diagonal e o
    impacto seco com estilhaços."""
    length = 0.5
    mix = silence(length)
    add(mix, ping(3600.0, 0.12, ((1.0, 1.0), (1.47, 0.6), (2.31, 0.3))), 0.0, 0.35)
    cut = band(noise(rng, 0.16), [(0.0, 5200.0), (0.16, 1100.0)], 2.5)
    add(mix, shape(cut, [(0.0, 0.0), (0.03, 1.0), (0.16, 0.0)]), 0.03, 1.4)
    add(mix, click(rng, 2600.0, 0.03, 1.5), 0.17, 1.2)
    add(mix, thud(200.0, 80.0, 0.12), 0.17, 0.8)
    add(mix, crackles(rng, length, 60.0, 0.18, 0.4), 0.0, 0.6)
    return mix, 1.7


def emboscada(rng):
    """Emboscada: um silêncio tenso com folhas mexendo de leve, o bote rápido num sopro
    e duas foices fechando com força."""
    length = 0.6
    mix = silence(length)
    rustle = flutter(rng, band(noise(rng, 0.25), 3200.0, 1.0), 30.0, 0.8)
    add(mix, shape(rustle, [(0.0, 0.0), (0.08, 1.0), (0.25, 0.0)]), 0.0, 0.25)
    lunge = band(noise(rng, 0.1), [(0.0, 700.0), (0.1, 3200.0)], 1.5)
    add(mix, shape(lunge, [(0.0, 0.0), (0.07, 1.0), (0.1, 0.0)]), 0.24, 1.1)
    for at in (0.33, 0.37):
        slash = band(noise(rng, 0.1), [(0.0, 4200.0), (0.1, 900.0)], 2.5)
        add(mix, decay(slash, 0.1, 0.002), at, 1.2)
    add(mix, thud(170.0, 60.0, 0.16), 0.34, 1.2)
    return mix, 1.8


def danca_da_foice(rng):
    """Dança da Foice: as foices afiando uma na outra em dois raspados metálicos, um
    tinido que fica e notas que sobem, o Ataque crescendo."""
    length = 0.75
    mix = silence(length)
    for at in (0.0, 0.18):
        scrape = band(noise(rng, 0.14), [(0.0, 3000.0), (0.14, 6500.0)], 3.0)
        add(mix, shape(scrape, [(0.0, 0.0), (0.04, 1.0), (0.14, 0.0)]), at, 0.9)
        add(mix, ping(4200.0, 0.2, ((1.0, 1.0), (1.47, 0.5))), at + 0.12, 0.25)
    for index, freq in enumerate((784.0, 988.0, 1175.0, 1568.0)):
        add(mix, ping(freq, 0.18), 0.36 + index * 0.08, 0.28)
    return mix, 1.6


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
    "uivo": uivo,
    "patada": patada,
    "olhar_manhoso": olhar_manhoso,
    "lufada_cortante": lufada_cortante,
    "danca_do_vento": danca_do_vento,
    "ciclone": ciclone,
    "lamina_sombria": lamina_sombria,
    "pinca_de_aco": pinca_de_aco,
    "garra_de_picareta": garra_de_picareta,
    "beliscao": beliscao,
    "couraca": couraca,
    "geada_silenciosa": geada_silenciosa,
    "nuvem_de_poeira": nuvem_de_poeira,
    "floco_cortante": floco_cortante,
    "arremesso_de_torrao": arremesso_de_torrao,
    "manto_de_neve": manto_de_neve,
    "eco_mental": eco_mental,
    "garra_de_pedra": garra_de_pedra,
    "garra_do_eclipse": garra_do_eclipse,
    "martelo_de_ferro": martelo_de_ferro,
    "lanca_de_cristal": lanca_de_cristal,
    "inverno_mudo": inverno_mudo,
    "grito_congelado": grito_congelado,
    "palavra_guardada": palavra_guardada,
    "pena_afiada": pena_afiada,
    "vento_a_favor": vento_a_favor,
    "rajada_de_penas": rajada_de_penas,
    "nuvem_de_penas": nuvem_de_penas,
    "vendaval": vendaval,
    "rasante": rasante,
    "bicada_de_folha": bicada_de_folha,
    "garra_de_espinho": garra_de_espinho,
    "asa_semeadora": asa_semeadora,
    "faisca_de_alga": faisca_de_alga,
    "corrente_viva": corrente_viva,
    "mare_eletrica": mare_eletrica,
    "desabamento": desabamento,
    "abalo_profundo": abalo_profundo,
    "tempestade_de_algas": tempestade_de_algas,
    "esguicho": esguicho,
    "poca_d_agua": poca_d_agua,
    "laco_de_raizes": laco_de_raizes,
    "brotar": brotar,
    "semear_jardim": semear_jardim,
    "lama_grudenta": lama_grudenta,
    "areia_movedica": areia_movedica,
    "chao_de_geada": chao_de_geada,
    "espinho_venenoso": espinho_venenoso,
    "poca_toxica": poca_toxica,
    "pena_sombria": pena_sombria,
    "olhar_da_lua": olhar_da_lua,
    "voo_silencioso": voo_silencioso,
    "eclipse_lunar": eclipse_lunar,
    "bote": bote,
    "presa_venenosa": presa_venenosa,
    "constricao": constricao,
    "cuspe_acido": cuspe_acido,
    "golpe_de_foice": golpe_de_foice,
    "emboscada": emboscada,
    "danca_da_foice": danca_da_foice,
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
