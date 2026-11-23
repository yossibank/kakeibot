package com.yossibank.kakeibot.features.screens.entry.voice

import java.util.UUID

data class EntryVoiceResult(
    val outcome: Outcome,
    val count: Int,
    val text: String,
    val id: UUID = UUID.randomUUID(),
) {
    enum class Outcome {
        Applied,
        MissingAmount,
        Unheard,
        Failed,
        Downloading,
        Unsupported,
    }

    val title: String
        get() = when (outcome) {
            Outcome.Applied -> "声から $count つ入れました"
            Outcome.MissingAmount -> "金額が聞き取れませんでした"
            Outcome.Unheard -> if (text.isEmpty()) "聞き取れませんでした" else "入れられる項目がありませんでした"
            Outcome.Failed -> "声を聞き取れませんでした。もう一度押してください"
            Outcome.Downloading -> "日本語の音声認識を準備しています"
            Outcome.Unsupported -> "この端末では日本語の音声認識が使えません"
        }

    val message: String?
        get() = if (text.isEmpty()) null else "「$text」"

    val hint: String?
        get() = when (outcome) {
            Outcome.Applied -> null
            Outcome.Downloading -> "日本語のデータを入れ終えてから、もう一度押してください"
            Outcome.Unsupported -> "テンキーで入れてください"
            else -> "もう一度「声」を押して話すか、テンキーで入れてください"
        }

    val canUndo: Boolean
        get() = outcome == Outcome.Applied
}
