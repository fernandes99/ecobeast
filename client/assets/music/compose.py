"""Compositor das músicas da luta (.specs/battle-intro/02-battle-music.md).

As três músicas são composições originais deste projeto, em estilo retrô de
videogame de bolso: progressões de acordes e ritmos comuns do gênero, sem
melodia de jogo nenhum. Este script é a partitura: mude as notas, o andamento
ou os volumes aqui e rode de novo.

    python client/assets/music/compose.py

Gera, ao lado deste arquivo, battle_wild.ogg, battle_tamer.ogg, victory.ogg e
explore.ogg (a música de fundo de Explorar zona, battle-intro/03).
Só usa a biblioteca padrão do Python e o ffmpeg (com libvorbis) no PATH. Rodar
de novo dá os mesmos arquivos.

Cada música de luta começa com uma abertura que toca uma vez só, as batidas
fortes ("tun tun tun") e uma subida que entra na música; depois, o loop volta
para o fim da abertura. O ponto de volta vai para o `loop_offset` do `.import`.

Quatro canais, como os videogames de bolso:
- pulso 1: a melodia, numa onda quadrada;
- pulso 2: os acordes em arpejo, numa onda quadrada mais fina e mais baixa;
- triangular: o baixo;
- ruído: a percussão (bumbo, caixa e chimbal).
"""

from __future__ import annotations

import math
import os
import subprocess
import tempfile
import wave
from array import array
from dataclasses import dataclass, field

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
# O pico depois de normalizar: abaixo de 1 para não distorcer.
PEAK = 0.89
# Notas: dó a si, com sustenido; a oitava 4 tem o lá de 440 Hz.
NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
CHORDS = {
    "C": ["C", "E", "G"],
    "D": ["D", "F#", "A"],
    "Dm": ["D", "F", "A"],
    "E": ["E", "G#", "B"],
    "Em": ["E", "G", "B"],
    "F": ["F", "A", "C"],
    "F#m": ["F#", "A", "C#"],
    "G": ["G", "B", "D"],
    "A": ["A", "C#", "E"],
    "Am": ["A", "C", "E"],
    "Bm": ["B", "D", "F#"],
}


def frequency(note: str) -> float:
    """"A4" -> 440.0. O último caractere é a oitava."""
    name, octave = note[:-1], int(note[-1])
    semitone = NOTE_NAMES.index(name) + (octave + 1) * 12
    return 440.0 * 2.0 ** ((semitone - 69) / 12.0)


@dataclass
class IntroBar:
    """Um compasso da abertura: batidas de acorde, uma melodia e a percussão."""

    # (semicolcheia de início, duração, notas): a mais grave vai no baixo, as
    # outras nas quadradas, e cada batida tem bumbo.
    stabs: list[tuple[int, int, list[str]]]
    melody: list[tuple[str, int]]
    # Como em DRUM_PATTERNS, mais "r", uma caixa curta para o rufar.
    drums: str


@dataclass
class Song:
    name: str
    bpm: float
    # Cada compasso: os acordes, em partes iguais (1, 2 ou 4), e a melodia em
    # (nota, semicolcheias), somando 16. "R" é pausa.
    bars: list[tuple[list[str], list[tuple[str, int]]]]
    loop: bool
    melody_duty: float = 0.5
    bass_octave: int = 2
    harmony_octave: int = 4
    drums: str = "wild"
    # Tempo de sobra no fim, para a última nota soar (só sem loop).
    tail: float = 0.0
    volumes: dict[str, float] = field(default_factory=dict)
    # A abertura, tocada uma vez antes dos compassos que repetem.
    intro: list[IntroBar] = field(default_factory=list)


# --- Partituras ----------------------------------------------------------------

