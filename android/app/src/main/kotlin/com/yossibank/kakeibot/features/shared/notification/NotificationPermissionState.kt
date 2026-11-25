package com.yossibank.kakeibot.features.shared.notification

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.edit
import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization
import com.yossibank.kakeibot.featuremodels.shared.notification.NotificationPermission
import kotlinx.coroutines.CompletableDeferred

class NotificationPermissionState(
    private val context: Context,
) {
    val permission = NotificationPermission(
        authorization = ::authorization,
        request = ::request,
    )

    internal var launch: () -> Unit = {}

    private var answer: CompletableDeferred<Boolean>? = null

    private val isEnabled: Boolean
        get() = NotificationManagerCompat.from(context).areNotificationsEnabled()

    private val canAsk: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

    private val store
        get() = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)

    fun openSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)

        context.startActivity(intent)
    }

    internal fun receive(isGranted: Boolean) {
        answer?.complete(isGranted)
    }

    private fun authorization(): NotificationAuthorization = when {
        isEnabled -> NotificationAuthorization.allowed
        canAsk && !store.getBoolean(KEY_ASKED, false) -> NotificationAuthorization.notDetermined
        else -> NotificationAuthorization.denied
    }

    private suspend fun request(): Boolean {
        if (!canAsk) {
            return isEnabled
        }

        val waiting = CompletableDeferred<Boolean>()

        answer = waiting
        store.edit { putBoolean(KEY_ASKED, true) }
        launch()

        return waiting.await()
    }

    private companion object {
        const val STORE_NAME = "notification-permission"
        const val KEY_ASKED = "asked"
    }
}

@Composable
fun rememberNotificationPermission(): NotificationPermissionState {
    val context = LocalContext.current
    val state = remember(context) { NotificationPermissionState(context = context) }

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = state::receive,
    )

    state.launch = {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    DisposableEffect(state) {
        onDispose { state.receive(isGranted = false) }
    }

    return state
}
