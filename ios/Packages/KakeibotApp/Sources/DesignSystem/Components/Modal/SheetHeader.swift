import SwiftUI

public struct SheetHeader<Title: View, Trailing: View>: View {
    private let onClose: () -> Void
    private let title: Title
    private let trailing: Trailing

    public init(
        onClose: @escaping () -> Void,
        @ViewBuilder title: () -> Title,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.onClose = onClose
        self.title = title()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack {
            RingButton(systemImage: "xmark", action: onClose)

            Spacer()

            title

            Spacer()

            trailing
        }
    }
}

public extension SheetHeader where Trailing == SheetHeaderSlot {
    init(
        onClose: @escaping () -> Void,
        @ViewBuilder title: () -> Title
    ) {
        self.init(onClose: onClose, title: title) {
            SheetHeaderSlot()
        }
    }
}

public extension SheetHeader where Title == SheetTitle {
    init(
        _ text: String,
        onClose: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(onClose: onClose) {
            SheetTitle(text)
        } trailing: {
            trailing()
        }
    }
}

public extension SheetHeader where Title == SheetTitle, Trailing == SheetHeaderSlot {
    init(
        _ text: String,
        onClose: @escaping () -> Void
    ) {
        self.init(text, onClose: onClose) {
            SheetHeaderSlot()
        }
    }
}

public struct SheetHeaderSlot: View {
    public init() {}

    public var body: some View {
        Color.clear
            .frame(width: 44, height: 44)
    }
}

#Preview {
    VStack(spacing: 24) {
        SheetHeader("お知らせ") {}

        SheetHeader("テンプレート") {} trailing: {
            RingButton(systemImage: "plus") {}
        }
    }
    .padding()
    .background(Palette.background)
}
