---
paths:
  - "*.md"
  - "docs/**/*.md"
  - "spec/**/*.md"
---

# 文書の役割

kakeibot の文書を読み書きするときに読み込まれる。どの事実をどの文書に書くかを決める。書き方の決まりは、共通の設定（[claude-config](https://github.com/yossibank/claude-config) の `rules/docs.md`）にある。

| 文書 | 書く | 書かない |
| --- | --- | --- |
| README | 入口、準備、コマンド、バッジ | 機能の中身、決定 |
| CLAUDE.md | 作業の進め方、作業と文書の対応 | 全リポジトリ共通の決まり（claude-config） |
| overview | 何を作るか、守ること、未決 | 作り方 |
| architecture | 今の形（フォルダ、ターゲット、依存、署名の状態） | 理由、選ばなかった案、decisions の決定の言い直し |
| decisions | 決定、理由、選ばなかった案 | 形の詳しい説明（architecture へリンク） |
| data | 表の形と、その決まり | なぜその形か |
| roadmap | 作る順番、状態、画面 | 設定・環境の状態 |
| spec/export-format | 書き出しの形式 | 表の形（data へリンク） |

README のバッジは、overview と同じ事実を書く例外。CLAUDE.md の「文書」の表で一緒に直す。
