import sys

package = sys.argv[1]

FAMILY = "    @Environment(\\.widgetFamily) private var family\n\n    let entry: BudgetWidgetEntry\n"
INJECTED = "    let entry: BudgetWidgetEntry\n    var family: WidgetFamily = .systemSmall\n"
ANCHOR = '        .testTarget(\n            name: "AppFeatureTests",'
TARGET = """        .testTarget(
            name: "AppWidgetSnapshotTests",
            dependencies: [
                "AppWidget",
                "DesignSystem",
                .product(name: "Core", package: "KakeibotKit")
            ]
        ),
"""


def replace(path, old, new):
    text = open(path, encoding="utf-8").read()
    if old not in text:
        sys.exit(f"NG 書き換える場所が見つからない: {path}")
    open(path, "w", encoding="utf-8").write(text.replace(old, new, 1))


for view in ("BudgetWidgetView", "BudgetLockWidgetView"):
    replace(f"{package}/Sources/AppWidget/{view}.swift", FAMILY, INJECTED)

replace(f"{package}/Package.swift", ANCHOR, TARGET + ANCHOR)
