import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletListView: View {
    @State private var model: WalletListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var openId: Wallet.ID?
    @State private var hideZone: CGRect = .zero
    @State private var isOverHideZone = false
    @State private var hiding: Wallet?
    @State private var isConfirmingHide = false

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: WalletListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text("長押しで動かせます。下の枠に置くか、横に払うと非表示になります")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    board

                    if lift != nil {
                        hideTarget
                    } else if !model.hidden.isEmpty {
                        hiddenSection
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil)

            AddButton("口座を追加") {
                sheet = .new
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
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
        .confirmsWalletHide(
            balance: hidingBalance,
            isPresented: $isConfirmingHide
        ) {
            if let hiding {
                Task {
                    await model.hide(hiding.id)
                }
            }
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

            Text("口座")
                .font(.serif(.body))
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

    var hideTarget: some View {
        SettingsHideZone(isTargeted: isOverHideZone, height: Self.rowHeight)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(Self.space))
            } action: { frame in
                hideZone = frame
            }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionTitle("非表示の口座")

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

    func movableRow(_ wallet: Wallet) -> some View {
        let isLifted = lift?.id == wallet.id
        let index = model.shown.firstIndex(of: wallet) ?? 0
        let y = isLifted ? liftedCenterY : centerY(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: wallet.id, openId: $openId, role: .hide) {
            sheet = .edit(wallet.id)
        } onAction: {
            requestHide(wallet)
        } content: {
            row(wallet)
        }
        .frame(height: Self.rowHeight)
        .scaleEffect(scale)
        .shadow(color: shadow, radius: 16, y: 8)
        .offset(y: y - Self.rowHeight / 2)
        .zIndex(layer)
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
                    Palette.gold.opacity(.subtle),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Palette.gold.opacity(.muted), lineWidth: 1)
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
                .font(.serif(.body))
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
    var boardHeight: CGFloat {
        let count = CGFloat(model.shown.count)
        let gaps = Self.spacing * max(count - 1, 0)
        return Self.rowHeight * count + gaps
    }

    var hidingBalance: Int {
        hiding.map { model.balance(of: $0) } ?? 0
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
        isOverHideZone = hideZone.contains(location)

        guard !isOverHideZone else {
            return
        }

        let target = index(at: liftedCenterY)

        withAnimation(.snappy) {
            model.move(wallet.id, to: target)
        }
    }

    func drop() {
        guard let lift else {
            return
        }

        if isOverHideZone {
            let wallet = model.shown.first { $0.id == lift.id }

            withAnimation(.snappy) {
                self.lift = nil
                isOverHideZone = false
                model.cancelMoving()
            }

            if let wallet {
                requestHide(wallet)
            }

            return
        }

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    func requestHide(_ wallet: Wallet) {
        guard model.balance(of: wallet) == 0 else {
            hiding = wallet
            isConfirmingHide = true
            return
        }

        Task {
            await model.hide(wallet.id)
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
