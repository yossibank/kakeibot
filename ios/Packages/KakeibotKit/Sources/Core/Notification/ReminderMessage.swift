public struct ReminderMessage: Hashable, Sendable {
    public let title: String
    public let body: String
}

public extension ReminderMessage {
    init(on weekday: Weekday) {
        switch weekday {
        case .monday:
            self.init(
                title: "今週もはじめましょう",
                body: "今日使ったお金を、さっと残しておきませんか"
            )
        case .tuesday:
            self.init(
                title: "今日の家計簿、まだ白紙です",
                body: "1 行だけでも、書いておきましょう"
            )
        case .wednesday:
            self.init(
                title: "週のなかば、ひと息つきましょう",
                body: "レシートが手元にあるうちに記録できます"
            )
        case .thursday:
            self.init(
                title: "今日のお金、覚えていますか",
                body: "使わなかった日は「支出なし」の印だけで大丈夫です"
            )
        case .friday:
            self.init(
                title: "1 週間おつかれさまでした",
                body: "今日の分を入れて、週末を軽くしましょう"
            )
        case .saturday:
            self.init(
                title: "週末のお買い物、どうでしたか",
                body: "忘れないうちに残しておきましょう"
            )
        case .sunday:
            self.init(
                title: "今週のふりかえりの前に",
                body: "今日の記録を入れると、1 週間がそろいます"
            )
        }
    }
}
