#!/usr/bin/env python3
import json
import os
import re
import sys
import unicodedata
from urllib.parse import unquote

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP = {".git", ".build", ".swiftpm", "DerivedData", "worktrees", "node_modules"}
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
FENCE = re.compile(r"^\s*```")
HEADING = re.compile(r"^#{1,6}\s+(.+?)\s*#*\s*$")
TREE = re.compile(r"^([│ ]*)[├└]── ([^\s]+/)")
MAKE = re.compile(r"`make ([a-z][a-z-]*)")
TARGET = re.compile(r"^([a-z][a-z-]*):", re.M)
TEST_TARGET = re.compile(r"\.testTarget\(\s*name:\s*\"([^\"]+)\"")
SAMPLES = {"export/export-v1.json"}
DOC = os.path.join(ROOT, "docs", "architecture-packages.md")

errors = []
anchors = {}


def error(path, line, message):
    errors.append(f"{os.path.relpath(path, ROOT)}:{line}: error: {message}")


def markdown_files():
    for top, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP]
        for file in files:
            if file.endswith(".md"):
                yield os.path.join(top, file)


def slug(heading):
    text = "".join(
        c for c in heading.lower()
        if c in "-_ " or unicodedata.category(c)[0] in "LMN"
    )
    return text.replace(" ", "-")


def anchors_of(path):
    if path not in anchors:
        found = set()
        counts = {}
        fenced = False
        for line in open(path, encoding="utf-8").read().split("\n"):
            if FENCE.match(line):
                fenced = not fenced
            match = None if fenced else HEADING.match(line)
            if match:
                base = slug(match.group(1))
                count = counts.get(base, 0)
                counts[base] = count + 1
                found.add(base if count == 0 else f"{base}-{count}")
        anchors[path] = found
    return anchors[path]


def check_links(path, lines):
    fenced = False
    for number, line in enumerate(lines, 1):
        if FENCE.match(line):
            fenced = not fenced
        if fenced:
            continue
        for target in LINK.findall(line):
            if re.match(r"[a-z]+:", target):
                continue
            file, _, anchor = target.partition("#")
            full = os.path.join(os.path.dirname(path), unquote(file)) if file else path
            if not os.path.exists(full):
                error(path, number, f"リンク先が無い: {target}")
            elif anchor and full.endswith(".md") and unquote(anchor) not in anchors_of(full):
                error(path, number, f"リンク先の見出しが無い: {target}")


def check_trees(path, lines):
    fenced = False
    stack = []
    for number, line in enumerate(lines, 1):
        if FENCE.match(line):
            fenced = not fenced
            close(stack, 0)
            continue
        if not fenced:
            continue
        if not stack:
            name = line.strip()
            base = os.path.join(ROOT, "ios", "Packages", name.rstrip("/"))
            if name.endswith("/") and os.path.isdir(base):
                stack = [(base, number, [])]
            continue
        match = TREE.match(line)
        if not match:
            continue
        depth = len(match.group(1)) // 4 + 1
        close(stack, depth)
        parent = stack[-1][0]
        first = match.group(2).split("/")[0]
        stack[-1][2].append(first)
        full = os.path.join(parent, match.group(2).rstrip("/"))
        if not os.path.isdir(full):
            error(path, number, f"木のフォルダが無い: {os.path.relpath(full, ROOT)}")
        if match.group(2).count("/") == 1:
            stack.append((full, number, []))
    close(stack, 0)


def close(stack, depth):
    while len(stack) > depth:
        folder, number, listed = stack.pop()
        if not listed or not os.path.isdir(folder):
            continue
        actual = sorted(
            d for d in os.listdir(folder)
            if not d.startswith(".") and os.path.isdir(os.path.join(folder, d))
        )
        for name in actual:
            if name not in listed:
                error(DOC, number, f"木に無いフォルダ: {os.path.relpath(os.path.join(folder, name), ROOT)}")


def check_make(path, text, targets):
    for number, line in enumerate(text.split("\n"), 1):
        for target in MAKE.findall(line):
            if target not in targets:
                error(path, number, f"Makefile に無い入口: make {target}")


def check_fixtures():
    base = os.path.join(ROOT, "spec", "fixtures")
    concepts = os.path.join(
        ROOT, "ios", "Packages", "KakeibotKit", "Sources", "Core", "Concepts"
    )
    folders = {d.lower() for d in os.listdir(concepts)}
    for folder in sorted(os.listdir(base)):
        if os.path.isdir(os.path.join(base, folder)) and folder not in folders:
            error(os.path.join(base, folder), 1, "Core/Concepts に同じ名前のフォルダが無い")
    for top, _, files in os.walk(base):
        for file in sorted(files):
            path = os.path.join(top, file)
            if not file.endswith(".json") or os.path.relpath(path, base) in SAMPLES:
                continue
            try:
                data = json.load(open(path, encoding="utf-8"))
            except ValueError as e:
                error(path, 1, f"JSON が読めない: {e}")
                continue
            if not isinstance(data, dict) or not isinstance(data.get("description"), str):
                error(path, 1, "description が無い")
                continue
            if "cases" not in data:
                continue
            summaries = [case.get("summary") for case in data["cases"]]
            if not all(isinstance(s, str) and s for s in summaries):
                error(path, 1, "summary の無いケースがある")
            elif len(set(summaries)) != len(summaries):
                error(path, 1, "summary が重なっている")


def check_test_plan():
    plan_path = os.path.join(ROOT, "ios", "Kakeibot.xctestplan")
    plan = json.load(open(plan_path, encoding="utf-8"))
    planned = {entry["target"]["name"] for entry in plan["testTargets"]}
    packages = os.path.join(ROOT, "ios", "Packages")
    declared = set()
    for package in sorted(os.listdir(packages)):
        manifest = os.path.join(packages, package, "Package.swift")
        if os.path.exists(manifest):
            declared |= set(TEST_TARGET.findall(open(manifest, encoding="utf-8").read()))
    for name in sorted(declared - planned):
        error(plan_path, 1, f"テストプランに無いテストのターゲット: {name}")
    for name in sorted(planned - declared):
        error(plan_path, 1, f"Package.swift に無いテストのターゲット: {name}")


def main():
    makefile = open(os.path.join(ROOT, "Makefile"), encoding="utf-8").read()
    targets = set(TARGET.findall(makefile))
    for path in markdown_files():
        text = open(path, encoding="utf-8").read()
        lines = text.split("\n")
        check_links(path, lines)
        check_make(path, text, targets)
    check_trees(DOC, open(DOC, encoding="utf-8").read().split("\n"))
    check_fixtures()
    check_test_plan()
    print("\n".join(errors))
    sys.exit(1 if errors else 0)


main()
