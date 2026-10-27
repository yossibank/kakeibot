import pathlib
import sys

root = pathlib.Path(sys.argv[1])
path = next(root.rglob("EntryWalletSheet.swift"))
text = path.read_text()

for before, after in [
    ("FittedSheet(anchor: scrollAnchor) {", "VStack {"),
    ("@State private var isEditing = false", "@State private var isEditing = true"),
]:
    assert before in text
    text = text.replace(before, after)

path.write_text(text)
