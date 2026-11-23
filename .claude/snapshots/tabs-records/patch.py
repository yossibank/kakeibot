import pathlib
import runpy
import sys

root = pathlib.Path(__file__).resolve().parents[3]

runpy.run_path(str(root / "scripts" / "snapshot-scroll.py"), run_name="__main__")

records = pathlib.Path(sys.argv[1]) / "Sources/Features/Screens/Tabs/Records/View/RecordsView.swift"
text = records.read_text(encoding="utf-8")
records.write_text(text.replace("LazyVStack(", "VStack("), encoding="utf-8")
