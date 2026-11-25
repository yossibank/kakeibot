package com.yossibank.kakeibot.featuremodels.shared.notice

import com.yossibank.kakeibot.store.writes.types.Deletion
import com.yossibank.kakeibot.store.writes.types.DeletionSubject
import com.yossibank.kakeibot.store.writes.types.subject

object DeletionNotice {
    fun message(deletion: Deletion): String = deletion.subject?.noticeMessage ?: "削除しました"
}

val DeletionSubject.noticeMessage: String
    get() {
        val name = names.firstOrNull()

        if (count == 1 && name != null) {
            return "$name を削除しました"
        }

        if (count <= 1) {
            return "${kind.noun}を削除しました"
        }

        return "${kind.noun} $count 件を削除しました"
    }

private val DeletionSubject.Kind.noun: String
    get() = when (this) {
        DeletionSubject.Kind.wallet -> "口座"
        DeletionSubject.Kind.category -> "カテゴリ"
        DeletionSubject.Kind.recurring -> "固定費"
        DeletionSubject.Kind.template -> "テンプレート"
        DeletionSubject.Kind.rewardRule -> "決まり"
        DeletionSubject.Kind.theme -> "テーマ"
        DeletionSubject.Kind.shelfIcon -> "スタンプ"
        DeletionSubject.Kind.valuation -> "評価額"
        DeletionSubject.Kind.adjustment -> "残高の調整"
    }
