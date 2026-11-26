package com.yossibank.kakeibot.core.concepts.voice

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.Weekday

internal fun VoiceText.Companion.number(token: String): Int? {
    token.toIntOrNull()?.let { return it }

    var total = 0
    var section = 0
    var current: Int? = null

    for (character in token) {
        val unit = smallUnits[character]
        val digit = digit(character)

        when {
            unit != null -> {
                section += (current ?: 1) * unit
                current = null
            }

            digit != null -> {
                current = (current ?: 0) * 10 + digit
            }

            character == '万' -> {
                total += (section + (current ?: 0)) * 10000
                section = 0
                current = null
            }

            else -> {
                return null
            }
        }
    }

    val value = total + section + (current ?: 0)

    return if (value > 0) value else null
}

internal fun VoiceText.amount(skipping: VoiceText.Span?): VoiceText.Found<Int>? {
    val withYen = yenPattern
        .findAll(text)
        .filterNot { overlaps(it.span, skipping) }
        .mapNotNull { match ->
            VoiceText.number(match.groupValues[1])?.let { VoiceText.Found(it, match.span) }
        }.lastOrNull { it.value in 1..MAX_AMOUNT }

    if (withYen != null) {
        return withYen
    }

    val withSign = signPattern
        .findAll(text)
        .filterNot { overlaps(it.span, skipping) }
        .mapNotNull { match ->
            match.groupValues[1].toIntOrNull()?.let { VoiceText.Found(it, match.span) }
        }.lastOrNull { it.value in 1..MAX_AMOUNT }

    if (withSign != null) {
        return withSign
    }

    return barePattern
        .findAll(text)
        .filterNot { overlaps(it.span, skipping) }
        .mapNotNull { match ->
            match.groupValues[1].toIntOrNull()?.let { VoiceText.Found(it, match.span) }
        }.firstOrNull { it.value in 1..MAX_AMOUNT }
}

internal fun VoiceText.date(today: LocalDate): VoiceText.Found<LocalDate>? {
    for ((word, days) in relativeDays) {
        val start = text.indexOf(word)

        if (start >= 0) {
            return VoiceText.Found(
                today.adding(days = days),
                VoiceText.Span(
                    start,
                    start + word.length,
                ),
            )
        }
    }

    daysAgoPattern.find(text)?.let { match ->
        val days = VoiceText.number(match.groupValues[1])

        if (days != null && days <= MAX_DAYS_AGO) {
            return VoiceText.Found(today.adding(days = -days), match.span)
        }
    }

    weekdayPattern.find(text)?.let { match ->
        val weekday = weekdays[match.groupValues[2]]

        if (weekday != null) {
            val isLastWeek = match.groups[1] != null

            return VoiceText.Found(
                recent(weekday = weekday, lastWeek = isLastWeek, today = today),
                match.span,
            )
        }
    }

    monthDayPattern.find(text)?.let { match ->
        val month = VoiceText.number(match.groupValues[1])
        val day = VoiceText.number(match.groupValues[2])

        val date = if (month != null &&
            day != null
        ) {
            recent(month = month, day = day, today = today)
        } else {
            null
        }

        if (date != null) {
            return VoiceText.Found(date, match.span)
        }
    }

    dayPattern.find(text)?.let { match ->
        val day = VoiceText.number(match.groupValues[1])
        val date = day?.let { recent(day = it, today = today) }

        if (date != null) {
            return VoiceText.Found(date, match.span)
        }
    }

    return null
}

private val MatchResult.span: VoiceText.Span
    get() = VoiceText.Span(range.first, range.last + 1)

private fun overlaps(
    range: VoiceText.Span,
    other: VoiceText.Span?,
): Boolean = other?.let(range::overlaps) ?: false

private fun digit(character: Char): Int? {
    if (character.code < 128) {
        return character.digitToIntOrNull()
    }

    return kanjiDigits[character]
}

private fun recent(
    weekday: Weekday,
    lastWeek: Boolean,
    today: LocalDate,
): LocalDate {
    val todayIndex = today.weekday.daysSinceMonday
    val targetIndex = weekday.daysSinceMonday

    if (!lastWeek) {
        return today.adding(days = -((todayIndex - targetIndex + 7) % 7))
    }

    return today.adding(days = targetIndex - todayIndex - 7)
}

private fun recent(
    month: Int,
    day: Int,
    today: LocalDate,
): LocalDate? {
    val date = LocalDate.of(year = today.year, month = month, day = day) ?: return null
    return if (date > today) LocalDate.of(year = today.year - 1, month = month, day = day) else date
}

private fun recent(
    day: Int,
    today: LocalDate,
): LocalDate? {
    val date = LocalDate.of(yearMonth = today.yearMonth, day = day)

    if (date != null && date <= today) {
        return date
    }

    return LocalDate.of(yearMonth = today.yearMonth.adding(months = -1), day = day)
}

private const val MAX_AMOUNT = 999_999_999
private const val MAX_DAYS_AGO = 60

private val relativeDays = listOf(
    "一昨日" to -2,
    "おととい" to -2,
    "昨日" to -1,
    "きのう" to -1,
    "昨夜" to -1,
    "昨晩" to -1,
    "ゆうべ" to -1,
    "今日" to 0,
    "きょう" to 0,
    "今朝" to 0,
    "今夜" to 0,
    "今晩" to 0,
)

private val weekdays = mapOf(
    "月" to Weekday.monday,
    "火" to Weekday.tuesday,
    "水" to Weekday.wednesday,
    "木" to Weekday.thursday,
    "金" to Weekday.friday,
    "土" to Weekday.saturday,
    "日" to Weekday.sunday,
)

private val kanjiDigits = mapOf(
    '〇' to 0,
    '零' to 0,
    '一' to 1,
    '二' to 2,
    '三' to 3,
    '四' to 4,
    '五' to 5,
    '六' to 6,
    '七' to 7,
    '八' to 8,
    '九' to 9,
)

private val smallUnits = mapOf(
    '十' to 10,
    '百' to 100,
    '千' to 1000,
)

private val yenPattern = Regex("([0-9〇零一二三四五六七八九十百千万]+)\\s*(?:円|えん)")
private val signPattern = Regex("¥\\s*([0-9]+)")
private val daysAgoPattern = Regex("([0-9〇一二三四五六七八九十]{1,3})日前")
private val weekdayPattern = Regex("(先週の?)?([月火水木金土日])曜日?")
private val barePattern = Regex("([0-9]+)(?![0-9])(?!\\s*[日月年時分秒個つ人回件%％番])")
private val monthDayPattern = Regex("([0-9〇一二三四五六七八九十]{1,3})月([0-9〇一二三四五六七八九十]{1,3})日")
private val dayPattern = Regex("([0-9〇一二三四五六七八九十]{1,3})日(?![前間分])")
