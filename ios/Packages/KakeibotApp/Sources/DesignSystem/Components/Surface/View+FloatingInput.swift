import SwiftUI
import UIKit

public extension View {
    func floatingInput(
        isPresented: Bool,
        onDismiss: @escaping () -> Void,
        @ViewBuilder card: () -> some View
    ) -> some View {
        modifier(
            FloatingInputLayer(
                isPresented: isPresented,
                onDismiss: onDismiss,
                card: card()
            )
        )
    }
}

private struct FloatingInputLayer<Card: View>: ViewModifier {
    @State private var keyboardOverlap: CGFloat = 0

    let isPresented: Bool
    let onDismiss: () -> Void
    let card: Card

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)
                    .transition(.opacity)
                    .zIndex(1)

                card
                    .padding(.horizontal, Self.inset)
                    .padding(.bottom, Self.inset + keyboardOverlap)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .background {
                        KeyboardOverlapReader { overlap in
                            withAnimation(.snappy(duration: 0.25)) {
                                keyboardOverlap = overlap
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .transition(Self.transition)
                    .zIndex(1)
            }
        }
    }
}

private extension FloatingInputLayer {
    static var inset: CGFloat {
        12
    }

    static var transition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }
}

private struct KeyboardOverlapReader: UIViewRepresentable {
    let onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> KeyboardOverlapView {
        let view = KeyboardOverlapView()

        view.onChange = onChange

        return view
    }

    func updateUIView(
        _ view: KeyboardOverlapView,
        context: Context
    ) {
        view.onChange = onChange
    }
}

private final class KeyboardOverlapView: UIView {
    var onChange: ((CGFloat) -> Void)?

    private var overlap: CGFloat = 0

    private let gauge = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        gauge.isHidden = true
        gauge.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gauge)

        NSLayoutConstraint.activate([
            gauge.topAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            gauge.leadingAnchor.constraint(equalTo: leadingAnchor),
            gauge.widthAnchor.constraint(equalToConstant: 1),
            gauge.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        report()
    }
}

private extension KeyboardOverlapView {
    func report() {
        let hidden = max(bounds.maxY - gauge.frame.minY, 0)

        guard
            window != nil,
            abs(hidden - overlap) > 0.5
        else {
            return
        }

        overlap = hidden

        DispatchQueue.main.async { [onChange] in
            onChange?(hidden)
        }
    }
}
