package com.yossibank.kakeibot.featuremodels.shared.notification

import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization

class NotificationPermission(
    val authorization: () -> NotificationAuthorization,
    val request: suspend () -> Boolean,
    val reschedule: suspend () -> Unit = {},
) {
    suspend fun requestIfUndecided() {
        if (authorization() != NotificationAuthorization.notDetermined) {
            return
        }

        if (request()) {
            reschedule()
        }
    }

    companion object {
        val allowed = NotificationPermission(
            authorization = { NotificationAuthorization.allowed },
            request = { true },
        )
    }
}
