package com.yossibank.kakeibot.features.screens.entry.voice

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.featuremodels.screens.entry.model.EntryModel
import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow

@Composable
fun rememberVoiceStarter(
    voice: EntryVoiceFlow,
    model: EntryModel,
    today: LocalDate,
): () -> Unit {
    val context = LocalContext.current

    val permission = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { isGranted ->
        if (isGranted) {
            voice.start(
                model = model,
                today = today,
            )
        } else {
            voice.deny()
        }
    }

    return {
        val granted = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO)

        if (granted == PackageManager.PERMISSION_GRANTED) {
            voice.start(
                model = model,
                today = today,
            )
        } else {
            permission.launch(Manifest.permission.RECORD_AUDIO)
        }
    }
}
