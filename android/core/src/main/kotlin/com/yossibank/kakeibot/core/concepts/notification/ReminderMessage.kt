package com.yossibank.kakeibot.core.concepts.notification

import com.yossibank.kakeibot.core.concepts.date.Weekday

data class ReminderMessage(
    val title: String,
    val body: String,
) {
    companion object {
        operator fun invoke(on: Weekday): ReminderMessage = when (on) {
            Weekday.monday -> ReminderMessage(
                title = "今週もはじめましょう",
                body = "今日使ったお金を、さっと残しておきませんか",
            )

            Weekday.tuesday -> ReminderMessage(
                title = "今日の家計簿、まだ白紙です",
                body = "1 行だけでも、書いておきましょう",
            )

            Weekday.wednesday -> ReminderMessage(
                title = "週のなかば、ひと息つきましょう",
                body = "レシートが手元にあるうちに記録できます",
            )

            Weekday.thursday -> ReminderMessage(
                title = "今日のお金、覚えていますか",
                body = "使わなかった日は「支出なし」の印だけで大丈夫です",
            )

            Weekday.friday -> ReminderMessage(
                title = "1 週間おつかれさまでした",
                body = "今日の分を入れて、週末を軽くしましょう",
            )

            Weekday.saturday -> ReminderMessage(
                title = "週末のお買い物、どうでしたか",
                body = "忘れないうちに残しておきましょう",
            )

            Weekday.sunday -> ReminderMessage(
                title = "今週のふりかえりの前に",
                body = "今日の記録を入れると、1 週間がそろいます",
            )
        }
    }
}
