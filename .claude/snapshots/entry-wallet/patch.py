import pathlib
import sys

root = pathlib.Path(sys.argv[1])
path = next(root.rglob("EntryWalletSheet.swift"))
text = path.read_text()

before = "FittedSheet(anchor: scrollAnchor) {"
assert before in text

path.write_text(text.replace(before, "VStack {"))
