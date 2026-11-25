package com.yossibank.kakeibot.featuremodels.shared.model

import org.junit.Test
import kotlin.test.assertEquals

class DeviceNameTest {
    @Test
    fun namesWideScreensAsTablet() {
        assertEquals("タブレット", DeviceName.name(ofWidth = 600))
        assertEquals("タブレット", DeviceName.name(ofWidth = 840))
    }

    @Test
    fun namesOtherScreensAsPhone() {
        assertEquals("スマホ", DeviceName.name(ofWidth = 411))
        assertEquals("スマホ", DeviceName.name(ofWidth = 599))
        assertEquals("スマホ", DeviceName.current)
    }
}
