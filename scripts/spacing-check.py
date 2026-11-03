#!/usr/bin/env python3
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGES = os.path.join(ROOT, "ios", "Packages")
NUMBER = r"(\d+(?:\.\d+)?)"
END = r"(?=\s*[,)])"

PATTERNS = [
    re.compile(r"\.padding\((?:\.\w+, |\[[^\]]*\], )?" + NUMBER + r"\)"),
    re.compile(r"\bspacing: " + NUMBER + END),
    re.compile(r"\bcornerRadius: " + NUMBER + END),
    re.compile(r"\.radius\(" + NUMBER + r"\)"),
]


def sources():
    for package in sorted(os.listdir(PACKAGES)):
        top = os.path.join(PACKAGES, package, "Sources")

        for folder, _, files in os.walk(top):
            for name in sorted(files):
                if name.endswith(".swift"):
                    yield os.path.join(folder, name)


def allowed(value):
    number = float(value)
    return number <= 2 or (number.is_integer() and int(number) % 4 == 0)


def main():
    errors = []

    for path in sources():
        with open(path, encoding="utf-8") as file:
            for line_number, line in enumerate(file, start=1):
                for pattern in PATTERNS:
                    for match in pattern.finditer(line):
                        value = match.group(1)

                        if not allowed(value):
                            relative = os.path.relpath(path, ROOT)
                            message = f"余白・間隔・角の丸みは 4 の倍数にする（2 以下は除く）: {value}"
                            errors.append(f"{relative}:{line_number}: error: {message}")

    print("\n".join(errors))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
