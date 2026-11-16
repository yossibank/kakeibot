package com.yossibank.kakeibot.appfeature.app

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.theme.ThemeLook
import com.yossibank.kakeibot.core.concepts.theme.ThemeStyle
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.style
import com.yossibank.kakeibot.store.queries.methods.styleUpdates
import com.yossibank.kakeibot.store.queries.methods.themeLook
import com.yossibank.kakeibot.store.queries.methods.themeLookUpdates
import com.yossibank.kakeibot.store.writes.methods.generateRecurringEntries
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId

class AppModel(
    private val currentDay: () -> LocalDate = ::deviceDay,
) : ViewModel() {
    var launch: Launch by mutableStateOf(Launch.Opening)
        private set

    var today: LocalDate by mutableStateOf(currentDay())
        private set

    var look: ThemeLook by mutableStateOf(ThemeLook.followsDevice)
        private set

    var style: ThemeStyle by mutableStateOf(ThemeStyle.standard)
        private set

    private var opening: Job? = null

    sealed interface Launch {
        data object Opening : Launch

        data class Ready(
            val database: AppDatabase,
        ) : Launch

        data object Failed : Launch
    }

    fun open(openDatabase: suspend () -> AppDatabase) {
        if (opening != null || launch != Launch.Opening) {
            return
        }

        opening = viewModelScope.launch {
            var database: AppDatabase? = null

            try {
                val opened = openDatabase()
                database = opened

                generateRecurring(opened)

                look = opened.themeLook()
                style = opened.style()
                launch = Launch.Ready(opened)

                observeTheme(opened)
            } catch (error: CancellationException) {
                throw error
            } catch (_: Exception) {
                launch = Launch.Failed
            } finally {
                if (launch !is Launch.Ready) {
                    database?.close()
                }

                opening = null
            }
        }
    }

    fun retryOpen(openDatabase: suspend () -> AppDatabase) {
        if (launch != Launch.Failed) {
            return
        }

        launch = Launch.Opening

        open(openDatabase)
    }

    fun refreshDay() {
        today = currentDay()

        val database = (launch as? Launch.Ready)?.database ?: return

        viewModelScope.launch {
            generateRecurring(database)
        }
    }

    override fun onCleared() {
        (launch as? Launch.Ready)?.database?.close()
    }

    private fun observeTheme(database: AppDatabase) {
        viewModelScope.launch {
            database.themeLookUpdates().collect { look = it }
        }

        viewModelScope.launch {
            database.styleUpdates().collect { style = it }
        }
    }

    private suspend fun generateRecurring(database: AppDatabase) {
        try {
            database.generateRecurringEntries(
                through = today,
                at = Instant.now(),
            )
        } catch (error: CancellationException) {
            throw error
        } catch (_: Exception) {
            return
        }
    }

    companion object {
        fun deviceDay(): LocalDate = LocalDate.of(
            instant = Instant.now(),
            timeZone = ZoneId.systemDefault(),
        )
    }
}