def wild_battle() -> Song:
    """Contra selvagem: animada, em ré maior, 150 batidas por minuto."""
    section_a = [
        (["D"], [("A4", 2), ("D5", 2), ("F#5", 4), ("E5", 2), ("D5", 2), ("E5", 4)]),
        (["Bm"], [("F#5", 4), ("D5", 2), ("B4", 2), ("D5", 4), ("F#5", 4)]),
        (["G"], [("G5", 6), ("F#5", 2), ("E5", 4), ("D5", 4)]),
        (["A"], [("E5", 8), ("C#5", 4), ("A4", 4)]),
        (["D"], [("A4", 2), ("D5", 2), ("F#5", 4), ("A5", 4), ("F#5", 2), ("A5", 2)]),
        (["Bm"], [("B5", 6), ("A5", 2), ("F#5", 4), ("D5", 4)]),
        (["G", "A"], [("G5", 4), ("B5", 4), ("A5", 4), ("C#6", 4)]),
    ]
    section_b = [
        (["G"], [("B4", 4), ("D5", 4), ("G5", 6), ("F#5", 2)]),
        (["A"], [("E5", 4), ("C#5", 4), ("A4", 8)]),
        (["F#m"], [("C#5", 4), ("F#5", 4), ("A5", 4), ("F#5", 4)]),
        (["Bm"], [("B5", 8), ("A5", 4), ("F#5", 4)]),
        (["G"], [("G5", 4), ("F#5", 2), ("E5", 2), ("D5", 4), ("B4", 4)]),
        (["A"], [("C#5", 4), ("E5", 4), ("A5", 8)]),
        (["Em"], [("G5", 4), ("F#5", 2), ("E5", 2), ("B4", 4), ("E5", 4)]),
        (["A"], [("E5", 4), ("F#5", 4), ("G5", 4), ("C#5", 4)]),
    ]
    resolve = (["D"], [("D6", 8), ("A5", 4), ("F#5", 4)])
    # O último compasso fica no lá, que puxa de volta para o ré do começo.
    back_to_start = (["A"], [("A5", 8), ("G5", 4), ("E5", 4)])
    bars = section_a + [resolve] + section_b + section_a + [back_to_start]
    # Três batidas de ré e uma subida que cai no lá do começo da melodia.
    intro = [IntroBar(
        stabs=[(0, 3, ["D2", "D4", "A4"]), (4, 3, ["D2", "D4", "A4"]), (8, 3, ["D2", "D4", "A4"])],
        melody=[("D5", 3), ("R", 1), ("D5", 3), ("R", 1), ("D5", 3), ("R", 1),
                ("F#4", 1), ("G4", 1), ("A4", 1), ("C#5", 1)],
        drums="............rrrr",
    )]
    return Song("battle_wild", 150, bars, loop=True, melody_duty=0.5, drums="wild", intro=intro)


def tamer_battle() -> Song:
    """Contra Domador: mais rápida e tensa, em lá menor, 168 batidas por minuto."""
    section_a = [
        (["Am"], [("A4", 2), ("A4", 2), ("C5", 2), ("E5", 2), ("A5", 4), ("G5", 2), ("E5", 2)]),
        (["Am"], [("F5", 2), ("E5", 2), ("D5", 2), ("C5", 2), ("E5", 8)]),
        (["F"], [("F5", 2), ("F5", 2), ("A5", 2), ("C6", 2), ("A5", 4), ("F5", 4)]),
        (["G"], [("G5", 2), ("G5", 2), ("B5", 2), ("D6", 2), ("B5", 4), ("G5", 4)]),
        (["Am"], [("A5", 2), ("E5", 2), ("A5", 2), ("C6", 2), ("B5", 4), ("A5", 4)]),
        (["Am"], [("G5", 2), ("A5", 2), ("B5", 2), ("C6", 2), ("E6", 8)]),
        (["F"], [("D6", 4), ("C6", 2), ("A5", 2), ("F5", 4), ("A5", 4)]),
        # O mi maior, com o sol sustenido, puxa de volta para o lá menor.
        (["E"], [("G#5", 4), ("B5", 4), ("E6", 6), ("D6", 2)]),
    ]
    section_b = [
        (["Dm"], [("D5", 4), ("F5", 4), ("A5", 6), ("G5", 2)]),
        (["Am"], [("E5", 4), ("C5", 4), ("A4", 8)]),
        (["Dm"], [("D5", 2), ("E5", 2), ("F5", 2), ("A5", 2), ("D6", 6), ("C6", 2)]),
        (["E"], [("B5", 4), ("G#5", 4), ("E5", 8)]),
        (["F"], [("C6", 4), ("A5", 2), ("F5", 2), ("C6", 4), ("D6", 4)]),
        (["G"], [("B5", 4), ("G5", 2), ("D5", 2), ("B5", 4), ("D6", 4)]),
        (["E"], [("E6", 4), ("D6", 2), ("B5", 2), ("G#5", 4), ("B5", 4)]),
        (["E"], [("E5", 2), ("G#5", 2), ("B5", 2), ("D6", 2), ("E6", 8)]),
    ]
    bars = section_a + section_b + section_a
    # Três batidas de lá, fora do tempo, e uma descida cromática até o lá do começo.
    intro = [IntroBar(
        stabs=[(0, 2, ["A1", "A4", "E5"]), (3, 2, ["A1", "A4", "E5"]), (6, 2, ["A1", "A4", "E5"])],
        melody=[("A5", 2), ("R", 1), ("A5", 2), ("R", 1), ("A5", 2),
                ("E5", 1), ("D#5", 1), ("D5", 1), ("C#5", 1), ("C5", 1), ("B4", 1), ("A#4", 1), ("G#4", 1)],
        drums="............rrrr",
    )]
    return Song("battle_tamer", 168, bars, loop=True, melody_duty=0.25, drums="tamer", intro=intro)


