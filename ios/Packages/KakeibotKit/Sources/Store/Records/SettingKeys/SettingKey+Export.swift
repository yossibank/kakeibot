import Core

extension Setting.Key {
    static let deviceOnly = Set(allCases.filter(\.isDeviceOnly).map(\.rawValue))
    static let exported = allCases.filter(\.isExported).map(\.rawValue)

    var isDeviceOnly: Bool {
        switch self {
        case .onboardingCompleted, .setupCardClosed, .entryOpened, .settingsOpened: true
        case .closedHints, .closedHiddenLists, .recentSearches, .widgetEntry: true
        default: false
        }
    }

    var isExported: Bool {
        self != .backupExportedAt
    }
}
