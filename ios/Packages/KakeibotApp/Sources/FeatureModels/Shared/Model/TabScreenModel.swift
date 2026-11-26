import Core

@MainActor
public protocol TabScreenModel: ScreenModel {
    var isLoadFailed: Bool { get }

    func setToday(_ today: LocalDate)
}
