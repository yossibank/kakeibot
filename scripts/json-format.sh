#!/bin/bash
set -uo pipefail

[[ ${1:-} == "check" || ${1:-} == "write" ]] || { echo "NG 使い方: $(basename "$0") <check|write> [ファイル…]"; exit 1; }

mode=$1
shift
status=0
cd "$(dirname "$0")/.." || exit 1

targets() {
    if [[ $# -gt 0 ]]; then
        printf '%s\n' "$@"
    else
        git ls-files --cached --others --exclude-standard 'spec/fixtures/*.json' 'store/*.json'
    fi
}

while IFS= read -r file; do
    [[ -f $file ]] || continue

    if ! formatted=$(jq --indent 2 . "$file"); then
        echo "error: $file: JSON として読めない"
        status=1
        continue
    fi

    printf '%s\n' "$formatted" | cmp -s - "$file" && continue

    if [[ $mode == "write" ]]; then
        printf '%s\n' "$formatted" >|"$file"
    else
        echo "error: $file: 整形されていない。make format で直す"
        status=1
    fi
done < <(targets "$@")

exit "$status"
