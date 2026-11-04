"""Lê o executável do simulador de referência sem rodá-lo.

Comandos:
  strings REGEX           textos do arquivo que casam com a expressão
  refs ENDEREÇO           instruções que usam um endereço (texto ou variável)
  dis ENDEREÇO            código de máquina em volta de um endereço
  str ENDEREÇO...         o texto que começa em cada endereço

Endereços em hexadecimal, com ou sem 0x. Use --file para outro arquivo,
como a ajuda (.HLP), que só aceita `strings`.
"""

import argparse
import re
import struct
import sys

import capstone
import pefile

DEFAULT_EXE = r"C:\Games\POKéGAME\PokeGame.exe"

# Endereços já decifrados. Mantenha junto com references/findings.md.
KNOWN = {
    0x4030F8: "Random(eax): 0 até eax-1",
    0x404DDC: "junta textos (edx = quantos)",
    0x4090B8: "inteiro para texto",
    0x41037C: "número grande: copia",
    0x414434: "número grande: cria de inteiro (edx)",
    0x41462C: "número grande: cria de real",
    0x4167DC: "número grande: soma",
    0x4167F4: "número grande: multiplica",
    0x416800: "número grande: compara",
    0x411720: "número grande: para inteiro",
    0x4A8C75: "insígnias",
    0x4A8C78: "dinheiro",
    0x492BD1: "marca do fim do jogo (?)",
}


def hexint(text: str) -> int:
    return int(text, 16)


class Image:
    def __init__(self, path: str):
        with open(path, "rb") as handle:
            self.data = handle.read()
        self.pe = pefile.PE(data=self.data, fast_load=True)
        self.base = self.pe.OPTIONAL_HEADER.ImageBase
        self.md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)

    def va(self, offset: int) -> int:
        return self.base + self.pe.get_rva_from_offset(offset)

    def offset(self, va: int) -> int | None:
        return self.pe.get_offset_from_rva(va - self.base)

    def text_at(self, va: int, limit: int = 120) -> str | None:
        """O texto que começa em `va`, se houver pelo menos 3 letras legíveis."""
        try:
            start = self.offset(va)
        except pefile.PEFormatError:
            return None
        if start is None or start >= len(self.data):
            return None
        raw = self.data[start : start + limit].split(b"\x00")[0]
        if len(raw) < 3 or not all(32 <= byte < 127 or byte >= 160 for byte in raw):
            return None
        return raw.decode("latin1")

    def note(self, op_str: str) -> str:
        notes = []
        for match in re.finditer(r"0x[0-9a-f]{6,8}", op_str):
            value = int(match.group(), 16)
            if value in KNOWN:
                notes.append(KNOWN[value])
            else:
                text = self.text_at(value)
                if text is not None:
                    notes.append(repr(text))
        return f"   ; {' | '.join(notes)}" if notes else ""

    def aligned(self, anchor: int, before: int, after: int):
        """Desmonta a partir de um ponto que passa exatamente por `anchor`."""
        for start in range(anchor - before, anchor - before + 16):
            begin, end = self.offset(start), self.offset(anchor + after)
            code = list(self.md.disasm(self.data[begin:end], start))
            if any(ins.address == anchor for ins in code):
                return code
        return []


def cmd_strings(args) -> None:
    with open(args.file, "rb") as handle:
        data = handle.read()
    try:
        image = Image(args.file)
    except pefile.PEFormatError:
        image = None
    wanted = re.compile(args.regex.encode("latin1"), re.I)
    for match in re.finditer(rb"[\x20-\x7e\xa0-\xff]{4,}", data):
        if wanted.search(match.group()):
            where = f"{image.va(match.start()):08x}" if image else f"arquivo+{match.start():x}"
            print(where, match.group().decode("latin1")[:200])


def cmd_refs(args) -> None:
    image = Image(args.file)
    needle = struct.pack("<I", args.address)
    for match in re.finditer(re.escape(needle), image.data):
        va = image.va(match.start())
        for back in range(1, 4):
            code = list(image.md.disasm(image.data[match.start() - back : match.start() + 8], va - back, count=1))
            if code and code[0].address == va - back and f"{args.address:#x}" in code[0].op_str:
                ins = code[0]
                print(f"{ins.address:08x} {ins.mnemonic} {ins.op_str}")
                break
        else:
            print(f"{va:08x} (dado ou instrução não reconhecida)")


def cmd_dis(args) -> None:
    image = Image(args.file)
    code = image.aligned(args.address, args.before, args.after)
    if not code:
        sys.exit("Não achei um começo de instrução que passe por esse endereço.")
    for ins in code:
        mark = ">>" if ins.address == args.address else "  "
        print(f"{mark} {ins.address:08x} {ins.mnemonic} {ins.op_str}{image.note(ins.op_str)}")


def cmd_str(args) -> None:
    image = Image(args.file)
    for address in args.addresses:
        print(f"{address:08x}", repr(image.text_at(address, 400)))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--file", default=DEFAULT_EXE)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("strings").add_argument("regex")
    sub.add_parser("refs").add_argument("address", type=hexint)
    dis = sub.add_parser("dis")
    dis.add_argument("address", type=hexint)
    dis.add_argument("--before", type=hexint, default=0x60)
    dis.add_argument("--after", type=hexint, default=0x60)
    sub.add_parser("str").add_argument("addresses", type=hexint, nargs="+")
    args = parser.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    {"strings": cmd_strings, "refs": cmd_refs, "dis": cmd_dis, "str": cmd_str}[args.command](args)


if __name__ == "__main__":
    main()
