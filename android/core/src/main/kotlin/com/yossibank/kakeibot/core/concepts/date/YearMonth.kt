package com.yossibank.kakeibot.core.concepts.date

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@ConsistentCopyVisibility
@Serializable(with = YearMonthSerializer::class)
data class YearMonth private constructor(
    val year: Int,
    val month: Int,
) : Comparable<YearMonth> {
    val numberOfDays: Int
        get() = when (month) {
            2 -> if (isLeapYear) 29 else 28
            4, 6, 9, 11 -> 30
            else -> 31
        }

    internal val monthIndex: Int
        get() = year * 12 + month - 1

    internal val firstDayNumber: Int
        get() {
            val previousYear = year - 1
            val leapDays = leapDays(previousYear)
            val daysBeforeYear = previousYear * 365 + leapDays
            val leapDayThisYear = if (month > 2 && isLeapYear) 1 else 0
            val commonDays = daysBeforeMonthInCommonYear[month - 1]
            val daysBeforeMonth = commonDays + leapDayThisYear

            return daysBeforeYear + daysBeforeMonth
        }

    private val isLeapYear: Boolean
        get() {
            val isFourth = year % 4 == 0
            val isCentury = year % 100 == 0

            return isFourth && (!isCentury || year % 400 == 0)
        }

    fun adding(months: Int): YearMonth = ofMonthIndex(monthIndex + months)

    fun weeks(startingOn: Weekday): List<List<LocalDate?>> {
        val first = LocalDate.ofClamped(
            yearMonth = this,
            clampedDay = 1,
        )

        val last = first.adding(days = numberOfDays - 1)

        return (first..last).weeks(startingOn)
    }

    fun period(startingOn: MonthStartDay): ClosedRange<LocalDate> {
        val startMonth = startingOn.startMonth(ofPeriodIn = this)

        return startingOn.period(startingIn = startMonth)
    }

    override fun compareTo(other: YearMonth): Int = monthIndex.compareTo(other.monthIndex)

    override fun toString(): String {
        val yearText = DateText.padded(
            value = year,
            digits = 4,
        )

        val monthText = DateText.padded(
            value = month,
            digits = 2,
        )

        return "$yearText-$monthText"
    }

    companion object {
        private val daysBeforeMonthInCommonYear = listOf(
            0,
            31,
            59,
            90,
            120,
            151,
            181,
            212,
            243,
            273,
            304,
            334,
        )

        fun of(
            year: Int,
            month: Int,
        ): YearMonth? {
            if (month !in 1..12) {
                return null
            }

            return YearMonth(
                year = year,
                month = month,
            )
        }

        fun parse(text: String): YearMonth? {
            val numbers = DateText.numbers(
                text = text,
                digits = listOf(4, 2),
            ) ?: return null

            if (numbers[0] !in DateText.yearRange) {
                return null
            }

            return of(
                year = numbers[0],
                month = numbers[1],
            )
        }

        internal fun ofMonthIndex(monthIndex: Int): YearMonth {
            val year = Math.floorDiv(monthIndex, 12)

            return YearMonth(
                year = year,
                month = monthIndex - year * 12 + 1,
            )
        }

        private fun leapDays(year: Int): Int =
            Math.floorDiv(year, 4) - Math.floorDiv(year, 100) + Math.floorDiv(year, 400)
    }
}

object YearMonthSerializer : KSerializer<YearMonth> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "YearMonth",
        PrimitiveKind.STRING,
    )

    override fun serialize(
        encoder: Encoder,
        value: YearMonth,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): YearMonth {
        val text = decoder.decodeString()

        return YearMonth.parse(text) ?: throw SerializationException("Invalid year-month: $text")
    }
}
