#!/bin/bash
set -euo pipefail

skill=$(cd "$(dirname "$0")/.." && pwd)
root=$(cd "$skill/../../.." && pwd)
out=$(mkdir -p "${1:?出力先のフォルダ}" && cd "$1" && pwd)
template="${2:-$skill/templates/RenderTests.swift}"
package="$root/ios/Packages/KakeibotApp"
tests="$package/Tests/AppWidgetSnapshotTests"
backup=$(mktemp -d)

device="${DEVICE:-$(xcrun simctl list devices available iPhone | awk -F '[()]' '/iPhone/ { print $2; exit }')}"

files=(
    "$package/Package.swift"
    "$package/Sources/AppWidget/BudgetWidgetView.swift"
    "$package/Sources/AppWidget/BudgetLockWidgetView.swift"
)

restore() {
    for file in "${files[@]}"; do
        cp "$backup/$(basename "$file")" "$file"
    done

    rm -rf "$tests" "$backup"
}

for file in "${files[@]}"; do
    cp "$file" "$backup/"
done

trap restore EXIT

python3 -I "$skill/scripts/patch.py" "$package"
mkdir -p "$tests"
sed "s|__OUT__|$out|" "$template" > "$tests/RenderTests.swift"

cd "$package"

set +e
xcodebuild test \
    -scheme KakeibotApp-Package \
    -destination "id=$device" \
    -only-testing:AppWidgetSnapshotTests 2>&1 | grep -E "error:|TEST (SUCCEEDED|FAILED)"
set -e

ls "$out"/*.png
