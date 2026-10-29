---
paths:
  - "*.md"
  - "docs/**/*.md"
  - "spec/**/*.md"
---

# 文書の役割

kakeibot の文書を読み書きするときに読み込まれる決まり。spec の文書の役割を決める。

ほかの文書の役割と足す条件は、[claude-config](https://github.com/yossibank/claude-config) の `rules/docs-app.md` にある。

| 文書 | 書く | 書かない |
| --- | --- | --- |
| spec/export-format | 書き出しの形式 | 表の形（data へリンク） |
| spec/fixtures | fixtures の JSON の形式 | 置き場所と名前（architecture へリンク） |

README のバッジは、ほかの文書と同じ事実を書く例外である。対応 OS は overview、言語の版と使う技術は architecture と同じにする。CLAUDE.md の「文書」の表で一緒に直す。
