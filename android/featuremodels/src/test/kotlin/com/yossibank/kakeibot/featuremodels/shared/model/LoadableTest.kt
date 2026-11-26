package com.yossibank.kakeibot.featuremodels.shared.model

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LoadableTest {
    @Test
    fun holdsValueOnlyWhenLoaded() {
        val loading: Loadable<Int> = Loadable.Loading
        val loaded: Loadable<Int> = Loadable.Loaded(1)
        val failed: Loadable<Int> = Loadable.Failed

        assertNull(loading.value)
        assertEquals(1, loaded.value)
        assertNull(failed.value)
        assertTrue(loaded.isLoaded)
        assertTrue(failed.isFailed)
    }

    @Test
    fun settlesWhenLoadedOrFailed() {
        assertFalse(Loadable.Loading.isSettled)
        assertTrue(Loadable.Loaded(1).isSettled)
        assertTrue(Loadable.Failed.isSettled)
    }

    @Test
    fun retriesOnlyFromFailure() {
        val loaded: Loadable<Int> = Loadable.Loaded(1)

        assertEquals(Loadable.Loading, Loadable.Failed.retrying)
        assertEquals(Loadable.Loading, Loadable.Loading.retrying)
        assertEquals(loaded, loaded.retrying)
    }
}
