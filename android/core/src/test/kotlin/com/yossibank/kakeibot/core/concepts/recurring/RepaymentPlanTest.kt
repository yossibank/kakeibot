package com.yossibank.kakeibot.core.concepts.recurring

import com.yossibank.kakeibot.core.support.CoreFixture
import kotlinx.serialization.Serializable
import org.junit.Test
import org.junit.experimental.runners.Enclosed
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

@RunWith(Enclosed::class)
class RepaymentPlanTest {
    @RunWith(Parameterized::class)
    class PlansCountAndFinalAmount(
        private val fixture: PlanCase,
    ) {
        @Serializable
        data class PlanCase(
            val summary: String,
            val owed: Int,
            val amount: Int,
            val count: Int? = null,
            val expectedCount: Int,
            val finalAmount: Int? = null,
            val gap: Long,
        ) {
            override fun toString(): String = summary
        }

        @Test
        fun plansCountAndFinalAmount() {
            val plan = assertNotNull(
                RepaymentPlan.of(
                    owed = fixture.owed,
                    amount = fixture.amount,
                    count = fixture.count,
                ),
            )

            assertEquals(fixture.expectedCount, plan.count)
            assertEquals(fixture.finalAmount, plan.finalAmount)
            assertEquals(fixture.gap, plan.gap)
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "{0}")
            fun cases(): List<PlanCase> = CoreFixture.cases("recurring/repayment-plan.json", PlanCase.serializer())
        }
    }

    @RunWith(Parameterized::class)
    class HasNoPlan(
        private val owed: Int,
        private val amount: Int,
    ) {
        @Test
        fun hasNoPlanWithoutOwedOrAmount() {
            assertNull(RepaymentPlan.of(owed = owed, amount = amount))
        }

        companion object {
            @JvmStatic
            @Parameterized.Parameters(name = "owed={0} amount={1}")
            fun cases(): List<Array<Int>> = listOf(
                arrayOf(0, 16235),
                arrayOf(-1, 16235),
                arrayOf(3_896_752, 0),
            )
        }
    }
}
