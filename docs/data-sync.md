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
トリガーは、同期を入れているか、sync_share に行があるときだけ記録する。

| 列 | 型 | 補足 |
| --- | --- | --- |
| table_name | TEXT | 表の名前 |
| record_id | TEXT | 行の id。no_spend_day は date、setting は key |
| version | INTEGER | 記録するたびに 1 足す。送った後は、読んだときと同じ値のときだけ消す |

`(table_name, record_id)` が主キー。行が残っていれば保存、無ければ削除として送る。

`WITHOUT ROWID` の表なので、GRDB の見張りは、この表の変更に気づかない。トリガーを通さずに書くときは、`notifyChanges` で見張りに知らせる。

setting は、次の key を記録しない。

- `onboarding_completed`
- `setup_card_closed`
- `entry_opened`
- `settings_opened`
- `closed_hints`
- `closed_hidden_lists`
- `recent_searches`
- `widget_entry`

## sync_share

共有している財布。財布ごとに 1 行持つ。

| 列 | 型 | 補足 |
| --- | --- | --- |
| wallet_id | TEXT | 主キー。wallet を参照し、財布を消すと一緒に消える |
| owner_name | TEXT | 自分が誘った側なら NULL。誘われた側なら、誘った人の CloudKit の owner name |

`WITHOUT ROWID` の表である。ゾーンの名前は列に持たず、`"Wallet-" + wallet_id` で決める。

自分のほかの端末は、`Wallet-` のゾーンのレコードを受け取ったときに、財布があれば行を足す。`endSharing` を呼ぶと、行と、そのゾーンの sync_record が消える。財布の行は残り、自分のゾーンに送り直す。

同期の画面の一覧は、owner_name が NULL の財布と、sync_share に行の無い財布を並べる。隠した財布は、共有しているときだけ並べる。

行がどのゾーンに入るかは、次の表で決める。sync_share にある財布だけが共有のゾーンになり、それ以外は自分のゾーンに入る。

| 表 | 共有のゾーンになる財布 |
| --- | --- |
| wallet | その id |
| valuation | wallet_id |
| entry | wallet_id。無ければ to_wallet_id（振替は、どちらかが共有なら共有のゾーン） |
| category | wallet_id |
| tag | その category の wallet_id |
| icon | その icon を指す共有の wallet。無ければ wallet_id を持つ category |
| ほかの表 | 自分のゾーン |

## sync_waiting

受け取ったが、入れられない行。参照先がまだ無いときや、ほかの決まりに合わないときに置き、次に受け取ったときに入れ直す。

| 列 | 型 | 補足 |
| --- | --- | --- |
| table_name / record_id | TEXT | sync_change と同じ |
| fields | TEXT | 列の値の JSON |

## sync_record

iCloud にあるレコードの控え。送った行と受け取った行ごとに、CloudKit の system fields を持つ。

| 列 | 型 | 補足 |
| --- | --- | --- |
| table_name / record_id | TEXT | sync_change と同じ |
| zone_name | TEXT | レコードがあるゾーンの名前。主キーは 3 列の組 |
| system_fields | BLOB | 次に送るときの元にする |

受け取った行と同じ書き込みで控える。全部を取り直すときは、全部消す。

同期を入れたとき・切ったときは、自分のゾーン（`Kakeibot`）の行だけを消す。共有のゾーンに関わる sync_change と、`Wallet-` のゾーンの行は残す。sync_waiting は全部消す。

iCloud の行に入れ替えて同期を入れるときは、手元の行を消す間、sync_change に記録しない。sync_record・sync_change・sync_waiting は全部消す。
