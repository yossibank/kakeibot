package com.yossibank.kakeibot.features.shared.tab

import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.TabScreenModel
import com.yossibank.kakeibot.features.shared.notice.TabNoticeRound
import com.yossibank.kakeibot.features.shared.observation.rememberObservationRound
import com.yossibank.kakeibot.features.shared.placeholder.LoadFailedColumn

@Composable
fun <Model : TabScreenModel> rememberTabModel(
    parts: ScreenParts,
    today: LocalDate,
    make: (ObservationRound) -> Model,
): Model {
    val round = rememberObservationRound()
    val model = remember(parts, round) { make(round) }

    SideEffect {
        model.setToday(today)
    }

    return model
}

@Composable
fun TabScreen(
    model: TabScreenModel,
    content: LazyListScope.() -> Unit,
) {
    LaunchedEffect(model) {
        model.observe()
    }

    model.task.Timer()
    TabNoticeRound(model.task)

    LoadFailedColumn(
        isFailed = model.isLoadFailed,
        onRetry = model::retry,
        content = content,
    )
}
