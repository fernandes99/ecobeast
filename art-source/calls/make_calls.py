"""Gera o som característico de cada Ecobeast (creature-sounds/03), no mesmo chip de
videogame antigo do Ruvo (art-source/ruvo/call.py): pulsos, um triângulo de 16 degraus,
ruído de registrador LFSR, tudo calculado a 11 025 Hz e com 64 degraus de volume.

Cada som tem sílabas que lembram o nome, um efeito do Elemento por cima (brasa, bolhas,
vento, gelo, choque, zumbido...) e o jeito do Ecobeast; numa linha, a Evolução fica mais
grave e mais longa. Nada imita um bicho de verdade, e nada é gravado.

Uso, na raiz do repositório:
    python -I art-source/calls/make_calls.py            (todos)
    python -I art-source/calls/make_calls.py crag ingot (só estes)
Escreve client/assets/creatures/<slug>/call.wav (44,1 kHz, mono, 16 bits).
O Ruvo continua no script dele.
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 44100
HOLD = 4
CHIP_RATE = RATE / HOLD
PEAK = 0.7
LEVELS = 64
CREATURES = Path(__file__).resolve().parents[2] / "client/assets/creatures"

_NOTES = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}


def n(name):
    """A frequência de uma nota: "A4" é 440 Hz; aceita "C#5" e "Bb3"."""
    semitones = _NOTES[name[0]]
    rest = name[1:]
    if rest[0] == "#":
        semitones += 1
        rest = rest[1:]
    elif rest[0] == "b":
        semitones -= 1
        rest = rest[1:]
    return 440.0 * 2.0 ** ((semitones + (int(rest) - 4) * 12) / 12.0)


def pulse(phase, duty):
    return 1.0 if phase % 1.0 < duty else -1.0


def triangle(phase):
    return round((1.0 - 4.0 * abs(phase % 1.0 - 0.5)) * 7.5) / 7.5


def glide(freqs, progress):
    if len(freqs) == 1:
        return freqs[0]
    segment = progress * (len(freqs) - 1)
    k = min(int(segment), len(freqs) - 2)
    return freqs[k] * (freqs[k + 1] / freqs[k]) ** (segment - k)


def envelope(t, length, attack, release, sustain, decay):
    if t < 0.0 or t >= length:
        return 0.0
    level = min(1.0, t / attack) if attack > 0.0 else 1.0
    level *= 1.0 - (1.0 - sustain) * (t / length)
    if decay:
        level *= (1.0 - t / length) ** decay
    if t > length - release:
        level *= max(0.0, (length - t) / release)
    return level


class Lfsr:
    def __init__(self, short):
        self.state = 1
        self.tap = 6 if short else 1

    def step(self):
        bit = (self.state ^ (self.state >> self.tap)) & 1
        self.state = (self.state >> 1) | (bit << 14)
        return 1.0 if self.state & 1 else -1.0


class Call:
    def __init__(self, length, gain=1.0, echo=(), seed=1):
        self.chip = [0.0] * int(length * CHIP_RATE)
        self.gain = gain
        self.echo = echo
        self.random = random.Random(seed)

    def _span(self, start, length):
        first = int(start * CHIP_RATE)
        return first, min(len(self.chip), first + int(length * CHIP_RATE))

    def tone(self, start, length, freqs, duty=0.25, weight=0.9, attack=0.006, release=None,
             sustain=0.8, decay=0.0, vibrato=(0.0, 0.0), tremolo=(0.0, 0.0), arp=None,
             tri=0.45, wave="pulse", double=0.0):
        """Uma nota de `freqs` (deslizando entre os pontos), com o triângulo uma oitava abaixo.

        duty pode ser uma tupla, trocada em partes iguais; arp é (semitons, passo em s);
        double soma uma segunda voz desafinada em `double` centésimos."""
        freqs = freqs if isinstance(freqs, (tuple, list)) else (freqs,)
        duties = duty if isinstance(duty, (tuple, list)) else (duty,)
        release = min(0.04, length / 3.0) if release is None else release
        first, last = self._span(start, length)
        phase = phase2 = 0.0
        for index in range(first, last):
            t = (index - first) / CHIP_RATE
            progress = t / length
            freq = glide(freqs, progress)
            if vibrato[0]:
                freq *= 1.0 + vibrato[1] * min(1.0, t / 0.1) * math.sin(2.0 * math.pi * vibrato[0] * t)
            if arp:
                freq *= 2.0 ** (arp[0][int(t / arp[1]) % len(arp[0])] / 12.0)
            phase += freq / CHIP_RATE
            level = envelope(t, length, attack, release, sustain, decay)
            if tremolo[0]:
                level *= 1.0 - tremolo[1] * (0.5 + 0.5 * math.sin(2.0 * math.pi * tremolo[0] * t))
            width = duties[min(len(duties) - 1, int(progress * len(duties)))]
            voice = pulse(phase, width) if wave == "pulse" else triangle(phase)
            sample = weight * voice
            if double:
                phase2 += freq * 2.0 ** (double / 1200.0) / CHIP_RATE
                sample += weight * 0.6 * (pulse(phase2, width) if wave == "pulse" else triangle(phase2))
            if tri:
                sample += tri * triangle(phase / 2.0)
            self.chip[index] += level * sample

    def noise(self, start, length, weight=0.25, step=3.0, step_to=None, short=False, attack=0.0, decay=2.0):
        """Ruído do LFSR: `step` amostras do chip por passo (maior é mais grave), deslizando até `step_to`."""
        lfsr = Lfsr(short)
        value = lfsr.step()
        clock = 0.0
        first, last = self._span(start, length)
        for index in range(first, last):
            progress = (index - first) / (length * CHIP_RATE)
            step_now = step if step_to is None else step + (step_to - step) * progress
            clock += 1.0 / step_now
            while clock >= 1.0:
                clock -= 1.0
                value = lfsr.step()
            if attack and progress < attack:
                level = progress / attack
            else:
                level = (1.0 - (progress - attack) / (1.0 - attack)) ** decay
            self.chip[index] += weight * level * value

    def write(self, slug):
        out = list(self.chip)
        for delay, gain in self.echo:
            offset = int(delay * CHIP_RATE)
            for index in range(len(self.chip) - offset):
                out[index + offset] += gain * self.chip[index]
        loudest = max(abs(sample) for sample in out) or 1.0
        top = LEVELS / 2 - 1
        out = [round(sample / loudest * top) / top for sample in out]
        frames = b"".join(struct.pack("<h", int(sample * PEAK * self.gain * 32767))
                          for sample in out for _ in range(HOLD))
        path = CREATURES / slug / "call.wav"
        with wave.open(str(path), "wb") as target:
            target.setnchannels(1)
            target.setsampwidth(2)
            target.setframerate(RATE)
            target.writeframes(frames)
        return path, len(out) / CHIP_RATE


# Os efeitos dos Elementos e os pedaços que se repetem.

def click(c, start, weight=0.4):
    c.noise(start, 0.012, weight, step=1, short=True, decay=3)


def hiss(c, start, length, weight=0.3):
    c.noise(start, length, weight, step=1, attack=0.25, decay=1.2)


def ember(c, start, length=0.05, weight=0.25, sparks=3, until=None):
    c.noise(start, length, weight, step=3, short=True, decay=2)
    end = until or start + 0.3
    for _ in range(sparks):
        at = c.random.uniform(start + length, end)
        c.noise(at, 0.01, weight * 0.6, step=1, decay=3)


def sparkle(c, start, end, count, weight=0.08):
    for _ in range(count):
        c.noise(c.random.uniform(start, end), 0.01, weight, step=1, decay=3)


def bubbles(c, start, count, gap=0.045, low=None, high=None, weight=0.45):
    low, high = low or n("C5"), high or n("C6")
    for i in range(count):
        c.tone(start + i * gap, 0.035, (low, high), weight=weight, wave="tri", tri=0.0, attack=0.002)


def glug(c, start, freq, weight=0.45):
    c.tone(start, 0.06, (freq * 1.5, freq * 0.75), weight=weight, wave="tri", tri=0.0, attack=0.002, decay=1.5)
    c.tone(start, 0.06, (freq * 1.5, freq * 0.75), duty=0.5, weight=weight * 0.3, tri=0.0, decay=1.5)


def rustle(c, start, length, weight=0.1):
    c.noise(start, length, weight, step=2, attack=0.3, decay=1.5)


def rumble(c, start, length, weight=0.18, step=12.0, step_to=None):
    c.noise(start, length, weight, step=step, step_to=step_to, attack=0.1, decay=1.0)


def gust(c, start, length, weight=0.22):
    c.noise(start, length, weight, step=8.0, step_to=1.5, attack=0.5, decay=1.0)


def zap(c, start, length=0.08, weight=0.5, high=None, low=None):
    c.tone(start, length, (high or n("D7"), low or n("A4")), duty=0.125, weight=weight,
           attack=0.001, decay=2, tri=0.0)
    c.noise(start, length, weight * 0.6, step=1, short=True, decay=3)


def tinkle(c, start, notes, gap=0.05, weight=0.35, length=0.09):
    for i, note in enumerate(notes):
        c.tone(start + i * gap, length, note, weight=weight, wave="tri", tri=0.0, attack=0.001, decay=2)


def blips(c, start, notes, gap, length, **options):
    for i, note in enumerate(notes):
        c.tone(start + i * gap, length, note, **options)


def bell(c, start, freq, length, weight=0.4):
    """Um anel de metal: parciais fora da série harmônica, caindo depressa."""
    for ratio, share in ((1.0, 1.0), (2.76, 0.5), (5.4, 0.25)):
        if freq * ratio < 5000.0:
            c.tone(start, length, freq * ratio, duty=0.5, weight=weight * share, attack=0.001,
                   release=0.01, sustain=1.0, decay=3, tri=0.0)


def buzz(c, start, length, freq, weight=0.3, rate=55.0):
    c.tone(start, length, freq, duty=0.125, weight=weight, tremolo=(rate, 0.8), tri=0.0)


CALLS = {}


def call(slug, length, **options):
    def register(design):
        CALLS[slug] = (length, options, design)
        return design
    return register


# Linha do Ruvo (Fogo). O Ruvo está em art-source/ruvo/call.py.

@call("ruvak", 0.44)
def ruvak(c):
    """"ru-vak": mais grave que o Ruvo, o "vak" cai depressa e estala no "k"."""
    c.tone(0.0, 0.08, (n("C#4"), n("D#4")), weight=0.9)
    c.tone(0.09, 0.2, (n("F#4"), n("F#4"), n("C#4")), duty=(0.25, 0.125), vibrato=(14.0, 0.015), sustain=0.6)
    ember(c, 0.09, 0.06, 0.3, sparks=4, until=0.42)
    click(c, 0.27, 0.45)


@call("ruvaroth", 0.8)
def ruvaroth(c):
    """"ru-va-roth": grave e longo, o "roth" oco e desafinado (a chama escura), brasa e ronco."""
    c.tone(0.0, 0.1, (n("A3"), n("B3")), weight=0.9)
    c.tone(0.11, 0.13, n("D4"))
    c.tone(0.26, 0.5, (n("C#4"), n("A3"), n("F#3")), duty=0.5, double=18.0, vibrato=(6.0, 0.02),
           sustain=0.5, release=0.15, tri=0.6)
    ember(c, 0.11, 0.06, 0.3, sparks=5, until=0.75)
    rumble(c, 0.26, 0.45, 0.18)


# Linha da Nilu (Água).

@call("nilu", 0.34, gain=0.85)
def nilu(c):
    """"ni-lu": agudo e macio, de triângulo, tímido, com duas bolhas no fim."""
    for weight, wave, duty in ((1.0, "tri", 0.25), (0.3, "pulse", 0.125)):
        c.tone(0.0, 0.08, (n("E5"), n("G5")), weight=weight, wave=wave, duty=duty, tri=0.0)
        c.tone(0.1, 0.16, (n("A5"), n("E5")), weight=weight * 0.9, wave=wave, duty=duty,
               vibrato=(10.0, 0.01), tri=0.0)
    bubbles(c, 0.22, 2)


@call("nilgar", 0.5)
def nilgar(c):
    """"nil-gar": a garra estala no começo do "gar", e as bolhas sobem no fim."""
    c.tone(0.0, 0.1, (n("A4"), n("C5")))
    c.tone(0.12, 0.28, (n("E4"), n("E4"), n("C#4")), duty=0.5, vibrato=(11.0, 0.012), tri=0.55)
    click(c, 0.12, 0.5)
    bubbles(c, 0.4, 2, low=n("A4"), high=n("A5"))


@call("nilgorr", 0.78)
def nilgorr(c):
    """"nil-gorrr": o "r" rolado pelo tremolo, o casco de metal soando e a água no fundo."""
    c.tone(0.0, 0.1, (n("E4"), n("G4")))
    c.tone(0.12, 0.56, (n("B3"), n("A3"), n("E3")), duty=0.5, tremolo=(28.0, 0.6), tri=0.6, sustain=0.6)
    bell(c, 0.12, n("E5"), 0.4, 0.3)
    bubbles(c, 0.62, 2, low=n("G4"), high=n("G5"), weight=0.35)
    rumble(c, 0.12, 0.5, 0.12)


# Linha do Seedlet (Flora).

@call("seedlet", 0.38)
def seedlet(c):
    """"see-dlet" contente, e a cauda abrindo como broto num arpejo que sobe."""
    c.tone(0.0, 0.1, (n("G5"), n("B5")), duty=0.125)
    c.tone(0.12, 0.08, (n("D6"), n("B5")))
    tinkle(c, 0.22, (n("G5"), n("B5"), n("D6")), gap=0.03, weight=0.5, length=0.06)
    rustle(c, 0.0, 0.3, 0.08)


@call("grovequill", 0.56)
def grovequill(c):
    """"grove-quill": o "quill" num trinado rápido, com o vento passando pelas folhas."""
    c.tone(0.0, 0.15, (n("D5"), n("E5")))
    c.tone(0.17, 0.33, (n("A5"), n("B5"), n("G5")), duty=0.125, vibrato=(22.0, 0.03))
    gust(c, 0.05, 0.45, 0.2)
    rustle(c, 0.1, 0.35, 0.08)


@call("arbornix", 0.92)
def arbornix(c):
    """"ar-bor-nix": um chamado que sobe, solene, as asas de folhas abrindo no vento."""
    c.tone(0.0, 0.12, (n("G4"), n("A4")))
    c.tone(0.13, 0.17, (n("C5"), n("D5")))
    c.tone(0.32, 0.54, (n("G5"), n("A5"), n("G5"), n("D5")), duty=(0.25, 0.125), vibrato=(8.0, 0.02),
           sustain=0.6, release=0.12)
    tinkle(c, 0.32, (n("D6"), n("G6")), gap=0.06, weight=0.3)
    gust(c, 0.1, 0.75, 0.22)
    rustle(c, 0.3, 0.5, 0.1)


# Linha do Hushling (Gelo).

@call("hushling", 0.42, gain=0.55)
def hushling(c):
    """"hush-ling" quase sem som: um sopro e dois flocos de gelo tilintando."""
    c.noise(0.0, 0.18, 0.5, step=1, attack=0.4, decay=1.2)
    tinkle(c, 0.18, (n("E6"), n("B6")), gap=0.06, weight=0.6, length=0.1)
    c.tone(0.2, 0.16, (n("E6"), n("E6"), n("C#6")), weight=0.25, wave="tri", tri=0.0)


@call("echofrost", 0.96, echo=((0.16, 0.5), (0.32, 0.25), (0.48, 0.12)))
def echofrost(c):
    """"e-cho-frost" que ecoa três vezes, como a palavra guardada no cristal."""
    c.tone(0.0, 0.08, (n("B4"), n("C#5")))
    c.tone(0.09, 0.11, n("E5"))
    c.tone(0.21, 0.24, (n("G#5"), n("F#5"), n("E5")), duty=0.125, vibrato=(9.0, 0.015))
    hiss(c, 0.21, 0.07, 0.2)
    tinkle(c, 0.3, (n("E6"), n("G#6"), n("B6")), gap=0.04, weight=0.3)



# Linha do Clod (Terra).

@call("clod", 0.32)
def clod(c):
    """"clo-d" abafado, de triângulo, com duas pedrinhas batendo."""
    c.tone(0.0, 0.1, (n("D4"), n("A3")), duty=0.5, weight=0.5, tri=0.8)
    c.tone(0.13, 0.07, (n("G3"), n("E3")), duty=0.5, weight=0.5, tri=0.8)
    click(c, 0.22, 0.3)
    click(c, 0.26, 0.25)
    rumble(c, 0.0, 0.2, 0.1)


@call("crag", 0.5)
def crag(c):
    """"crag": o "cr" de cascalho, a voz áspera e um baque no "g"."""
    c.noise(0.0, 0.12, 0.35, step=4)
    c.tone(0.02, 0.28, (n("A3"), n("C4"), n("G3")), tremolo=(20.0, 0.4), tri=0.6)
    c.tone(0.32, 0.1, n("D3"), weight=0.9, wave="tri", tri=0.0, decay=1.5)
    rumble(c, 0.3, 0.18, 0.2)


@call("ingot", 0.66)
def ingot(c):
    """"in-got": o "got" pesado batendo como numa bigorna, que fica soando."""
    c.tone(0.0, 0.12, (n("E4"), n("F#4")))
    c.tone(0.14, 0.36, (n("B3"), n("A3")), duty=0.5, tri=0.6, sustain=0.5)
    bell(c, 0.14, n("B4"), 0.5, 0.45)
    click(c, 0.14, 0.4)
    rumble(c, 0.14, 0.4, 0.15)


# Linha da Puffcoo (Vento).

@call("puffcoo", 0.48)
def puffcoo(c):
    """"puff-coo-oo": um sopro de penas e um arrulho macio de triângulo, em dois tempos."""
    c.noise(0.0, 0.07, 0.45, step=2, attack=0.3, decay=1.5)
    for start, freqs in ((0.08, (n("A4"), n("C5"))), (0.24, (n("B4"), n("G4")))):
        c.tone(start, 0.18, freqs, weight=0.9, wave="tri", tri=0.0, vibrato=(7.0, 0.02))
        c.tone(start, 0.18, freqs, duty=0.5, weight=0.25, tri=0.0)


@call("galecrest", 0.7)
def galecrest(c):
    """"gale-crest": uma subida em rasante e o "crest" agudo caindo, no meio da ventania."""
    c.tone(0.0, 0.22, (n("D5"), n("A5")))
    c.tone(0.24, 0.38, (n("C6"), n("A5"), n("E5")), duty=0.125, vibrato=(10.0, 0.02))
    gust(c, 0.0, 0.65, 0.28)


# Linha do Tidebud (Água/Volt).

@call("tidebud", 0.38)
def tidebud(c):
    """"tide-bud" de bolha e, no fim, a faísca azul da crista."""
    c.tone(0.0, 0.12, (n("C5"), n("E5")), weight=1.0, wave="tri", tri=0.0)
    c.tone(0.0, 0.12, (n("C5"), n("E5")), duty=0.125, weight=0.3, tri=0.0)
    c.tone(0.14, 0.1, (n("G5"), n("D5")), weight=1.0, wave="tri", tri=0.0)
    bubbles(c, 0.05, 1, weight=0.3)
    zap(c, 0.26, 0.06, 0.3)


@call("kelpcoil", 0.58)
def kelpcoil(c):
    """"kelp-coil": o "coil" enrolando num vibrato largo, com faíscas correndo."""
    c.tone(0.0, 0.12, (n("A4"), n("C5")))
    click(c, 0.1, 0.3)
    c.tone(0.14, 0.36, (n("E5"), n("E5"), n("B4")), duty=0.125, vibrato=(16.0, 0.04))
    zap(c, 0.2, 0.05, 0.35)
    zap(c, 0.38, 0.05, 0.3)
    bubbles(c, 0.03, 1, weight=0.3)


@call("tempestide", 0.95)
def tempestide(c):
    """"tem-pes-tide": um raio no "tide", o trovão por baixo e o mar revolto."""
    c.tone(0.0, 0.1, (n("E4"), n("G4")))
    c.tone(0.11, 0.09, n("B4"))
    hiss(c, 0.15, 0.06, 0.2)
    c.tone(0.22, 0.58, (n("E5"), n("D5"), n("A4"), n("E4")), duty=0.5, double=15.0, vibrato=(6.0, 0.025),
           sustain=0.5, release=0.12)
    zap(c, 0.22, 0.12, 0.45)
    rumble(c, 0.25, 0.65, 0.3, step=14.0, step_to=20.0)
    gust(c, 0.4, 0.5, 0.15)


# Linha do Lume (Sombra).

@call("lume", 0.42)
def lume(c):
    """"lu-me" oco e baixo, de onda quadrada pela metade, como um piar no escuro."""
    c.tone(0.0, 0.14, (n("E4"), n("G4")), duty=0.5, tri=0.5)
    c.tone(0.17, 0.21, (n("D4"), n("D4"), n("B3")), duty=0.5, vibrato=(5.0, 0.015), tri=0.5)


@call("owlume", 0.6, gain=0.85)
def owlume(c):
    """"ow-lu-me": mais grave, com o sopro das asas que não fazem barulho."""
    c.tone(0.0, 0.16, (n("C4"), n("E4")), duty=0.5)
    c.tone(0.17, 0.13, n("G4"), duty=0.5)
    c.tone(0.32, 0.24, (n("E4"), n("C4")), duty=0.5, vibrato=(5.0, 0.02), double=10.0)
    c.noise(0.0, 0.5, 0.07, step=2, attack=0.5, decay=1.0)


@call("noclume", 1.05, echo=((0.18, 0.4), (0.36, 0.18)))
def noclume(c):
    """"noc-lu-me" ondulando devagar (o olhar que confunde), o brilho da lua e o eco."""
    c.tone(0.0, 0.12, (n("A3"), n("C4")), duty=0.5)
    click(c, 0.1, 0.25)
    c.tone(0.14, 0.14, n("E4"), duty=0.5)
    c.tone(0.3, 0.35, (n("D4"), n("C#4"), n("A3")), duty=0.5, double=20.0, vibrato=(3.0, 0.04))
    c.tone(0.3, 0.35, n("A5"), arp=((0, 7, 12), 0.05), weight=0.2, wave="tri", tri=0.0)


# Linha da Snekit (Instinto).

@call("snekit", 0.42)
def snekit(c):
    """"sne-kit-kit": o chiado do "s" e um "ki-ki-ki" de deboche."""
    hiss(c, 0.0, 0.1, 0.5)
    c.tone(0.08, 0.08, (n("B4"), n("D5")), duty=0.125)
    click(c, 0.19, 0.3)
    blips(c, 0.2, (n("F#5"), n("D5"), n("F#5")), gap=0.045, length=0.04, duty=0.125)


@call("venomaw", 0.76)
def venomaw(c):
    """"ve-no-maw": chiado longo, a bocarra num "maw" rouco e o veneno pingando."""
    hiss(c, 0.0, 0.22, 0.5)
    c.tone(0.15, 0.1, (n("F4"), n("A4")))
    c.tone(0.26, 0.1, n("C5"))
    c.tone(0.38, 0.34, (n("G4"), n("D4"), n("A3")), duty=0.5, double=25.0, vibrato=(7.0, 0.02),
           tremolo=(24.0, 0.3), tri=0.6)
    glug(c, 0.6, n("A4"), 0.4)
    glug(c, 0.68, n("F4"), 0.35)


# Linha do Prayling (Inseto).

@call("prayling", 0.36)
def prayling(c):
    """"pray... ling!": um quase nada parado e, de repente, o bote agudo."""
    c.tone(0.04, 0.09, n("E5"), duty=0.125, weight=0.45, tremolo=(60.0, 0.5))
    click(c, 0.2, 0.45)
    c.tone(0.2, 0.14, (n("B5"), n("E6")), duty=0.125, attack=0.001, sustain=1.0, decay=2, tri=0.3)


@call("mantorn", 0.56)
def mantorn(c):
    """"man-torn": duas lâminas batendo e um corte que desce frio."""
    click(c, 0.0, 0.4)
    click(c, 0.05, 0.4)
    c.tone(0.07, 0.11, (n("D5"), n("F5")), duty=0.125, tremolo=(50.0, 0.4))
    c.tone(0.2, 0.28, (n("A5"), n("D5"), n("A4")), duty=0.125)
    c.noise(0.2, 0.12, 0.3, step=1, step_to=3, attack=0.1)


@call("solantis", 0.66)
def solantis(c):
    """"so-lan-tis" subindo em maior, com sinos de luz e o zumbido por baixo."""
    buzz(c, 0.0, 0.6, n("C3"), 0.15)
    c.tone(0.0, 0.1, (n("C5"), n("E5")))
    c.tone(0.11, 0.13, n("G5"))
    c.tone(0.26, 0.34, (n("C6"), n("E6"), n("C6")), weight=0.9, wave="tri", tri=0.0, vibrato=(8.0, 0.01))
    c.tone(0.26, 0.34, (n("C6"), n("E6"), n("C6")), duty=0.125, weight=0.35, tri=0.0)
    tinkle(c, 0.3, (n("C6"), n("E6"), n("G6"), n("C7")), gap=0.05, weight=0.35, length=0.12)


@call("umbrantis", 0.82)
def umbrantis(c):
    """"um-bran-tis" descendo em menor, seco como folha morta, e uma foice raspando."""
    buzz(c, 0.0, 0.6, n("A2"), 0.12, rate=50.0)
    c.tone(0.0, 0.14, (n("A3"), n("C4")), duty=0.5, double=15.0)
    c.tone(0.15, 0.15, (n("E4"), n("D#4")))
    c.tone(0.32, 0.3, (n("C4"), n("B3"), n("F3")), duty=0.125)
    c.noise(0.1, 0.6, 0.12, step=3, attack=0.2, decay=1.2)
    c.noise(0.6, 0.12, 0.25, step=1, step_to=2)


# Linha do Sandlurk (Inseto/Toxina).

@call("sandlurk", 0.56)
def sandlurk(c):
    """"sand-luuurk": um suspiro de tédio que cai devagar, areia escorrendo e uma pinça."""
    c.tone(0.0, 0.12, (n("D4"), n("E4")), weight=0.7)
    c.noise(0.0, 0.12, 0.2, step=2, attack=0.3, decay=1.2)
    c.tone(0.16, 0.32, (n("C4"), n("A3"), n("G3")), duty=0.5, sustain=0.4, tri=0.55)
    c.noise(0.15, 0.35, 0.06, step=2, attack=0.3, decay=1.0)
    click(c, 0.5, 0.4)


@call("dunestrike", 0.74)
def dunestrike(c):
    """"duuune... strike!": a espera grave e lenta e o bote rápido do ferrão."""
    c.tone(0.0, 0.3, (n("G3"), n("A3"), n("G3")), duty=0.5, sustain=0.6, tri=0.55)
    c.noise(0.0, 0.3, 0.1, step=2, attack=0.3, decay=1.0)
    c.tone(0.36, 0.14, (n("D4"), n("D6")), duty=0.125, attack=0.002)
    c.noise(0.36, 0.1, 0.3, step=2, step_to=1)
    click(c, 0.5, 0.55)
    c.tone(0.5, 0.1, n("A2"), weight=0.9, wave="tri", tri=0.0, decay=2)
    glug(c, 0.64, n("E4"), 0.35)


# Linha do Hopling (Instinto).

@call("hopling", 0.46)
def hopling(c):
    """"hop-ling, hmph": um pulinho, o "ling" de cara amarrada e um bufo no fim."""
    c.tone(0.0, 0.08, (n("C5"), n("G5")))
    click(c, 0.07, 0.25)
    c.tone(0.11, 0.13, (n("E5"), n("C5")))
    c.noise(0.28, 0.05, 0.2, step=2, decay=1.5)
    c.tone(0.28, 0.12, (n("G3"), n("F3")), duty=0.5, tri=0.6)


@call("pouchmend", 0.7)
def pouchmend(c):
    """"pouch-mend" resmungado e cansado, e o filhote da bolsa respondendo animado."""
    c.noise(0.0, 0.06, 0.15, step=2, decay=1.5)
    c.tone(0.0, 0.3, (n("E3"), n("D3"), n("C3")), duty=0.5, tremolo=(14.0, 0.35), tri=0.6, sustain=0.7)
    c.tone(0.32, 0.16, (n("F3"), n("D3")), duty=0.5, tri=0.6)
    blips(c, 0.52, (n("C6"), n("E6"), n("G6")), gap=0.05, length=0.05, duty=0.125, weight=0.6, tri=0.0)


# Linha do Glimshell (Luz).

@call("glimshell", 0.6, gain=0.85)
def glimshell(c):
    """"glim-shell" sonolento, num bocejo que desce, com a pedrinha brilhando fraquinho."""
    c.tone(0.0, 0.1, n("E5"), weight=0.9, wave="tri", tri=0.0)
    tinkle(c, 0.02, (n("B6"),), weight=0.2)
    c.tone(0.14, 0.41, (n("A4"), n("B4"), n("E4")), duty=0.5, sustain=0.4, vibrato=(4.0, 0.015), tri=0.5)
    tinkle(c, 0.45, (n("E6"),), weight=0.2)


@call("lumoshell", 0.8, gain=0.9)
def lumoshell(c):
    """"lu-mo-shell": mais devagar e mais grave, com a luz escapando pelas frestas."""
    c.tone(0.0, 0.14, (n("E4"), n("F#4")), duty=0.5)
    c.tone(0.16, 0.14, n("B4"), duty=0.5)
    c.tone(0.33, 0.42, (n("A4"), n("G#4"), n("E4")), duty=0.5, sustain=0.4, vibrato=(4.0, 0.015), tri=0.55)
    tinkle(c, 0.2, (n("E6"), n("B6")), gap=0.1, weight=0.25)
    tinkle(c, 0.55, (n("G#6"),), weight=0.2)


@call("prismback", 1.0)
def prismback(c):
    """"prism-back" muito grave e lento, e um arco-íris de notas espalhado por cima."""
    c.tone(0.0, 0.3, (n("E3"), n("G#3")), duty=0.5, tri=0.65)
    hiss(c, 0.22, 0.05, 0.12)
    c.tone(0.36, 0.56, (n("B3"), n("A3"), n("E3")), duty=0.5, sustain=0.4, vibrato=(3.0, 0.012), tri=0.7,
           release=0.12)
    c.tone(0.36, 0.54, n("E6"), arp=((0, 4, 7, 11, 12, 7, 4), 0.04), weight=0.22, wave="tri", tri=0.0, decay=1)


# Linha do Veilmoth (Arcano).

@call("veilmoth", 0.56, echo=((0.07, 0.55),))
def veilmoth(c):
    """"veil-moth" dobrado, como a irmã respondendo, com pó violeta cintilando."""
    c.tone(0.0, 0.16, (n("F#5"), n("A5")), duty=0.125, vibrato=(9.0, 0.02))
    c.tone(0.18, 0.24, (n("C#6"), n("A5"), n("F#5")), duty=0.125)
    c.tone(0.18, 0.24, n("F#5"), arp=((0, 4, 7, 12), 0.03), weight=0.2, wave="tri", tri=0.0)
    c.noise(0.3, 0.12, 0.1, step=1, attack=0.3, decay=1.5)


@call("gatemoth", 0.88, echo=((0.08, 0.45),))
def gatemoth(c):
    """"gate-moth" e um portal abrindo: um zunido que sobe e o brilho girando."""
    c.tone(0.0, 0.14, (n("D5"), n("F#5")))
    click(c, 0.12, 0.25)
    c.tone(0.16, 0.34, (n("A5"), n("D6"), n("A5")), duty=0.125, vibrato=(9.0, 0.02))
    c.tone(0.16, 0.44, n("D6"), arp=((0, 4, 7, 11), 0.03), weight=0.2, wave="tri", tri=0.0)
    c.tone(0.3, 0.5, (n("D3"), n("D5")), weight=0.35, wave="tri", tri=0.0)
    gust(c, 0.3, 0.45, 0.22)


# Linha do Snelt (Metal).

@call("snelt", 0.42)
def snelt(c):
    """"snelt" e um "tim" de concha polida, soltando fumaça de raiva no fim."""
    hiss(c, 0.0, 0.05, 0.3)
    c.tone(0.04, 0.14, (n("E5"), n("G5")))
    bell(c, 0.18, n("B5"), 0.18, 0.45)
    c.noise(0.26, 0.14, 0.3, step=1, attack=0.15, decay=1.5)


@call("smeltrudge", 0.7)
def smeltrudge(c):
    """"smelt-rudge": o "rudge" moendo devagar, como quem avalia cada pedra, e uma batida."""
    hiss(c, 0.0, 0.05, 0.3)
    c.tone(0.04, 0.16, (n("A3"), n("C4")))
    c.tone(0.24, 0.38, (n("G3"), n("F3"), n("D3")), duty=0.5, tremolo=(18.0, 0.4), tri=0.6)
    c.noise(0.24, 0.38, 0.15, step=5, decay=0.8)
    bell(c, 0.56, n("A4"), 0.14, 0.35)


@call("magmollusk", 1.0)
def magmollusk(c):
    """"mag-mol-lusk" bem grave e sem pressa, a bigorna, a lava borbulhando e as brasas."""
    c.tone(0.0, 0.14, (n("D3"), n("F3")), duty=0.5, tri=0.7)
    c.tone(0.16, 0.14, n("A3"), duty=0.5)
    bell(c, 0.16, n("D5"), 0.55, 0.35)
    c.tone(0.32, 0.38, (n("G3"), n("D3"), n("A2")), duty=0.5, double=20.0, sustain=0.5, tri=0.6)
    hiss(c, 0.62, 0.06, 0.2)
    ember(c, 0.32, 0.06, 0.25, sparks=5, until=0.95)
    for start in (0.72, 0.82, 0.9):
        glug(c, start, n("A3"), 0.4)


# Linha do Fuzzap (Volt).

@call("fuzzap", 0.42)
def fuzzap(c):
    """"fuz-zap... eep!": o pelo chiando, o choque sem querer e o susto com o próprio choque."""
    c.tone(0.0, 0.12, n("E5"), duty=0.125, tremolo=(45.0, 0.7))
    c.noise(0.0, 0.12, 0.15, step=1, attack=0.3, decay=1.0)
    zap(c, 0.13, 0.1, 0.7)
    c.tone(0.3, 0.08, (n("C6"), n("G6")), weight=0.6)


@call("blizzvolt", 0.7)
def blizzvolt(c):
    """"bliz-volt" de alerta: um chiado gelado, o "volt" estalando em raio e cristais."""
    c.tone(0.0, 0.14, n("E5"), duty=0.125)
    c.noise(0.0, 0.14, 0.2, step=1, attack=0.2, decay=1.0)
    tinkle(c, 0.02, (n("B6"),), weight=0.25)
    c.tone(0.16, 0.24, (n("B5"), n("E5"), n("B4")), tremolo=(30.0, 0.3), vibrato=(12.0, 0.02))
    zap(c, 0.16, 0.12, 0.55)
    c.noise(0.4, 0.05, 0.4, step=1, short=True, decay=3)
    tinkle(c, 0.45, (n("E6"), n("G6"), n("B6")), gap=0.05, weight=0.25)


# Linha do Nectoad (Toxina).

@call("nectoad", 0.5)
def nectoad(c):
    """"nec-toad" de bolha, cheio de si, terminando num ta-dá."""
    c.tone(0.0, 0.1, (n("C4"), n("G4")), weight=1.0, wave="tri", tri=0.0)
    c.tone(0.0, 0.1, (n("C4"), n("G4")), duty=0.5, weight=0.3, tri=0.0)
    glug(c, 0.1, n("G4"), 0.25)
    c.tone(0.14, 0.22, (n("E4"), n("E4"), n("C4")), duty=0.5, vibrato=(6.0, 0.02), tri=0.55)
    blips(c, 0.38, (n("C5"), n("G5")), gap=0.04, length=0.06, weight=0.45, tri=0.0)


@call("toxbloom", 0.86)
def toxbloom(c):
    """"tox-bloom": o "bloom" inchando de orgulho, a flor tilintando e o néctar pingando."""
    c.tone(0.0, 0.12, (n("G3"), n("A3")), duty=0.5)
    click(c, 0.1, 0.3)
    hiss(c, 0.08, 0.05, 0.15)
    c.tone(0.16, 0.54, (n("C4"), n("G4"), n("G4"), n("E4")), duty=0.5, attack=0.08, sustain=0.6,
           vibrato=(5.0, 0.02), double=10.0, tri=0.6, release=0.1)
    tinkle(c, 0.4, (n("C6"), n("E6"), n("G6")), gap=0.05, weight=0.25)
    glug(c, 0.62, n("E4"), 0.35)
    glug(c, 0.74, n("C4"), 0.3)
    rustle(c, 0.2, 0.5, 0.07)


# Linha da Budflit (Inseto/Psíquico).

@call("budflit", 0.34, gain=0.7)
def budflit(c):
    """"bud-flit" pequenino, as asas tremendo um pouco e uma faísca de brilho."""
    c.tone(0.0, 0.06, (n("G5"), n("A5")), duty=0.125, weight=0.7)
    c.tone(0.08, 0.16, (n("D6"), n("E6"), n("D6")), duty=0.125, tremolo=(35.0, 0.7))
    tinkle(c, 0.24, (n("A6"),), weight=0.3)


@call("cheerwing", 0.62)
def cheerwing(c):
    """"cheer-wing!" animado e uma vinheta de torcida que sobe, com brilho."""
    hiss(c, 0.0, 0.03, 0.2)
    c.tone(0.0, 0.16, (n("E5"), n("A5")), vibrato=(12.0, 0.02))
    c.tone(0.18, 0.18, (n("C#6"), n("A5")))
    blips(c, 0.38, (n("A5"), n("C#6"), n("E6"), n("A6")), gap=0.045, length=0.05, duty=0.125, weight=0.55,
          tri=0.0)
    sparkle(c, 0.3, 0.6, 4)


@call("galafly", 0.96)
def galafly(c):
    """"ga-la-fly" e uma fanfarra de maestro, com confete caindo."""
    c.tone(0.0, 0.1, n("C5"))
    c.tone(0.11, 0.11, n("E5"))
    c.tone(0.24, 0.31, (n("G5"), n("C6")), duty=0.125, vibrato=(8.0, 0.02))
    blips(c, 0.56, (n("C5"), n("E5"), n("G5")), gap=0.06, length=0.07, weight=0.6)
    c.tone(0.74, 0.2, n("C6"), weight=0.7, vibrato=(10.0, 0.015), release=0.08)
    tinkle(c, 0.78, (n("E6"), n("G6")), gap=0.05, weight=0.25)
    sparkle(c, 0.5, 0.95, 7)


# Linha do Bumbit (Inseto/Flora).

@call("bumbit", 0.42)
def bumbit(c):
    """"bum-bit-bit-bit": as asinhas zumbindo baixinho e um "bit" nervoso, apressado."""
    buzz(c, 0.0, 0.42, n("A3"), 0.3)
    c.tone(0.0, 0.12, (n("E4"), n("D4")), duty=0.5, tri=0.5)
    blips(c, 0.15, (n("A4"), n("B4"), n("A4")), gap=0.05, length=0.035, weight=0.7)


@call("buzzwork", 0.62)
def buzzwork(c):
    """"buzz-work" mandão e uma contagem firme: um, dois, três... pronto."""
    buzz(c, 0.0, 0.55, n("E3"), 0.3, rate=50.0)
    c.tone(0.0, 0.14, (n("A4"), n("G4")), duty=0.125, tremolo=(40.0, 0.5))
    c.tone(0.16, 0.14, (n("D4"), n("C4")), duty=0.5)
    blips(c, 0.34, (n("C5"), n("D5"), n("E5")), gap=0.06, length=0.04, weight=0.6)
    c.tone(0.53, 0.07, n("C5"), weight=0.7)


@call("bloomarch", 1.0)
def bloomarch(c):
    """"bloom-arch" solene, sobre um zumbido grave, com pétalas e mel pingando."""
    buzz(c, 0.0, 0.95, n("A2"), 0.35, rate=35.0)
    c.tone(0.0, 0.3, (n("D3"), n("F3")), duty=0.5, tri=0.7)
    c.tone(0.34, 0.5, (n("A3"), n("G3"), n("D3")), duty=0.5, double=12.0, vibrato=(4.0, 0.015),
           sustain=0.5, tri=0.7, release=0.1)
    hiss(c, 0.78, 0.06, 0.15)
    rustle(c, 0.3, 0.5, 0.08)
    glug(c, 0.86, n("D4"), 0.3)


def main():
    wanted = sys.argv[1:] or sorted(CALLS)
    unknown = [slug for slug in wanted if slug not in CALLS]
    if unknown:
        sys.exit("sem desenho: " + ", ".join(unknown))
    for slug in wanted:
        length, options, design = CALLS[slug]
        sound = Call(length, **options)
        design(sound)
        path, seconds = sound.write(slug)
        print("ok: %-11s %.2f s" % (slug, seconds))


main()
