import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletListView: View {
    @State private var model: WalletListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: WalletListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text("長押しで動かせます。この順で入力シートと資産タブに出ます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    board

                    if !model.hidden.isEmpty {
                        hiddenSection
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil)

            addButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sheet(item: $sheet) { sheet in
            WalletEditSheet(model: editModel(for: sheet))
        }
        .task {
            await model.observe()
        }
    }
}

private extension WalletListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("財布")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var board: some View {
        ZStack(alignment: .top) {
            ForEach(model.shown) { wallet in
                movableRow(wallet)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: boardHeight, alignment: .top)
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionTitle("非表示の財布")

            ForEach(model.hidden) { wallet in
                Button {
                    sheet = .edit(wallet.id)
                } label: {
                    row(wallet)
                        .opacity(0.5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var addButton: some View {
        Button {
            sheet = .new
        } label: {
            Label("財布を追加", systemImage: "plus")
                .font(.subheadline)
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.gold.opacity(0.06), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.gold.opacity(0.55), style: Self.dash)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func movableRow(_ wallet: Wallet) -> some View {
        let isLifted = lift?.id == wallet.id
        let index = model.shown.firstIndex(of: wallet) ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return row(wallet)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(y: y - Self.rowHeight / 2)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(wallet.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(wallet, to: location)
                } onEnd: {
                    drop()
                }
            )
    }

    func row(_ wallet: Wallet) -> some View {
        let balance = model.balance(of: wallet)
        let balanceColor = balance < 0 ? Palette.rose : Palette.champagne

        return HStack(spacing: 14) {
            IconImage(model.icon(for: wallet), size: 18)
                .foregroundStyle(Palette.gold)
                .frame(width: 40, height: 40)
                .background(
                    Palette.gold.opacity(0.1),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(wallet.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(wallet.kind.title)
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.mist)
            }

            Spacer(minLength: 8)

            Text(AmountText.text(balance))
                .font(.system(size: 17, design: .serif))
                .monospacedDigit()
                .foregroundStyle(balanceColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .frame(height: Self.rowHeight)
        .card(cornerRadius: 18)
        .contentShape(.rect)
    }
}

private extension WalletListView {
    struct Lift {
        let id: Wallet.ID
        var y: CGFloat
        var grab: CGFloat?
    }

    enum Sheet: Hashable, Identifiable {
        case new
        case edit(Wallet.ID)

        var id: Self {
            self
        }
    }

    nonisolated static let space = "WalletBoard"
    static let rowHeight: CGFloat = 68
    static let spacing: CGFloat = 10
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    var boardHeight: CGFloat {
        let count = CGFloat(model.shown.count)
        let gaps = Self.spacing * max(count - 1, 0)
        return Self.rowHeight * count + gaps
    }

    var liftedCenterY: CGFloat {
        guard let lift else {
            return 0
        }

        return lift.y + (lift.grab ?? 0)
    }

    func centerY(at index: Int) -> CGFloat {
        let step = Self.rowHeight + Self.spacing
        return step * CGFloat(index) + Self.rowHeight / 2
    }

    func index(at y: CGFloat) -> Int {
        let step = Self.rowHeight + Self.spacing
        let index = Int(y / step)
        return min(max(index, 0), model.shown.count - 1)
    }

    func follow(
        _ wallet: Wallet,
        to location: CGPoint
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: wallet) ?? 0
            let start = centerY(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: wallet.id, y: start)
            }

            liftCount += 1
        }

        guard var current = lift else {
            return
        }

        if current.grab == nil {
            current.grab = current.y - location.y
        }

        current.y = location.y
        lift = current

        let target = index(at: liftedCenterY)

        withAnimation(.snappy) {
            model.move(wallet.id, to: target)
        }
    }

    func drop() {
        guard lift != nil else {
            return
        }

        withAnimation(.snappy) {
            lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    func editModel(for sheet: Sheet) -> WalletEditModel {
        switch sheet {
        case .new:
            WalletEditModel(database: database)
        case let .edit(id):
            WalletEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            WalletListView(database: database)
        }
    }
}
