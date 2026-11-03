import pathlib
import runpy

root = pathlib.Path(__file__).resolve().parents[3]

runpy.run_path(str(root / "scripts" / "snapshot-scroll.py"), run_name="__main__")
