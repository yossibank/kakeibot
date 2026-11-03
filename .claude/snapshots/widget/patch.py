import sys

package = sys.argv[1]

FAMILY = "    @Environment(\\.widgetFamily) private var family\n"
VIEWS = {
    "Budget/BudgetWidgetView": "BudgetWidgetEntry",
    "Budget/BudgetLockWidgetView": "BudgetWidgetEntry",
    "QuickRecord/QuickRecordWidgetView": "QuickRecordWidgetEntry",
}


def replace(path, old, new):
    text = open(path, encoding="utf-8").read()
    if old not in text:
        sys.exit(f"NG 書き換える場所が見つからない: {path}")
    open(path, "w", encoding="utf-8").write(text.replace(old, new, 1))


for view, entry in VIEWS.items():
    path = f"{package}/Sources/AppWidget/Widgets/{view}.swift"
    stored = f"    let entry: {entry}\n"
    replace(path, FAMILY, "")
    replace(path, stored, stored + "    var family: WidgetFamily = .systemSmall\n")
