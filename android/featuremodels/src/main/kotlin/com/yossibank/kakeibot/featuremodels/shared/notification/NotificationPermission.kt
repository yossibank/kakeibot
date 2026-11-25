package com.yossibank.kakeibot.featuremodels.shared.notification

import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization

class NotificationPermission(
    val authorization: () -> NotificationAuthorization,
    val request: suspend () -> Boolean,
) {
    suspend fun requestIfUndecided() {
        if (authorization() != NotificationAuthorization.notDetermined) {
            return
        }

        request()
    }

    companion object {
        val allowed = NotificationPermission(
            authorization = { NotificationAuthorization.allowed },
            request = { true },
        )
    }
}
