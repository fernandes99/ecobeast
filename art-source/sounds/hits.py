"""Gera os sons de dano da luta (board-battle/09): normal, super efetivo e pouco
efetivo. Tudo é síntese, sem gravação de terceiros. O dono mandou um som de outro
jogo como referência do super efetivo; dele só se tirou o jeito (um impacto largo,
com grave e um ruído médio "crocante", uma leve trepidação e um ronco que some),
nunca a onda.

Cada som soma três peças:
- a pancada: um seno cujo tom cai rápido, como um bumbo;
- o ruído: ruído branco num filtro passa-banda, que dá o estalo;
- no super efetivo, uma trepidação no volume, um segundo impacto e um ronco grave.

Uso, na raiz do repositório: python -I art-source/sounds/hits.py
Escreve client/assets/sounds/hits/{normal,super,weak}.wav (44,1 kHz, mono, 16 bits).
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "client/assets/sounds/hits"


def thump(seconds, start_hz, end_hz, decay, sweep=0.04):
    """Seno com o tom caindo de start_hz para end_hz em `sweep` segundos."""
    out = []
    phase = 0.0
    for index in range(int(seconds * RATE)):
        t = index / RATE
        freq = end_hz + (start_hz - end_hz) * math.exp(-t / sweep)
        phase += 2.0 * math.pi * freq / RATE
        out.append(math.sin(phase) * math.exp(-t / decay) * min(1.0, t / 0.002))
    return out


def band_noise(seconds, start_hz, end_hz, decay, random_source, q=1.0):
    """Ruído branco num passa-banda (biquad RBJ) com o centro deslizando."""
    count = int(seconds * RATE)
    out = []
    x1 = x2 = y1 = y2 = 0.0
    for index in range(count):
        t = index / RATE
        freq = start_hz * (end_hz / start_hz) ** (index / max(1, count - 1))
        w = 2.0 * math.pi * freq / RATE
        alpha = math.sin(w) / (2.0 * q)
        a0, a1, a2 = 1.0 + alpha, -2.0 * math.cos(w), 1.0 - alpha
        x = random_source.uniform(-1.0, 1.0)
        y = (alpha * x - alpha * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1 = x1, x
        y2, y1 = y1, y
        out.append(y * math.exp(-t / decay) * min(1.0, t / 0.001))
    return out


def low_noise(seconds, cutoff_hz, decay, random_source):
    """Ruído num passa-baixa de um polo: o ronco."""
    out = []
    y = 0.0
    k = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / RATE)
    for index in range(int(seconds * RATE)):
        t = index / RATE
        y += k * (random_source.uniform(-1.0, 1.0) - y)
        out.append(y * math.exp(-t / decay) * min(1.0, t / 0.01))
    return out


def mix(length, *layers):
    """Cada camada: (amostras, começo em segundos, ganho)."""
    out = [0.0] * int(length * RATE)
    for samples, start, gain in layers:
        first = int(start * RATE)
        for index, value in enumerate(samples):
            if first + index < len(out):
                out[first + index] += value * gain
    return out


def saturate(samples, drive):
    return [math.tanh(v * drive) for v in samples]


def tremble(samples, hz, depth, until):
    """A trepidação: o volume oscila no começo e para em `until` segundos."""
    out = []
    for index, value in enumerate(samples):
        t = index / RATE
        amount = depth * max(0.0, 1.0 - t / until)
        out.append(value * (1.0 - amount * (0.5 + 0.5 * math.sin(2.0 * math.pi * hz * t))))
    return out


def fade_tail(samples, seconds=0.02):
    count = int(seconds * RATE)
    for index in range(count):
        samples[-1 - index] *= index / count
    return samples


def write(name, samples, peak):
    loudest = max(abs(v) for v in samples) or 1.0
    frames = b"".join(struct.pack("<h", int(v / loudest * peak * 32767)) for v in samples)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / ("%s.wav" % name)), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)
    print("ok: %s.wav  %.2f s  pico %.2f" % (name, len(samples) / RATE, peak))


def normal(random_source):
    """Um golpe seco: pancada média e um estalo curto."""
    body = mix(0.25,
               (thump(0.25, 190.0, 75.0, 0.07), 0.0, 1.0),
               (band_noise(0.12, 2200.0, 900.0, 0.035, random_source), 0.0, 0.55))
    return fade_tail(saturate(body, 1.6))


def super_effective(random_source):
    """Um impacto largo: pancada grave, ruído médio crocante que treme, um segundo
    impacto logo depois e um ronco que some."""
    body = mix(0.62,
               (thump(0.5, 230.0, 48.0, 0.16, sweep=0.06), 0.0, 1.0),
               (band_noise(0.4, 2400.0, 700.0, 0.12, random_source, q=0.8), 0.0, 0.75),
               (thump(0.3, 180.0, 60.0, 0.08), 0.07, 0.6),
               (band_noise(0.2, 1600.0, 800.0, 0.06, random_source), 0.07, 0.4),
               (low_noise(0.55, 140.0, 0.2, random_source), 0.02, 0.9))
    body = tremble(body, 24.0, 0.45, 0.3)
    return fade_tail(saturate(body, 2.6))


def weak(random_source):
    """Uma batida abafada: pancada mais aguda e curta, ruído grave, sem saturar."""
    body = mix(0.18,
               (thump(0.18, 300.0, 170.0, 0.035, sweep=0.02), 0.0, 1.0),
               (band_noise(0.08, 700.0, 400.0, 0.025, random_source, q=1.5), 0.0, 0.35))
    return fade_tail(body)


source = random.Random(2026)
write("normal", normal(source), 0.62)
write("super", super_effective(source), 0.85)
write("weak", weak(source), 0.4)