def explore() -> Song:
    """O mapa de Explorar zona: calma e de aventura, em sol maior, 120 batidas por minuto."""
    section_a = [
        (["G"], [("B4", 4), ("D5", 4), ("G5", 6), ("F#5", 2)]),
        (["D"], [("A5", 4), ("F#5", 4), ("D5", 8)]),
        (["Em"], [("E5", 4), ("G5", 4), ("B5", 4), ("A5", 4)]),
        (["C"], [("G5", 8), ("E5", 4), ("C5", 4)]),
        (["G"], [("B4", 4), ("D5", 4), ("G5", 4), ("B5", 4)]),
        (["D"], [("A5", 6), ("G5", 2), ("F#5", 4), ("D5", 4)]),
        (["C"], [("E5", 4), ("G5", 4), ("C6", 4), ("B5", 4)]),
    ]
    rest = (["D"], [("A5", 12), ("R", 4)])
    section_b = [
        (["Em"], [("G5", 4), ("F#5", 4), ("E5", 4), ("B4", 4)]),
        (["C"], [("C5", 4), ("E5", 4), ("G5", 8)]),
        (["G"], [("D5", 4), ("G5", 4), ("B5", 6), ("A5", 2)]),
        (["D"], [("F#5", 8), ("A5", 4), ("D6", 4)]),
        (["Em"], [("E6", 6), ("D6", 2), ("B5", 4), ("G5", 4)]),
        (["C"], [("C6", 6), ("B5", 2), ("G5", 4), ("E5", 4)]),
        (["Am"], [("A5", 4), ("C6", 4), ("E6", 4), ("D6", 4)]),
        (["D"], [("D6", 8), ("C6", 4), ("A5", 4)]),
    ]
    # O último compasso desce pelo ré até o si do começo.
    back_to_start = (["D"], [("A5", 8), ("F#5", 4), ("D5", 4)])
    bars = section_a + [rest] + section_b + section_a + [back_to_start]
    return Song(
        "explore", 120, bars, loop=True, melody_duty=0.25, drums="explore",
        volumes={"melody": 0.26, "kick": 0.35, "snare": 0.14, "hat": 0.05},
    )


def victory() -> Song:
    """O toque de vitória: uma fanfarra curta em dó maior."""
    bars = [
        (["C"], [("G4", 2), ("C5", 2), ("E5", 2), ("G5", 2), ("C6", 6), ("G5", 2)]),
        (["F", "G", "C", "C"], [("A5", 2), ("C6", 2), ("B5", 2), ("D6", 2), ("C6", 8)]),
    ]
    return Song("victory", 132, bars, loop=False, melody_duty=0.5, drums="none", tail=0.6)


# --- Síntese -------------------------------------------------------------------

class Track:
    """Um buffer da música inteira. Com loop, o que passa do fim volta ao ponto
    de volta (`loop_start`, o fim da abertura), como o Godot vai tocar."""

    def __init__(self, length: int, loop: bool, loop_start: int = 0) -> None:
        self.data = array("f", [0.0]) * length
        self.length = length
        self.loop = loop
        self.loop_start = loop_start

    def add(self, start: int, samples: list[float]) -> None:
        span = self.length - self.loop_start
        for offset, value in enumerate(samples):
            index = start + offset
            if index >= self.length:
                if not self.loop:
                    return
                index = self.loop_start + (index - self.length) % span
            self.data[index] += value


