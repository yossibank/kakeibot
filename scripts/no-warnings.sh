#!/bin/bash
set -uo pipefail

[[ $# -gt 0 ]] || { echo "NG 使い方: $(basename "$0") <ビルドのコマンド…>"; exit 1; }

output=$("$@" 2>&1)
status=$?
echo "$output"

[[ $status -eq 0 ]] || exit "$status"

warnings=$(echo "$output" | grep -E ': warning: ' | grep -v '/SourcePackages/' | sort -u)

[[ -z $warnings ]] && exit 0

echo "$warnings" | sed 's/: warning: /: error: 警告が出た: /'
exit 1
