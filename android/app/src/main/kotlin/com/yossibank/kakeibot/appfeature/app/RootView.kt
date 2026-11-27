package com.yossibank.kakeibot.appfeature.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import com.yossibank.kakeibot.appfeature.main.MainView
import com.yossibank.kakeibot.designsystem.theme.FontTextStyle
import com.yossibank.kakeibot.designsystem.theme.Palette
import com.yossibank.kakeibot.designsystem.theme.PaletteScene
import com.yossibank.kakeibot.designsystem.theme.textFont
import com.yossibank.kakeibot.notifications.NotificationScheduler
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.file
import java.time.Instant

@Composable
fun RootView(
    link: String?,
    onOpenLink: () -> Unit,
) {
    val context = LocalContext.current.applicationContext
    val model: AppModel = viewModel { AppModel(scheduler = NotificationScheduler(context)) }

    val openDatabase: suspend () -> AppDatabase = {
        AppDatabase.file(context, now = Instant.now())
    }

    LaunchedEffect(model) {
        model.open(openDatabase)
    }

    LifecycleResumeEffect(model) {
        model.refreshDay()
        onPauseOrDispose {}
    }

    PaletteScene(
        look = model.input.look,
        style = model.input.style,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Palette.background),
            contentAlignment = Alignment.Center,
        ) {
            when (val launch = model.state.launch) {
                AppModel.Launch.Opening -> CircularProgressIndicator(color = Palette.accent)

                is AppModel.Launch.Ready -> MainView(
                    parts = launch.parts,
                    today = model.input.today,
                    link = link,
                    onOpenLink = onOpenLink,
                )

                AppModel.Launch.Failed -> OpenFailedView {
                    model.retryOpen(openDatabase)
                }
            }
        }
    }
}

@Composable
private fun OpenFailedView(onRetry: () -> Unit) {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "データを開けませんでした",
            color = Palette.text,
            style = textFont(style = FontTextStyle.Title3),
        )

        Text(
            text = "もう一度試す",
            modifier = Modifier
                .clickable(onClick = onRetry)
                .padding(8.dp),
            color = Palette.accent,
        )
    }
}
