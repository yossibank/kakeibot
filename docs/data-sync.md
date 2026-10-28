# 同期の表

> [!NOTE]
> 端末間の同期のために持つ表の形が分かる。
> 同期する表は [data](data.md)、決定は [decisions/sync.md](decisions/sync.md) にある。

## sync_state

同期の状態を 1 行だけ持つ。

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | INTEGER | 1 だけ |
| enabled | INTEGER | 同期を入れているか |
| applying | INTEGER | 受け取った変更を書いている間だけ 1。その間は sync_change に記録しない |
| engine_state | BLOB | CKSyncEngine の状態 |

## sync_change

まだ送っていない行。data の表のすべてに、行を足す・変える・消すと、ここに記録するトリガーを持つ。

| 列 | 型 | 補足 |
| --- | --- | --- |
| table_name | TEXT | 表の名前 |
| record_id | TEXT | 行の id。no_spend_day は date、setting は key |
| version | INTEGER | 記録するたびに 1 足す。送った後は、読んだときと同じ値のときだけ消す |

`(table_name, record_id)` が主キー。行が残っていれば保存、無ければ削除として送る。

setting は、次の key を記録しない。

- `onboarding_completed`
- `setup_card_closed`
- `entry_opened`
- `settings_opened`
- `closed_hints`
- `closed_hidden_lists`
- `recent_searches`
- `widget_entry`

## sync_waiting

受け取ったが、入れられない行。参照先がまだ無いときや、ほかの決まりに合わないときに置き、次に受け取ったときに入れ直す。

| 列 | 型 | 補足 |
| --- | --- | --- |
| table_name / record_id | TEXT | sync_change と同じ |
| fields | TEXT | 列の値の JSON |
