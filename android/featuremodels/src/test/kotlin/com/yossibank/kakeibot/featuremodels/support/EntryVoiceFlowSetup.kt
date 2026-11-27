package com.yossibank.kakeibot.featuremodels.support

import com.yossibank.kakeibot.featuremodels.screens.entry.voice.EntryVoiceFlow

const val VOICE_SILENCE_MILLIS = 100L
const val VOICE_NOTICE_MILLIS = 100L

internal fun voiceFlow(
    source: FakeVoiceSource,
    clock: FakeVoiceClock = FakeVoiceClock(),
): EntryVoiceFlow = EntryVoiceFlow(
    isAvailable = true,
    clock = clock.screenClock,
    makeSource = { source },
    sleep = clock::sleep,
    silenceMillis = VOICE_SILENCE_MILLIS,
    noticeMillis = VOICE_NOTICE_MILLIS,
)
