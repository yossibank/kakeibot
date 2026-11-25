#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile

CHECK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scenarios-check.py")
LIST = os.path.join("spec", "scenarios", "models.tsv")
SWIFT = os.path.join("ios", "Packages", "KakeibotApp", "Tests", "FeaturesTests", "Tests.swift")
KOTLIN = os.path.join("android", "featuremodels", "src", "test", "Tests.kt")
HEADER = "id\tios\tandroid\tstatus\tnote"
SWIFT_SOURCE = """
struct EntryModelTests {
    @Test
    func savesNewEntry() async throws {}

    @Test(arguments: [
        1,
    ])
    func refusesZeroAmount(_ value: Int) {}

    func helper() {}
}

extension EntryModelTests {
    @Test func readsReceipt() {}
}

struct SyncModelTests {
    @Test
    func sendsRows() {}

    @Test
    func stopsOnFailure() {}
}
"""
KOTLIN_SOURCE = """
class EntryModelTest {
    @Test
    fun savesNewEntry() = modelTest {}

    @Test
    fun savesOnce() = modelTest {}

    private fun helper() {}
}

class ScreenObservationTest {
    @Test
    fun stopsAtLimit() {}
}
"""
ROWS = [
    "entry.saves-new-entry\tEntryModelTests/savesNewEntry\tEntryModelTest/savesNewEntry EntryModelTest/savesOnce\t対応\t",
    "entry.refuses-zero-amount\tEntryModelTests/refusesZeroAmount\t\t違い\t0 円でも保存する",
    "entry.reads-receipt\tEntryModelTests/readsReceipt\t\t未移植\tレシートの読み取りが無い",
    "sync.*\tSyncModelTests/*\t\t未移植\t同期の画面が無い",
    "screen-observation.stops-at-limit\t\tScreenObservationTest/stopsAtLimit\tAndroidのみ\t読み直しの回数",
]
CASES = [
    ("そろった一覧", ROWS, None),
    ("一覧に無い iOS のテスト", ROWS[:1] + ROWS[2:], "一覧に無い iOS のテスト: EntryModelTests/refusesZeroAmount"),
    ("一覧に無い Android のテスト", ROWS[:4], "一覧に無い Android のテスト: ScreenObservationTest/stopsAtLimit"),
    ("iOS に無いテスト", ROWS + ["entry.gone\tEntryModelTests/gone\t\t未確認\t消えた"], "iOS に無いテスト: EntryModelTests/gone"),
    ("Android に無いテスト", [ROWS[0].replace("savesOnce", "gone")] + ROWS[1:], "Android に無いテスト: EntryModelTest/gone"),
    ("iOS に無いスイート", ROWS + ["backup.*\tBackupModelTests/*\t\t未移植\t無い"], "iOS に無いスイート: BackupModelTests"),
    ("重なった iOS のテスト", ROWS + [ROWS[1].replace("refuses-zero-amount", "again")], "iOS のテストが 3 行目と重なっている"),
    ("重なった ID", ROWS + [ROWS[4]], "ID が 6 行目と重なっている"),
    ("スイートごとの行との重なり", ROWS + ["sync.sends-rows\tSyncModelTests/sendsRows\t\t未確認\t送る"], "スイートごとの行と重なっている"),
    ("知らない区分", [ROWS[0].replace("対応", "同じ")] + ROWS[1:], "区分は"),
    ("Android の無い対応", ["entry.saves-new-entry\tEntryModelTests/savesNewEntry\t\t対応\t"] + ROWS[1:], "対応 の行には、Android のテストを書く"),
    ("理由の無い違い", [ROWS[0], ROWS[1].replace("0 円でも保存する", "")] + ROWS[2:], "違い の行には、理由を note に書く"),
    ("長い note", [ROWS[0], ROWS[1].replace("0 円", "0" * 61)] + ROWS[2:], "note は 60 字までにする"),
    ("型と合わない ID", [ROWS[0].replace("entry.", "records.")] + ROWS[1:], "ID のモデルは、テストの型の名前から付ける: entry"),
    ("足りない列", ROWS + ["entry.short\tEntryModelTests/short"], "列はタブ区切りで 5 つにする"),
    ("見出しの無い一覧", None, "1 行目は見出しにする"),
]
SUMMARY = "計\t1\t1\t0\t3\t0\t1\t6"


def write(root, relative, text):
    path = os.path.join(root, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as file:
        file.write(text)


def run(rows, *options):
    with tempfile.TemporaryDirectory() as root:
        write(root, SWIFT, SWIFT_SOURCE)
        write(root, KOTLIN, KOTLIN_SOURCE)
        write(root, LIST, "\n".join(ROWS if rows is None else [HEADER] + rows) + "\n")
        command = [sys.executable, "-I", CHECK, "--root", root, *options]
        return subprocess.run(command, capture_output=True, text=True, check=False)


def main():
    failures = []
    for name, rows, expected in CASES:
        result = run(rows)
        passed = result.returncode == 0 and not result.stdout if expected is None else expected in result.stdout
        if not passed or (expected and result.returncode == 0):
            failures.append(f"error: {name}: 出力が違う\n{result.stdout}{result.stderr}")
    summary = run(ROWS, "--summary").stdout
    if SUMMARY not in summary or "entry.refuses-zero-amount\t0 円でも保存する" not in summary:
        failures.append(f"error: 集計: 出力が違う\n{summary}")
    print("\n".join(failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
