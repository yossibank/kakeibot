package com.yossibank.kakeibot.appfeature.app

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.theme.ThemeLook
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenClock
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.notifications.NotificationScheduler
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.notificationInputUpdates
import com.yossibank.kakeibot.store.queries.methods.style
import com.yossibank.kakeibot.store.queries.methods.styleUpdates
import com.yossibank.kakeibot.store.queries.methods.themeLook
import com.yossibank.kakeibot.store.queries.methods.themeLookUpdates
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.ZoneId

class AppModel(
    currentDay: () -> LocalDate = ::deviceDay,
    scheduler: NotificationScheduler? = null,
    clock: ScreenClock = ScreenClock.system,
) : ViewModel() {
    val state = State()
    val input = Input(today = currentDay())

    private val runtime = Runtime()

    private val dependencies = Dependencies(
        currentDay = currentDay,
        scheduler = scheduler,
        clock = clock,
    )

    sealed interface Launch {
        data object Opening : Launch

        data class Ready(
            val database: AppDatabase,
            val parts: ScreenParts,
        ) : Launch

        data object Failed : Launch
    }

    class State {
        var launch: Launch by mutableStateOf(Launch.Opening)
            private set

        fun move(to: Launch) {
            launch = to
        }
    }

    class Input(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
            private set

        var look: ThemeLook by mutableStateOf(ThemeLook.followsDevice)
            private set

        var style: ThemeStyle by mutableStateOf(ThemeStyle.standard)
            private set

        fun receive(today: LocalDate) {
            this.today = today
        }

        fun receive(look: ThemeLook) {
            this.look = look
        }

        fun receive(style: ThemeStyle) {
            this.style = style
        }
    }

    private class Runtime {
        var opening: Job? = null
        var notifications: Job? = null
    }

    private class Dependencies(
        val currentDay: () -> LocalDate,
        val scheduler: NotificationScheduler?,
        val clock: ScreenClock,
    )

    override fun onCleared() {
        (state.launch as? Launch.Ready)?.database?.close()
    }

    fun open(openDatabase: suspend () -> AppDatabase) {
        if (runtime.opening != null || state.launch != Launch.Opening) {
            return
        }

        runtime.opening = viewModelScope.launch {
            var database: AppDatabase? = null

            try {
                val opened = openDatabase()

                database = opened
                generateRecurring(opened)
                input.receive(look = opened.themeLook())
                input.receive(style = opened.style())

                state.move(
                    to = Launch.Ready(
                        database = opened,
                        parts = ScreenParts(
                            database = opened,
                            clock = dependencies.clock,
                        ),
                    ),
                )

                observeTheme(opened)
                observeNotifications(opened)
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                state.move(to = Launch.Failed)
            } finally {
                if (state.launch !is Launch.Ready) {
                    database?.close()
                }

                runtime.opening = null
            }
        }
    }

    fun retryOpen(openDatabase: suspend () -> AppDatabase) {
        if (state.launch != Launch.Failed) {
            return
        }

        state.move(to = Launch.Opening)
        open(openDatabase)
    }

    fun refreshDay() {
        input.receive(today = dependencies.currentDay())

        val database = (state.launch as? Launch.Ready)?.database ?: return

        viewModelScope.launch {
            generateRecurring(database)
        }

        observeNotifications(database)
    }

    private fun observeTheme(database: AppDatabase) {
        viewModelScope.launch {
            database.themeLookUpdates().collect { input.receive(look = it) }
        }

        viewModelScope.launch {
            database.styleUpdates().collect { input.receive(style = it) }
        }
    }

    private fun observeNotifications(database: AppDatabase) {
        val scheduler = dependencies.scheduler ?: return
        val day = input.today

        runtime.notifications?.cancel()

        runtime.notifications = viewModelScope.launch {
            ModelTask.quiet {
                database.notificationInputUpdates(from = day).collect { notificationInput ->
                    withContext(Dispatchers.IO) {
                        scheduler.apply(
                            notificationInput.plan(today = day),
                            now = dependencies.clock.now,
                        )
                    }
                }
            }
        }
    }

    private suspend fun generateRecurring(database: AppDatabase) {
        ModelTask.quiet {
            database.generateRecurringEntries(
                through = input.today,
                at = dependencies.clock.now,
            )
        }
    }

    companion object {
        fun deviceDay(): LocalDate = LocalDate.of(
            instant = ScreenClock.system.now,
            timeZone = ZoneId.systemDefault(),
        )
    }
}
