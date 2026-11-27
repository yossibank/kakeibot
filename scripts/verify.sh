#!/bin/bash
set -uo pipefail

usage="NG 使い方: $(basename "$0") [--xcode <版>] <確認の名前> <コマンド…> | --reset | --summary"
skipped=".build/verify/skipped"

case ${1-} in
--reset)
    rm -f "$skipped"
    exit 0
    ;;
--summary)
    if [[ -s $skipped ]]; then
        echo "OK verify（飛ばした段: $(paste -sd, - <"$skipped")）"
    else
        echo "OK verify（全部の段を流した）"
    fi
    exit 0
    ;;
esac

xcode=""
if [[ ${1-} == --xcode ]]; then
    [[ $# -ge 2 ]] || { echo "$usage"; exit 1; }
    xcode=$2
    shift 2
fi

[[ $# -ge 1 ]] || { echo "$usage"; exit 1; }

label=$1
shift
[[ $# -gt 0 ]] || { echo "NG $label: コマンドを渡す"; exit 1; }

mkdir -p .build/verify

if [[ -n $xcode ]] && ! reason=$("$(dirname "$0")/xcode-version.sh" "$xcode"); then
    echo "$label" >>"$skipped"
    echo "SKIP ${label}（${reason}）"
    exit 0
fi

log=".build/verify/$label.log"
"$@" >|"$log" 2>&1
status=$?

if [[ $status -eq 0 ]]; then
    rm -f "$log"
    echo "OK $label"
    exit 0
fi

grep -E "error:|^e: |FAILED|failed|Test Case .* failed|✖|\.md:[0-9]+: |\.kts?:[0-9]+:[0-9]+: " "$log" | sort -u | head -40
echo "NG $label (full log: $log)"
exit "$status"
