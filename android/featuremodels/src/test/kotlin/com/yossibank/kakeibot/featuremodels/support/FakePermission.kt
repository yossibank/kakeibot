package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.core.concepts.notification.NotificationAuthorization
import com.yossibank.kakeibot.featuremodels.shared.notification.NotificationPermission

class FakePermission(
    authorization: NotificationAuthorization,
    private val grants: Boolean = true,
) {
    var requested = false
        private set

    var rescheduled = false
        private set

    private var status = authorization

    val permission = NotificationPermission(
        authorization = { status },
        request = ::request,
        reschedule = { rescheduled = true },
    )

    private fun request(): Boolean {
        requested = true

        if (status == NotificationAuthorization.notDetermined) {
            status = if (grants) {
                NotificationAuthorization.allowed
            } else {
                NotificationAuthorization.denied
            }
        }

        return status == NotificationAuthorization.allowed
    }
}
