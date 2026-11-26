#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile

CHECK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs-check.py")
TREE_DOCS = ["docs/architecture-packages.md", "docs/architecture-packages-app.md"]
README = "\n".join(f"[{name}]({name})" for name in TREE_DOCS + ["docs/decisions/README.md", "spec/fixtures.md"])
FILES = {
    "Makefile": "verify-docs:\n",
    "ios/Kakeibot.xctestplan": '{"testTargets": []}',
    "ios/Packages/KakeibotKit/Sources/Core/Concepts/.keep": "",
    "spec/fixtures/.keep": "",
    "spec/fixtures.md": "# fixtures\n",
    "docs/architecture-packages.md": "# packages\n",
    "docs/architecture-packages-app.md": "# app\n",
    "docs/decisions/README.md": "# 索引\n\n[sync](sync.md)\n",
    "docs/decisions/sync.md": "# 同期\n",
    "README.md": README,
}
UNREACHED = "README の文書の表か、決定の索引（docs/decisions/README.md）から届かない"
CASES = [
    ("すべて届く", {}, None),
    ("どこからも届かない docs", {"docs/lost.md": "# 迷子\n"}, f"docs/lost.md:1: error: {UNREACHED}"),
    ("どこからも届かない spec", {"spec/lost.md": "# 迷子\n"}, f"spec/lost.md:1: error: {UNREACHED}"),
    ("索引から届かない決定", {"docs/decisions/README.md": "# 索引\n"}, f"docs/decisions/sync.md:1: error: {UNREACHED}"),
    ("決定の文書からだけ届く", {"docs/decisions/sync.md": "# 同期\n\n[迷子](../lost.md)\n", "docs/lost.md": "# 迷子\n"}, f"docs/lost.md:1: error: {UNREACHED}"),
    ("README から届かない索引", {"README.md": README.replace("[docs/decisions/README.md](docs/decisions/README.md)", "")}, f"docs/decisions/README.md:1: error: {UNREACHED}"),
]


def run(changes):
    with tempfile.TemporaryDirectory() as root:
        for relative, text in {**FILES, **changes}.items():
            path = os.path.join(root, relative)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as file:
                file.write(text)
        command = [sys.executable, "-I", CHECK, "--root", root]
        return subprocess.run(command, capture_output=True, text=True, check=False)


def main():
    failures = []
    for name, changes, expected in CASES:
        result = run(changes)
        if expected is None:
            passed = result.returncode == 0 and not result.stdout.strip()
        else:
            passed = result.returncode != 0 and expected in result.stdout
        if not passed:
            failures.append(f"error: {name}: 出力が違う\n{result.stdout}{result.stderr}")
    print("\n".join(failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
