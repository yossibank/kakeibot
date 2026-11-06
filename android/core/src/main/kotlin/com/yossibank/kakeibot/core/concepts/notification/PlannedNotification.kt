package com.yossibank.kakeibot.core.concepts.notification

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.EntryTemplate
import com.yossibank.kakeibot.core.shared.Identifier

data class PlannedNotification(
    val key: String,
    val date: LocalDate,
    val time: ReminderTime,
    val title: String,
    val body: String,
    val route: Route,
) {
    val identifier: String
        get() = listOf(
            key,
            date.toString(),
            time.toString(),
            title,
            body,
        ).joinToString("|")

    sealed interface Route {
        val link: String

        data object Home : Route {
            override val link: String
                get() = "home"
        }

        data class Entry(
            val date: LocalDate,
        ) : Route {
            override val link: String
                get() = "entry/$date"
        }

        data class Recurring(
            val id: Identifier<com.yossibank.kakeibot.core.concepts.recurring.Recurring>,
        ) : Route {
            override val link: String
                get() = "recurring/$id"
        }

        data class Template(
            val id: Identifier<EntryTemplate>,
        ) : Route {
            override val link: String
                get() = "template/$id"
        }

        companion object {
            fun of(link: String): Route? {
                if (link == "home") {
                    return Home
                }

                val parts = parts(link)

                if (parts.size != 2) {
                    return null
                }

                return when (parts[0]) {
                    "entry" -> LocalDate.parse(parts[1])?.let { Entry(it) }
                    "recurring" -> Identifier.parse<com.yossibank.kakeibot.core.concepts.recurring.Recurring>(parts[1])
                        ?.let { Recurring(it) }
                    "template" -> Identifier.parse<EntryTemplate>(parts[1])?.let { Template(it) }
                    else -> null
                }
            }

            private fun parts(link: String): List<String> {
                val trimmed = link.trimStart('/')

                if (trimmed.isEmpty()) {
                    return emptyList()
                }

                val index = trimmed.indexOf('/')

                if (index < 0) {
                    return listOf(trimmed)
                }

                val head = trimmed.substring(0, index)
                val rest = trimmed.substring(index + 1)

                return if (rest.isEmpty()) listOf(head) else listOf(head, rest)
            }
        }
    }
}
