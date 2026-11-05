package com.yossibank.kakeibot.core.concepts.notification

import java.net.URI

private const val scheme = "kakeibot"

val PlannedNotification.Route.url: URI?
    get() = runCatching { URI("$scheme://$link") }.getOrNull()

fun PlannedNotification.Route.Companion.of(url: URI): PlannedNotification.Route? {
    if (url.scheme != scheme) {
        return null
    }

    val host = url.host ?: ""
    val link = host + (url.rawPath ?: "")

    return PlannedNotification.Route.of(link = link)
}
