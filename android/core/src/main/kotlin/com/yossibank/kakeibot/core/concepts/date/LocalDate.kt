package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.time.Instant
import java.time.ZoneId

@ConsistentCopyVisibility
@Serializable(with = LocalDateSerializer::class)
data class LocalDate private constructor(
    val yearMonth: YearMonth,
    val day: Int,
) : Comparable<LocalDate> {
    val year: Int
        get() = yearMonth.year

    val month: Int
        get() = yearMonth.month

    val weekday: Weekday
        get() = Weekday.of(daysSinceMonday = dayNumber)

    internal val dayNumber: Int
        get() = yearMonth.firstDayNumber + day - 1

    fun adding(days: Int): LocalDate = ofDayNumber(dayNumber + days)

    fun days(until: LocalDate): Int = until.dayNumber - dayNumber

    fun startOfDay(timeZone: ZoneId): Instant {
        val epochDay = dayNumber - unixEpochDayNumber

        return java.time.LocalDate.ofEpochDay(epochDay.toLong())
            .atStartOfDay(timeZone)
            .toInstant()
    }

    fun periodMonth(startingOn: MonthStartDay): YearMonth {
        val startMonth = startingOn.startMonth(ofPeriodContaining = this)

        return startingOn.periodMonth(startingIn = startMonth)
    }

    fun week(startingOn: Weekday): ClosedRange<LocalDate> {
        val difference = weekday.daysSinceMonday - startingOn.daysSinceMonday
        val offset = (difference + 7) % 7
        val start = adding(days = -offset)

        return start..start.adding(days = 6)
    }

    internal fun period(startingOn: MonthStartDay): ClosedRange<LocalDate> {
        val startMonth = startingOn.startMonth(ofPeriodContaining = this)

        return startingOn.period(startingIn = startMonth)
    }

    override fun compareTo(other: LocalDate): Int {
        val monthOrder = yearMonth.compareTo(other.yearMonth)

        return if (monthOrder != 0) monthOrder else day.compareTo(other.day)
    }

    override fun toString(): String {
        val dayText = DateText.padded(
            value = day,
            digits = 2,
        )

        return "$yearMonth-$dayText"
    }

    companion object {
        private const val SECONDS_PER_DAY = 86400L
        private const val DAYS_PER_400_YEARS = 146_097L
        private val unixEpochDayNumber = YearMonth.ofMonthIndex(1970 * 12).firstDayNumber

        fun of(
            yearMonth: YearMonth,
            day: Int,
        ): LocalDate? {
            if (day !in 1..yearMonth.numberOfDays) {
                return null
            }

            return LocalDate(
                yearMonth = yearMonth,
                day = day,
            )
        }

        fun of(
            year: Int,
            month: Int,
            day: Int,
        ): LocalDate? {
            val yearMonth = YearMonth.of(
                year = year,
                month = month,
            ) ?: return null

            return of(
                yearMonth = yearMonth,
                day = day,
            )
        }

        fun parse(text: String): LocalDate? {
            val numbers = DateText.numbers(
                text = text,
                digits = listOf(4, 2, 2),
            ) ?: return null

            if (numbers[0] !in DateText.yearRange) {
                return null
            }

            return of(
                year = numbers[0],
                month = numbers[1],
                day = numbers[2],
            )
        }

        fun of(
            instant: Instant,
            timeZone: ZoneId,
        ): LocalDate {
            val offset = timeZone.rules.getOffset(instant).totalSeconds
            val localSeconds = instant.epochSecond + offset
            val days = Math.floorDiv(localSeconds, SECONDS_PER_DAY).toInt()

            return ofDayNumber(unixEpochDayNumber + days)
        }

        internal fun ofClamped(
            yearMonth: YearMonth,
            clampedDay: Int,
        ): LocalDate = LocalDate(
            yearMonth = yearMonth,
            day = clampedDay.coerceIn(1, yearMonth.numberOfDays),
        )

        internal fun ofDayNumber(dayNumber: Int): LocalDate {
            val estimatedYear = (dayNumber.toLong() * 400 / DAYS_PER_400_YEARS).toInt() + 1
            var yearMonth = YearMonth.ofMonthIndex(estimatedYear * 12)

            while (yearMonth.firstDayNumber > dayNumber) {
                yearMonth = yearMonth.adding(months = -1)
            }

            while (yearMonth.adding(months = 1).firstDayNumber <= dayNumber) {
                yearMonth = yearMonth.adding(months = 1)
            }

            return LocalDate(
                yearMonth = yearMonth,
                day = dayNumber - yearMonth.firstDayNumber + 1,
            )
        }
    }
}

object LocalDateSerializer : KSerializer<LocalDate> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "LocalDate",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: LocalDate,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): LocalDate {
        val text = decoder.decodeString()

        return LocalDate.parse(text) ?: throw SerializationException("Invalid date: $text")
    }
}