def envelope(count: int, gate: int, attack: float = 0.004, decay: float = 0.08,
             sustain: float = 0.7, release: float = 0.04) -> list[float]:
    """Ataque curto, queda até o nível de sustentação e soltura depois do `gate`."""
    attack_n = max(1, int(attack * RATE))
    decay_n = max(1, int(decay * RATE))
    release_n = max(1, int(release * RATE))
    levels = []
    for i in range(count):
        if i < attack_n:
            level = i / attack_n
        elif i < attack_n + decay_n:
            level = 1.0 - (1.0 - sustain) * (i - attack_n) / decay_n
        else:
            level = sustain
        if i >= gate:
            level *= max(0.0, 1.0 - (i - gate) / release_n)
        levels.append(level)
    return levels


def pulse(freq: float, gate: int, duty: float, volume: float) -> list[float]:
    count = gate + int(0.04 * RATE)
    env = envelope(count, gate)
    step = freq / RATE
    return [volume * env[i] * (1.0 if (i * step) % 1.0 < duty else -1.0) for i in range(count)]


def triangle(freq: float, gate: int, volume: float) -> list[float]:
    """Triangular em 16 degraus, como a dos videogames antigos."""
    count = gate + int(0.03 * RATE)
    env = envelope(count, gate, decay=0.02, sustain=0.9, release=0.03)
    step = freq / RATE
    out = []
    for i in range(count):
        phase = (i * step) % 1.0
        value = 4.0 * phase - 1.0 if phase < 0.5 else 3.0 - 4.0 * phase
        value = round(value * 7.5) / 7.5
        out.append(volume * env[i] * value)
    return out


def noise(seconds: float, volume: float, period: int, seed: int = 1) -> list[float]:
    """Ruído de um registrador de 15 bits; `period` é de quantas em quantas amostras ele muda."""
    count = int(seconds * RATE)
    register = 0x4000 + seed
    value = 1.0
    out = []
    for i in range(count):
        if i % period == 0:
            bit = (register ^ (register >> 1)) & 1
            register = (register >> 1) | (bit << 14)
            value = 1.0 if register & 1 else -1.0
        out.append(volume * value * (1.0 - i / count) ** 2)
    return out


def kick(volume: float) -> list[float]:
    """Um tom que cai rápido de 160 Hz para 45 Hz."""
    count = int(0.12 * RATE)
    out = []
    phase = 0.0
    for i in range(count):
        t = i / count
        freq = 45.0 + 115.0 * (1.0 - t) ** 3
        phase += freq / RATE
        out.append(volume * (1.0 - t) * math.sin(2.0 * math.pi * phase))
    return out


DRUM_PATTERNS = {
    # Por semicolcheia de um compasso: "k" bumbo, "s" caixa, "h" chimbal, "." nada.
    "wild": "k.h.s.h.k.h.s.hh",
    "tamer": "k.hhs.hkk.hhs.hh",
    "explore": "k...h...s...h...",
    "none": "................",
}


def play_drums(track: Track, pattern: str, bar_start: int, step, volumes: dict[str, float], seed: int) -> None:
    for at, hit in enumerate(pattern):
        start = bar_start + step(at)
        if hit == "k":
            track.add(start, kick(volumes["kick"]))
        elif hit == "s":
            track.add(start, noise(0.12, volumes["snare"], period=2, seed=seed))
        elif hit == "r":
            # O rufar cresce até a música entrar.
            track.add(start, noise(0.06, volumes["snare"] * (0.6 + 0.15 * (at % 4)), period=2, seed=seed + at))
        elif hit == "h":
            track.add(start, noise(0.03, volumes["hat"], period=1, seed=at))


