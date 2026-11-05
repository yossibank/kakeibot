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
@Serializable(with = MonthStartDaySerializer::class)
data class MonthStartDay private constructor(
    val day: Int,
    val shift: HolidayShift = HolidayShift.none,
) {
    val isLastDay: Boolean
        get() = day == 31

    fun shifted(by: HolidayShift): MonthStartDay = MonthStartDay(
        day = day,
        shift = by,
    )

    internal fun date(yearMonth: YearMonth): LocalDate {
        val date = LocalDate.ofClamped(
            yearMonth = yearMonth,
            clampedDay = day,
        )

        return shift.apply(to = date)
    }

    internal fun period(startingIn: YearMonth): ClosedRange<LocalDate> {
        val start = date(startingIn)
        val nextMonth = startingIn.adding(months = 1)
        val end = date(nextMonth).adding(days = -1)

        return start..end
    }

    internal fun periodMonth(startingIn: YearMonth): YearMonth =
        if (day == 1) startingIn else startingIn.adding(months = 1)

    internal fun startMonth(ofPeriodIn: YearMonth): YearMonth =
        if (day == 1) ofPeriodIn else ofPeriodIn.adding(months = -1)

    internal fun startMonth(ofPeriodContaining: LocalDate): YearMonth {
        val candidates = (-2..1).map { ofPeriodContaining.yearMonth.adding(months = it) }

        return candidates.firstOrNull { ofPeriodContaining in period(startingIn = it) }
            ?: ofPeriodContaining.yearMonth
    }

    companion object {
        val first: MonthStartDay
            get() = MonthStartDay(day = 1)

        val allDays: List<MonthStartDay>
            get() = (1..31).map { MonthStartDay(day = it) }

        fun of(
            day: Int,
            shift: HolidayShift = HolidayShift.none,
        ): MonthStartDay? {
            if (day !in 1..31) {
                return null
            }

            return MonthStartDay(
                day = day,
                shift = shift,
            )
        }
    }
}

object MonthStartDaySerializer : KSerializer<MonthStartDay> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "MonthStartDay",
        PrimitiveKind.INT,
    )

    override fun serialize(
        encoder: Encoder,
        value: MonthStartDay,
    ) {
        encoder.encodeInt(value.day)
    }

    override fun deserialize(decoder: Decoder): MonthStartDay {
        val day = decoder.decodeInt()

        return MonthStartDay.of(day) ?: throw SerializationException("Invalid month start day: $day")
    }
}
