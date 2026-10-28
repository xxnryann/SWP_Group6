"""Sua lai file bi "mojibake" (UTF-8 bi doc nhu cp1252 roi ghi lai).

Chay:  python scripts/fix_mojibake.py
"""
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

# Bang mapping byte cp1252 -> ky tu (nguoc lai cua CP1252).
CP1252_BYTES = {
    0x80: 0x20AC, 0x82: 0x201A, 0x83: 0x0192, 0x84: 0x201E, 0x85: 0x2026,
    0x86: 0x2020, 0x87: 0x2021, 0x88: 0x02C6, 0x89: 0x2030, 0x8A: 0x0160,
    0x8B: 0x2039, 0x8C: 0x0152, 0x8E: 0x017D, 0x91: 0x2018, 0x92: 0x2019,
    0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013, 0x97: 0x2014,
    0x98: 0x02DC, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A, 0x9C: 0x0153,
    0x9E: 0x017E, 0x9F: 0x0178,
}
# Ky tu nao co the bi "lau" khi doc file UTF-8 nhu cp1252.
BROKEN_CHARS = set(chr(code) for code in range(0x80, 0x100))
BROKEN_CHARS.update(chr(code) for code in CP1252_BYTES.values())

RUN_PATTERN = re.compile("[" + "".join(
    re.escape(char) for char in sorted(BROKEN_CHARS, key=ord)) + "]+")

MARKERS = ("áº¿", "á»", "Ã", "Ä", "Æ", "á€", "â€")


def char_to_byte(char):
    code = ord(char)
    if code < 0x80:
        return code
    for byte, special in CP1252_BYTES.items():
        if special == code:
            return byte
    return code


def repair_run(run):
    """Coi run ky tu la cac byte da doc sai, thu giai lai theo UTF-8."""
    raw = bytes(char_to_byte(char) for char in run)
    try:
        decoded = raw.decode("utf-8")
    except UnicodeDecodeError:
        return run
    # Chi sua khi ket qua co ve hop le (khong con chuoi mau "Ã" bien doi).
    if any(marker in decoded for marker in ("Ã", "áº", "á»")):
        return run
    return decoded


def looks_broken(text):
    return any(marker in text for marker in MARKERS)


def repair(text):
    return RUN_PATTERN.sub(lambda match: repair_run(match.group(0)), text)


def main():
    targets = []
    for root in ("src", "web"):
        for base, _dirs, names in os.walk(root):
            for name in names:
                if name.endswith((".java", ".jsp", ".jspf", ".js", ".css", ".properties")):
                    targets.append(os.path.join(base, name))

    changed = []
    for path in targets:
        raw = open(path, "rb").read()
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            print("KHONG DOC DUOC UTF-8: %s" % path)
            continue
        if not looks_broken(text):
            continue
        fixed = repair(text)
        if fixed == text:
            print("BO SUNG - %s" % path)
            continue
        open(path, "w", encoding="utf-8", newline="").write(fixed)
        changed.append(path)

    for path in changed:
        print("DA SUA: %s" % path)
    print("Tong: %d file" % len(changed))


if __name__ == "__main__":
    main()