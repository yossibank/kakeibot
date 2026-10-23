---
name: widget-snapshot
description: kakeibot のウィジェット（あといくらの小・中、すぐ記録の中・大、ロック画面の丸・横長・1 行）を、シミュレーターでテストとして描いて PNG にする。ウィジェットの見た目・余白・色・字体を変えたときや、確かめたいときに使う。
argument-hint: "<出力先のフォルダ> [ひな形の Swift]"
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
---

# ウィジェットを描いて見る

ウィジェットを `ImageRenderer` で PNG に描き、見た目を確かめる手順。ホーム画面に置かなくても、場合ごとの見た目を比べられる。

## 使い方

描くときは、次を実行する。

```sh
${CLAUDE_SKILL_DIR}/scripts/render.sh <出力先のフォルダ> [ひな形の Swift]
```

ひな形を渡さないときは、`templates/RenderTests.swift` を使う。描く場合を変えたいときは、ひな形を出力先にコピーして書き換え、そのパスを渡す。

`render.sh` は、次を自動で行い、終わると必ず元に戻す。

- `BudgetWidgetView`・`BudgetLockWidgetView`・`QuickRecordWidgetView` の `widgetFamily` を、外から渡せる値に差し替える
- `KakeibotApp` の Package.swift に、一時のテストのターゲット `AppWidgetSnapshotTests` を足す
- シミュレーターでそのテストだけを動かし、`<場合>-<形>.png` を出力先に書く

シミュレーターは、`DEVICE` に UDID を渡して選べる。渡さないときは、使える iPhone の最初の 1 台を使う。

## 読み方

PNG は、確かめたい場合と形のものだけを読む。全部を読まない。直す前と後を比べるときは、同じ場合・同じ形のファイルを並べて読む。

## 描いた見た目の限り

`ImageRenderer` は WidgetKit の外で描くので、次は実際のウィジェットと違う。

- 背景（`containerBackground`）は描かれない。ひな形の背景の色で代わりに塗る
- ロック画面の色づけ（OS が決める単色の表示）は描かれない
- 手書き・ドットの字体は、テストの中では登録されないので出ない

これらは、実機かシミュレーターのホーム画面で確かめる。
