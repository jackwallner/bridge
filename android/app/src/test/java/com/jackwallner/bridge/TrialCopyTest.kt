package com.jackwallner.bridge

import com.jackwallner.bridge.data.PaywallPlan
import com.jackwallner.bridge.data.PaywallPricing
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/** The free week is only promised when Play offers it to this account (iOS `PaywallPricing.terms`, plus Play trial eligibility). */
class TrialCopyTest {
    @Test
    fun termsNameTheFreeWeekOnlyWhenOffered() {
        assertEquals(
            "7 days free, then $6.99/month. Auto-renews until canceled in Google Play.",
            PaywallPricing.terms("$6.99/month", PaywallPlan.MONTHLY, freeTrial = true),
        )
        assertEquals(
            "$6.99/month. Auto-renews until canceled in Google Play.",
            PaywallPricing.terms("$6.99/month", PaywallPlan.MONTHLY, freeTrial = false),
        )
        assertFalse(PaywallPricing.terms(null, PaywallPlan.YEARLY, freeTrial = false).contains("free", ignoreCase = true))
    }

    @Test
    fun ctaNamesTheTrialOnlyWhenOffered() {
        assertEquals("Start 7-Day Free Trial", PaywallPlan.MONTHLY.ctaTitle(true))
        assertEquals("Subscribe", PaywallPlan.YEARLY.ctaTitle(false))
        assertFalse(PaywallPlan.LIFETIME.ctaTitle(true).contains("Trial"))
    }
}
