package com.yossibank.kakeibot.core.concepts.theme

import com.yossibank.kakeibot.core.shared.Identifier
import java.time.Instant

data class Theme(
    val id: Identifier<Theme> = Identifier(),
    val name: String,
    val background: String,
    val surface: String,
    val textPrimary: String,
    val textSecondary: String,
    val accent: String,
    val expense: String,
    val income: String,
    val cornerRadius: Int,
    val fontId: String,
    val isBuiltin: Boolean,
    val createdAt: Instant,
    val updatedAt: Instant,
) {
    val palette: ThemePalette
        get() = ThemeDraft(this).palette ?: ThemePalette.night
}
