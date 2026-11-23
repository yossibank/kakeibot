# 共通の部品の一覧

> [!NOTE]
> 複数の画面で使う仕組みの名前、使いどころ、置き場所が分かる。
> 全体の構成は [architecture](architecture.md)、名前の付け方は [architecture-naming](architecture-naming.md) にある。

## 🪝 プロトコル

`Features/Shared/` に置くプロトコルは、すべてここに載せる。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `ScreenModel` | 画面のモデル。DB の見張りと、読めなかった時のエラーのバナーを共通にする | `Features/Shared/Model/` |
| `SettingSaving` | 設定の値を保存するモデル。失敗したら値を戻す | `Features/Shared/Model/` |
| `SettingsBoardModel` | 並べ替え・非表示・削除のできる、設定の一覧のモデル | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardListModel` | 一覧を DB から読み、見張るモデル。`SettingsBoardPage` に載せる画面は、これに適合させる | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardSpec` | 一覧の画面ごとの設定（題・文言・タイルの形・タイル・編集画面）。画面ごとに 1 つ書く | `Features/Shared/SettingsParts/Board/` |
| `SettingsEditModel` | 1 件を編集するモデル。下書きと、保存できるかを持つ | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditing` | 編集の画面がモデルに頼む操作（非表示・削除）と状態 | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditRemoving` | 編集のモデルに、非表示と削除を足す | `Features/Shared/SettingsParts/Input/` |

## 🗺️ 画面の部品

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `SettingsBoardPage` | 設定の一覧の画面の全体。`SettingsBoardSpec` を受け取り、状態・行き先・削除の確認・見張りを持つ | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardScreen` | `SettingsBoardPage` の中で使う、設定の一覧の外枠。説明カード・タイルの並び・追加ボタンを組む | `Features/Shared/SettingsParts/Board/` |

## 🪜 設定の一覧の画面を足す

並べ替えのできる設定の一覧は、次の順で足す。

| 順 | すること | 書く所 |
| --- | --- | --- |
| 1 | モデルを `SettingsBoardListModel` と `SettingsBoardModel` に適合させる | `<単数>ListModel` |
| 2 | 設定の型を 1 つ書き、`SettingsBoardSpec` に適合させる | `<単数>Board` |
| 3 | 画面は、`body` で `SettingsBoardPage` を返すだけにする | `<単数>ListView` |

設定の型の例は、`StampBoard` と `CategoryBoard` にある。`CategoryBoard` は、支出と収入の切り替えを `header` に持つ。
