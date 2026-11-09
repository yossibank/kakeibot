import pathlib
import re
import sys

sources = pathlib.Path(sys.argv[1]) / "Sources"

HELPER = """import SwiftUI

public struct SnapshotScroll<Content: View>: View {
    let isHorizontal: Bool
    let content: Content

    public init(
        _ axes: Axis.Set = .vertical,
        @ViewBuilder content: () -> Content
    ) {
        self.isHorizontal = axes == .horizontal
        self.content = content()
    }

    public var body: some View {
        if isHorizontal {
            content
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        } else {
            content
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
"""

paths = [
    *(sources / "DesignSystem").rglob("*.swift"),
    *(sources / "Features").rglob("*.swift"),
]

for path in paths:
    text = path.read_text(encoding="utf-8")
    patched = re.sub(r"\bScrollView(\(\.horizontal\))? \{", r"SnapshotScroll\1 {", text)
    patched = re.sub(r"\.contentMargins\((\.\w+), ([^,]+), for: \.scrollContent\)", r".padding(\1, \2)", patched)
    patched = patched.replace("NavigationStack {", "VStack(spacing: 0) {")
    patched = re.sub(r"containerRelativeFrame\(\.horizontal\) \{ width, _ in\s+width \* 0\.62\s+\}", "frame(width: 240)", patched)

    if path.name == "View+Glass.swift":
        patched = patched.replace("glassEffect(.regular.tint(tint).interactive(), in: shape)", "background(tint ?? Color.clear, in: shape)")

    if "SnapshotScroll" in patched and "import DesignSystem" not in patched:
        patched = "import DesignSystem\n" + patched

    if patched != text:
        path.write_text(patched, encoding="utf-8")

(sources / "DesignSystem" / "SnapshotScroll.swift").write_text(HELPER, encoding="utf-8")
