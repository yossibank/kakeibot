package com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts

import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.support.ModelFixture
import org.junit.Test
import kotlin.test.assertEquals

class ReviewTextTest {
    @Test
    fun namesShares() {
        ModelFixture.cases("review/review-share-text.json").forEach { case ->
            val texts = ReviewText.shares(case.numbers("amounts"))

            assertEquals(case.texts("texts"), texts, case.summary)
        }
    }

    @Test
    fun signsBalance() {
        ModelFixture.cases("review/review-balance-text.json").forEach { case ->
            val amount = case.number("amount")

            val text = AmountText.text(
                amount = amount.clamped,
                sign = AmountText.Sign.Plus,
            )

            assertEquals(case.text("text"), text, case.summary)
            assertEquals(case.text("title"), ReviewText.balanceTitle(amount), case.summary)
        }
    }
}
