#!/bin/bash
set -uo pipefail

[[ $# -eq 1 ]] || { echo "NG 使い方: $(basename "$0") <要る Xcode の版>"; exit 2; }

need=$1
have=$(xcodebuild -version 2>/dev/null | awk '$1 == "Xcode" { print $2; exit }')

if [[ -z $have ]]; then
    echo "Xcode $need が要る。手元に無い"
    exit 1
fi

awk -v need="$need" -v have="$have" 'BEGIN {
    n = split(need, a, ".")
    m = split(have, b, ".")
    len = n > m ? n : m
    for (i = 1; i <= len; i++) {
        x = (i <= n) ? a[i] + 0 : 0
        y = (i <= m) ? b[i] + 0 : 0
        if (y > x) exit 0
        if (y < x) exit 1
    }
    exit 0
}' && exit 0

echo "Xcode $need が要る。手元は $have"
exit 1
