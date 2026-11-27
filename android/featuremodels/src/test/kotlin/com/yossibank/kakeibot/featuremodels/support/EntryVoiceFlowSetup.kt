package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow

const val VOICE_SILENCE_MILLIS = 100L

internal fun voiceFlow(
    source: FakeVoiceSource,
    clock: FakeVoiceClock = FakeVoiceClock(),
    wait: ManualWait = ManualWait(),
): EntryVoiceFlow = EntryVoiceFlow(
    isAvailable = true,
    clock = clock.screenClock,
    makeSource = { source },
    wait = wait.wait,
    sleep = clock::sleep,
    silenceMillis = VOICE_SILENCE_MILLIS,
)
