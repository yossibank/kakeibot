package com.yossibank.kakeibot.core.concepts.app

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals

@RunWith(Parameterized::class)
class AppVersionTest(
    private val fixture: VersionCase,
) {
    @Test
    fun findsNewerVersion() {
        val isNewer = AppVersion.isNewer(fixture.latest, fixture.seen)

        assertEquals(fixture.isNewer, isNewer)
    }

    @Serializable
    data class VersionCase(
        val summary: String,
        val latest: String,
        val seen: String?,
        val isNewer: Boolean,
    ) {
        override fun toString(): String = summary
    }

    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun cases(): List<VersionCase> = CoreFixture.cases("app/app-version.json", VersionCase.serializer())
    }
}
