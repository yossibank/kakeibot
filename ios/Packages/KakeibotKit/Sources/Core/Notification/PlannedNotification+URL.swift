import Foundation

public extension PlannedNotification.Route {
    init?(url: URL) {
        guard url.scheme == Self.scheme else {
            return nil
        }

        let host = url.host() ?? ""
        self.init(link: host + url.path())
    }

    var url: URL? {
        URL(string: "\(Self.scheme)://\(link)")
    }
}

private extension PlannedNotification.Route {
    static let scheme = "kakeibot"
}
