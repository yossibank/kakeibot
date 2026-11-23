package com.yossibank.kakeibot.features.shared.notification

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect

class NotificationPermissionState(
    private val context: Context,
) {
    var isAllowed: Boolean by mutableStateOf(true)
        internal set

    internal var launch: () -> Unit = {}

    fun refresh() {
        isAllowed = NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    fun requestIfNeeded() {
        val isEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !isEnabled) {
            launch()
        }
    }

    fun openSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)

        context.startActivity(intent)
    }
}

@Composable
fun rememberNotificationPermission(): NotificationPermissionState {
    val context = LocalContext.current
    val state = remember(context) { NotificationPermissionState(context = context) }

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { isGranted ->
        state.isAllowed = isGranted
    }

    state.launch = {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    LaunchedEffect(state) {
        state.refresh()
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        state.refresh()
    }

    return state
}
