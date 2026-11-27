package com.yossibank.kakeibot.store.writes.types

import com.yossibank.kakeibot.store.writes.types.DeletionSubject.Kind

data class DeletionSubject(
    val kind: Kind,
    val count: Int,
    val names: List<String>,
) {
    internal constructor(
        kind: Kind,
        names: List<String?>,
    ) : this(
        kind = kind,
        count = names.size,
        names = names.mapNotNull { name -> name?.ifEmpty { null } },
    )

    enum class Kind {
        wallet,
        category,
        recurring,
        template,
        rewardRule,
        theme,
        shelfIcon,
        valuation,
        adjustment,
    }
}

val Deletion.subject: DeletionSubject?
    get() = when {
        wallets.isNotEmpty() -> DeletionSubject(Kind.wallet, wallets.map { it.name })
        categories.isNotEmpty() -> DeletionSubject(Kind.category, categories.map { it.name })
        recurrings.isNotEmpty() -> DeletionSubject(Kind.recurring, recurrings.map { it.memo })
        templates.isNotEmpty() -> DeletionSubject(Kind.template, templates.map { it.name })
        rewardRules.isNotEmpty() -> DeletionSubject(Kind.rewardRule, rewardRules.map { it.name })
        themes.isNotEmpty() -> DeletionSubject(Kind.theme, themes.map { it.name })
        shelfIcons.isNotEmpty() -> DeletionSubject(Kind.shelfIcon, shelfIcons.map { null })
        valuations.isNotEmpty() -> DeletionSubject(Kind.valuation, valuations.map { null })
        adjustments.isNotEmpty() -> DeletionSubject(Kind.adjustment, adjustments.map { null })
        else -> null
    }
