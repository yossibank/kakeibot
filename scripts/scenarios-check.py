#!/usr/bin/env python3
import os
import re
import sys

LIST = os.path.join("spec", "scenarios", "models.tsv")
IOS_TESTS = os.path.join("ios", "Packages", "KakeibotApp", "Tests", "FeaturesTests")
ANDROID_TESTS = os.path.join("android", "featuremodels", "src", "test")
HEADER = ["id", "ios", "android", "status", "note"]
MATCHED = "対応"
DIFFERENT = "違い"
UNCHECKED = "未確認"
UNPORTED = "未移植"
IOS_ONLY = "iOSのみ"
ANDROID_ONLY = "Androidのみ"
STATUSES = [MATCHED, DIFFERENT, UNCHECKED, UNPORTED, IOS_ONLY, ANDROID_ONLY]
WHOLE_SUITE = {UNPORTED, IOS_ONLY}
NOTE_LIMIT = 60
WORD = r"[a-z0-9]+(?:-[a-z0-9]+)*"
ID = re.compile(rf"^({WORD})\.({WORD}|\*)$")
TEST = re.compile(r"^([A-Za-z0-9_.]+)/([A-Za-z0-9_]+|\*)$")
ATTRIBUTE = re.compile(r"^\s*@Test\b")
SWIFT_TYPE = re.compile(
    r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|final|public)\s+)*"
    r"(?:struct|extension|class|enum|actor)\s+([A-Za-z0-9_.]+)"
)
SWIFT_FUNC = re.compile(r"\bfunc\s+([A-Za-z0-9_]+)")
KOTLIN_TYPE = re.compile(r"^(?:(?:internal|private)\s+)?class\s+(\w+)")
KOTLIN_FUNC = re.compile(r"\bfun\s+`?([^`(]+?)`?\s*\(")
SUFFIX = re.compile(r"Tests?$")
BOUNDARY = re.compile(r"(?<=[a-z0-9])(?=[A-Z])")

errors = []


def error(path, line, message):
    errors.append(f"{path}:{line}: error: {message}")


def tests_in(root, folder, extension, type_pattern, func_pattern):
    found = {}
    for top, dirs, files in os.walk(os.path.join(root, folder)):
        dirs.sort()
        for file in sorted(files):
            if not file.endswith(extension):
                continue
            path = os.path.join(top, file)
            owner = None
            waiting = False
            for number, line in enumerate(open(path, encoding="utf-8"), 1):
                match = type_pattern.match(line)
                if match:
                    owner = match.group(1)
                if ATTRIBUTE.match(line):
                    waiting = True
                match = func_pattern.search(line) if waiting else None
                if match:
                    waiting = False
                    name = f"{owner}/{match.group(1)}"
                    found[name] = (os.path.relpath(path, root), number)
    return found


def model_of(test):
    owner = SUFFIX.sub("", test.split("/")[0].replace(".", ""))
    words = [word for word in BOUNDARY.sub(" ", owner).split() if word != "Model"]
    return "-".join(words).lower()


def read_rows(root):
    path = os.path.join(root, LIST)
    lines = open(path, encoding="utf-8").read().split("\n")
    if lines[-1] == "":
        lines.pop()
    if not lines or lines[0].split("\t") != HEADER:
        error(LIST, 1, "1 行目は見出しにする: " + "、".join(HEADER))
    rows = []
    for number, line in enumerate(lines[1:], 2):
        cells = line.split("\t")
        if len(cells) != len(HEADER):
            error(LIST, number, f"列はタブ区切りで {len(HEADER)} つにする（{len(cells)} つある）")
            continue
        row = dict(zip(HEADER, cells))
        row["line"] = number
        row["android"] = row["android"].split(" ") if row["android"] else []
        rows.append(row)
    return rows


