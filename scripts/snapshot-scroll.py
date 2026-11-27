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

PAGER_BODY = """    public var body: some View {
        if pages.indices.contains(current) {
            page(pages[current])
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
"""

KEY_CATCHER = """struct KeyCatcher: View {
    let onType: (String) -> Bool

    var body: some View {
        Color.clear
    }
}

struct LiveKeyCatcher: UIViewRepresentable {"""

TEXT_FIELD = """
public struct SnapshotTextField: View {
    let text: Binding<String>
    let prompt: Text?

    public init(
        _ title: some StringProtocol,
        text: Binding<String>,
        prompt: Text? = nil,
        axis: Axis = .horizontal
    ) {
        self.text = text
        self.prompt = prompt
    }

    public var body: some View {
        Group {
            if text.wrappedValue.isEmpty {
                prompt ?? Text(verbatim: "")
            } else {
                Text(text.wrappedValue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    patched = re.sub(r"\bTextField\(", "SnapshotTextField(", patched)

    if path.name == "ResizingPager.swift":
        patched = re.sub(
            r"    public var body: some View \{.*?\n    \}\n\}\n",
            PAGER_BODY,
            patched,
            count=1,
            flags=re.DOTALL,
        )

    if path.name == "FittedSheet.swift":
        patched = patched.replace("FittedDetent(height: height)", "Color.clear.frame(height: height)")

    if path.name == "KeyCatcher.swift":
        patched = patched.replace("struct KeyCatcher: UIViewRepresentable {", KEY_CATCHER)

    if re.search(r"\bSnapshot(Scroll|TextField)\b", patched) and "import DesignSystem" not in patched:
        patched = "import DesignSystem\n" + patched

    if patched != text:
        path.write_text(patched, encoding="utf-8")

(sources / "DesignSystem" / "SnapshotScroll.swift").write_text(HELPER + TEXT_FIELD, encoding="utf-8")
