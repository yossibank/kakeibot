package com.yossibank.kakeibot.core.concepts.export.v1

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.category.EntryTag
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.concepts.receipt.ItemName
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.wallet.Valuation
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.InstantSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import java.time.Instant

data class ExportV1(
    val exportedAt: Instant,
    val app: App,
    val data: Tables,
) {
    sealed class ReadError(
        message: String,
    ) : Exception(message) {
        data class UnknownFormat(
            val format: String,
        ) : ReadError("Unknown format: $format")

        data class UnsupportedVersion(
            val version: Int,
        ) : ReadError("Unsupported version: $version")

        data object MissingTransfer : ReadError("Missing transfer")
    }

    enum class Platform(
        val rawValue: String,
    ) {
        ios("ios"),
        android("android"),
        ;

        companion object {
            fun of(rawValue: String): Platform? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }

    data class App(
        val platform: Platform,
        val version: String,
    )

    data class Tables(
        val icons: List<Icon>,
        val shelfIcons: List<ShelfIcon> = emptyList(),
        val wallets: List<Wallet>,
        val valuations: List<Valuation> = emptyList(),
        val categories: List<EntryCategory>,
        val tags: List<EntryTag> = emptyList(),
        val entries: List<Entry>,
        val entryItems: List<EntryItem> = emptyList(),
        val itemNames: List<ItemName> = emptyList(),
        val templates: List<EntryTemplate> = emptyList(),
        val budgets: List<Budget>,
        val recurrings: List<Recurring>,
        val rewardRules: List<RewardRule>,
        val rewardLogs: List<RewardLog>,
        val rewardGoals: List<RewardGoal>,
        val calendarStamps: List<CalendarStamp>,
        val noSpendDays: List<NoSpendDay>,
        val themes: List<Theme>,
        val settings: List<Setting>,
    ) {
        internal val hasTransferForEveryFee: Boolean
            get() {
                val transfers = entries
                    .filter { it.type == Entry.Kind.transfer }
                    .map { it.id }
                    .toSet()

                return entries.mapNotNull { it.transferId }.all { it in transfers }
            }
    }

    fun json(): ByteArray {
        val root = buildJsonObject {
            put("format", FORMAT)
            put("version", VERSION)
            put("exportedAt", InstantSerializer.format(exportedAt))
            put("app", app.row())
            put("data", data.row())
        }

        return ExportJson.write(root).toByteArray(Charsets.UTF_8)
    }

    companion object {
        const val FORMAT = "kakeibot-export"
        const val VERSION = 1

        fun of(json: ByteArray): ExportV1 {
            val element = Json.parseToJsonElement(json.toString(Charsets.UTF_8))
            val root = ExportRow(element)
            val format = root.string("format")
            val version = root.int("version")

            if (format != FORMAT) {
                throw ReadError.UnknownFormat(format)
            }

            if (version != VERSION) {
                throw ReadError.UnsupportedVersion(version)
            }

            val exportedAt = root.instant("exportedAt")
            val app = root.row("app").app()
            val data = root.row("data").tables()

            if (!data.hasTransferForEveryFee) {
                throw ReadError.MissingTransfer
            }

            return ExportV1(
                exportedAt = exportedAt,
                app = app,
                data = data,
            )
        }
    }
}