def check_shape(row, seen):
    number = row["line"]
    status = row["status"]
    match = ID.match(row["id"])
    if not match:
        error(LIST, number, f"ID は <モデル>.<筋書き> の形で、小文字の英数字とハイフンで書く: {row['id']}")
    elif row["id"] in seen:
        error(LIST, number, f"ID が {seen[row['id']]} 行目と重なっている: {row['id']}")
    else:
        seen[row["id"]] = number
    if status not in STATUSES:
        error(LIST, number, f"区分は {'・'.join(STATUSES)} のどれかにする: {status}")
        return
    for test in [row["ios"]] * bool(row["ios"]) + row["android"]:
        if not TEST.match(test):
            error(LIST, number, f"テストは <型>/<関数> の形で書く: {test}")
            return
    whole = row["ios"].endswith("/*")
    if whole != row["id"].endswith(".*"):
        error(LIST, number, "スイートごとの行は、ID を <モデル>.* に、iOS を <スイート>/* にする")
    if whole and status not in WHOLE_SUITE:
        error(LIST, number, f"スイートごとの行の区分は {'・'.join(sorted(WHOLE_SUITE))} のどちらかにする")
    if (status == ANDROID_ONLY) == bool(row["ios"]):
        error(LIST, number, f"iOS のテストは、{ANDROID_ONLY} の行だけ空にする")
    if status in (MATCHED, ANDROID_ONLY) and not row["android"]:
        error(LIST, number, f"{status} の行には、Android のテストを書く")
    if status in (UNCHECKED, UNPORTED, IOS_ONLY) and row["android"]:
        error(LIST, number, f"{status} の行には、Android のテストを書かない")
    if status != MATCHED and not row["note"]:
        error(LIST, number, f"{status} の行には、理由を note に書く")
    if len(row["note"]) > NOTE_LIMIT:
        error(LIST, number, f"note は {NOTE_LIMIT} 字までにする（{len(row['note'])} 字）")
    owner = row["ios"] or (row["android"][0] if row["android"] else "")
    if match and owner and match.group(1) != model_of(owner):
        error(LIST, number, f"ID のモデルは、テストの型の名前から付ける: {model_of(owner)}")


def check_ios(rows, ios):
    suites = {name.split("/")[0] for name in ios}
    whole = {}
    listed = {}
    for row in rows:
        suite, _, func = row["ios"].partition("/")
        if not row["ios"]:
            continue
        if func == "*":
            if suite not in suites:
                error(LIST, row["line"], f"iOS に無いスイート: {suite}")
            elif suite in whole:
                error(LIST, row["line"], f"スイートが {whole[suite]} 行目と重なっている: {suite}")
            whole.setdefault(suite, row["line"])
        elif row["ios"] not in ios:
            error(LIST, row["line"], f"iOS に無いテスト: {row['ios']}。名前を直すか、行を消す")
        elif row["ios"] in listed:
            error(LIST, row["line"], f"iOS のテストが {listed[row['ios']]} 行目と重なっている: {row['ios']}")
        else:
            listed[row["ios"]] = row["line"]
    for name, line in listed.items():
        if name.split("/")[0] in whole:
            error(LIST, line, f"スイートごとの行と重なっている: {name}")
    for name, (path, number) in ios.items():
        if name not in listed and name.split("/")[0] not in whole:
            error(path, number, f"一覧に無い iOS のテスト: {name}。{LIST} に足し、Android の扱いを決める")


def check_android(rows, android):
    used = set()
    for row in rows:
        for name in row["android"]:
            used.add(name)
            if name not in android:
                error(LIST, row["line"], f"Android に無いテスト: {name}。名前を直すか、列を空にして区分を決め直す")
    for name, (path, number) in android.items():
        if name not in used:
            error(path, number, f"一覧に無い Android のテスト: {name}。{LIST} の対応する行に足す")


def counts_of(rows, ios):
    sizes = {}
    for name in ios:
        suite = name.split("/")[0]
        sizes[suite] = sizes.get(suite, 0) + 1
    counts = {}
    for row in rows:
        suite, _, func = row["ios"].partition("/")
        size = sizes.get(suite, 0) if func == "*" else 1
        by_status = counts.setdefault(row["id"].split(".")[0], dict.fromkeys(STATUSES, 0))
        if row["status"] in by_status:
            by_status[row["status"]] += size
    return counts


def print_summary(rows, ios):
    counts = counts_of(rows, ios)
    total = {status: sum(by_status[status] for by_status in counts.values()) for status in STATUSES}
    print("\t".join(["モデル"] + STATUSES + ["計"]))
    for model, by_status in list(counts.items()) + [("計", total)]:
        numbers = [by_status[status] for status in STATUSES]
        print("\t".join([model] + [str(number) for number in numbers] + [str(sum(numbers))]))
    print(f"\n{DIFFERENT}（直す候補）")
    print_rows(rows, DIFFERENT)


def print_rows(rows, status):
    for row in rows:
        if row["status"] == status:
            tests = " ".join([row["ios"]] * bool(row["ios"]) + row["android"])
            print("\t".join([row["id"], row["note"], tests]))


def option(name):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else None


def main():
    root = option("--root") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ios = tests_in(root, IOS_TESTS, ".swift", SWIFT_TYPE, SWIFT_FUNC)
    android = tests_in(root, ANDROID_TESTS, ".kt", KOTLIN_TYPE, KOTLIN_FUNC)
    rows = read_rows(root)
    seen = {}
    for row in rows:
        check_shape(row, seen)
    if not errors:
        check_ios(rows, ios)
        check_android(rows, android)
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    if "--summary" in sys.argv:
        print_summary(rows, ios)
    elif option("--list"):
        print_rows(rows, option("--list"))


if __name__ == "__main__":
    main()
