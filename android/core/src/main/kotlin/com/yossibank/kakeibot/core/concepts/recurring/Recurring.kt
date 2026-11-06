package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import kotlinx.serialization.Serializable
import java.time.Instant

data class Recurring(
    val id: Identifier<Recurring> = Identifier(),
    val type: Entry.Kind,
    val amount: Int,
    val categoryId: Identifier<EntryCategory>?,
    val walletId: Identifier<Wallet>,
    val toWalletId: Identifier<Wallet>? = null,
    val memo: String? = null,
    val frequency: Frequency,
    val month: Int? = null,
    val day: Int,
    val holidayShift: HolidayShift = HolidayShift.none,
    val closingDay: Int? = null,
    val fee: Int? = null,
    val finalAmount: Int? = null,
    val billShift: Int = 0,
    val startDate: LocalDate,
    val endDate: LocalDate? = null,
    val remindDaysBefore: Int? = null,
    val generatedUntil: LocalDate? = null,
    val sortOrder: Int = 0,
    val archivedAt: Instant? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    @Serializable
    enum class Frequency(
        val rawValue: String,
    ) {
        monthly("monthly"),
        yearly("yearly"),
        ;

        companion object {
            fun of(rawValue: String): Frequency? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    data class Occurrence(
        val scheduled: LocalDate,
        val date: LocalDate,
    )

    companion object
}

fun Recurring.title(categoryName: String?): String? = memo?.takeIf { it.isNotEmpty() } ?: categoryName