def render(song: Song) -> tuple[array, int]:
    """A música e o ponto de volta do loop, em amostras (o fim da abertura)."""
    sixteenth = 60.0 / song.bpm / 4.0
    bar_samples = round(16 * sixteenth * RATE)
    intro = len(song.intro) * bar_samples
    music = intro + len(song.bars) * bar_samples
    total = music if song.loop else music + int(song.tail * RATE)
    volumes = {"melody": 0.30, "harmony": 0.10, "bass": 0.34, "kick": 0.55, "snare": 0.22, "hat": 0.07, "stab": 0.16}
    volumes.update(song.volumes)
    track = Track(total, song.loop, intro)
    step = lambda count: round(count * sixteenth * RATE)  # noqa: E731

    def play_melody(melody: list[tuple[str, int]], bar_start: int, where: str) -> None:
        # Cada nota soa 90% da duração, para respirar entre elas.
        position = 0
        for note, length in melody:
            if note != "R":
                gate = int(step(length) * 0.9)
                track.add(bar_start + step(position), pulse(frequency(note), gate, song.melody_duty, volumes["melody"]))
            position += length
        if position != 16:
            raise ValueError(f"{song.name}: {where} tem {position} semicolcheias")

    for index, bar in enumerate(song.intro):
        bar_start = index * bar_samples
        play_melody(bar.melody, bar_start, f"o compasso {index + 1} da abertura")
        for start, length, notes in bar.stabs:
            gate = int(step(length) * 0.9)
            at = bar_start + step(start)
            track.add(at, triangle(frequency(notes[0]), gate, volumes["bass"] * 1.2))
            for note in notes[1:]:
                track.add(at, pulse(frequency(note), gate, 0.5, volumes["stab"]))
            track.add(at, kick(volumes["kick"]))
        play_drums(track, bar.drums, bar_start, step, volumes, seed=index)

    for index, (chords, melody) in enumerate(song.bars):
        bar_start = intro + index * bar_samples
        play_melody(melody, bar_start, f"o compasso {index + 1}")

        # Acordes: arpejo em semicolcheias; baixo em colcheias, fundamental e oitava.
        span = 16 // len(chords)
        for part, chord in enumerate(chords):
            tones = CHORDS[chord]
            for sixteen in range(span):
                at = part * span + sixteen
                tone = tones[sixteen % len(tones)]
                gate = int(step(1) * 0.8)
                track.add(bar_start + step(at), pulse(frequency(f"{tone}{song.harmony_octave}"), gate, 0.125, volumes["harmony"]))
            for eighth in range(span // 2):
                at = part * span + eighth * 2
                octave = song.bass_octave + (eighth % 2)
                gate = int(step(2) * 0.85)
                track.add(bar_start + step(at), triangle(frequency(f"{tones[0]}{octave}"), gate, volumes["bass"]))

        play_drums(track, DRUM_PATTERNS[song.drums], bar_start, step, volumes, seed=index)
    return track.data, intro


def normalize(samples: array) -> array:
    loudest = max(abs(value) for value in samples) or 1.0
    gain = PEAK / loudest
    return array("f", (value * gain for value in samples))


def write_ogg(song: Song, samples: array) -> str:
    pcm = array("h", (int(max(-1.0, min(1.0, value)) * 32767) for value in samples))
    target = os.path.join(HERE, f"{song.name}.ogg")
    with tempfile.TemporaryDirectory() as folder:
        source = os.path.join(folder, f"{song.name}.wav")
        with wave.open(source, "wb") as file:
            file.setnchannels(1)
            file.setsampwidth(2)
            file.setframerate(RATE)
            file.writeframes(pcm.tobytes())
        # bitexact: o mesmo .ogg a cada vez, sem número de série sorteado.
        subprocess.run(
            ["ffmpeg", "-loglevel", "error", "-y", "-i", source,
             "-c:a", "libvorbis", "-q:a", "6",
             "-fflags", "+bitexact", "-flags:a", "+bitexact", target],
            check=True,
        )
    return target


def set_loop_offset(song: Song, loop_start: int) -> None:
    """Põe o ponto de volta no `.import` que o Godot criou, se ele já existir."""
    path = os.path.join(HERE, f"{song.name}.ogg.import")
    if not os.path.exists(path):
        print(f"  abra o editor do Godot e rode de novo: falta {os.path.basename(path)}")
        return
    with open(path, encoding="utf-8") as file:
        lines = file.read().splitlines()
    # O mesmo formato que o Godot escreve: "1.6", e não "1.600000".
    offset = "loop_offset=" + f"{loop_start / RATE:.6f}".rstrip("0").rstrip(".")
    lines = [offset if line.startswith("loop_offset=") else line for line in lines]
    with open(path, "w", encoding="utf-8", newline="\n") as file:
        file.write("\n".join(lines) + "\n")


def main() -> None:
    for song in (wild_battle(), tamer_battle(), victory(), explore()):
        samples, loop_start = render(song)
        path = write_ogg(song, normalize(samples))
        if song.loop:
            set_loop_offset(song, loop_start)
        intro = f", abertura de {loop_start / RATE:.2f} s" if loop_start else ""
        print(f"{os.path.basename(path)}: {len(samples) / RATE:.1f} s{intro}")


if __name__ == "__main__":
    main()
