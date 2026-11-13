import pathlib
import runpy
import sys

root = pathlib.Path(__file__).resolve().parents[3]

runpy.run_path(str(root / "scripts" / "snapshot-scroll.py"), run_name="__main__")

work = pathlib.Path(sys.argv[1])
path = next(work.rglob("EntryWalletDeck.swift"))
text = path.read_text()

before = "@State private var isEditing = false"
assert before in text

path.write_text(text.replace(before, "@State private var isEditing = true"))
