package com.yossibank.kakeibot.store.writes.types

data class DeletionSubject(
    val kind: Kind,
    val count: Int,
    val names: List<String>,
) {
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

    internal constructor(
        kind: Kind,
        names: List<String?>,
    ) : this(
        kind = kind,
        count = names.size,
        names = names.mapNotNull { name -> name?.ifEmpty { null } },
    )
}

val Deletion.subject: DeletionSubject?
    get() = when {
        wallets.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.wallet, wallets.map { it.name })
        categories.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.category, categories.map { it.name })
        recurrings.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.recurring, recurrings.map { it.memo })
        templates.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.template, templates.map { it.name })
        rewardRules.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.rewardRule, rewardRules.map { it.name })
        themes.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.theme, themes.map { it.name })
        shelfIcons.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.shelfIcon, shelfIcons.map { null })
        valuations.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.valuation, valuations.map { null })
        adjustments.isNotEmpty() -> DeletionSubject(DeletionSubject.Kind.adjustment, adjustments.map { null })
        else -> null
    }
