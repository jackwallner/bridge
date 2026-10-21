package com.jackwallner.bridge.data

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.jackwallner.bridge.BuildConfig
import com.revenuecat.purchases.CacheFetchPolicy
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PeriodType
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.PurchasesErrorCode
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesTransactionException
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.paywalls.events.CustomPaywallImpressionParams
import java.math.BigDecimal
import java.security.MessageDigest
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Currency
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.delay

/** The membership brand, also the RevenueCat entitlement lookup key (iOS `RevenueCatConfig.entitlement`). */
object Membership {
    const val NAME = "Bridge+"
}

enum class PaywallPlan {
    YEARLY,
    LIFETIME,
    MONTHLY;

    /** The free week is named only when Play offers it to this account (`offersFreeTrial`). */
    fun ctaTitle(freeTrial: Boolean): String = when {
        this == LIFETIME -> "Unlock ${Membership.NAME} Forever"
        freeTrial -> "Start 7-Day Free Trial"
        else -> "Subscribe"
    }
}

/** A store price: the localized label plus the amount for arithmetic. */
data class PaywallPrice(val amount: BigDecimal, val localized: String, val currencyCode: String)

enum class PurchaseOutcome { PURCHASED, PENDING, CANCELLED }

class PurchaseException(message: String) : Exception(message)

/** Google Play reviewers reach Bridge+ with a code; only its SHA-256 ships in the build. */
class ReviewAccess(private val defaults: KeyValueStore, private val expectedDigest: String) {
    val isGranted: Boolean get() = expectedDigest.length == 64 && defaults.getString(KEY) == expectedDigest

    fun activate(code: String): Boolean {
        if (!expectedDigest.matches(Regex("[a-f0-9]{64}"))) return false
        val digest = MessageDigest.getInstance("SHA-256").digest(code.trim().toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
        if (!MessageDigest.isEqual(digest.toByteArray(), expectedDigest.toByteArray())) return false
        defaults.putString(KEY, expectedDigest)
        return true
    }

    private companion object {
        const val KEY = "subscription.playReviewAccess"
    }
}

/**
 * RevenueCat behind the Bridge+ entitlements. Debug builds use the Test
 * Store key and release builds the Play key; neither ever runs on the other.
 * The app reads the `android` offering, so iOS keeps its own `default`.
 */
class SubscriptionService(
    private val context: Context,
    private val defaults: KeyValueStore,
    private val diagnostics: ConversionDiagnostics,
    reviewCodeDigest: String = BuildConfig.PLAY_REVIEW_CODE_SHA256,
) {
    private val reviewAccess = ReviewAccess(defaults, reviewCodeDigest)

    var isPro by mutableStateOf((BuildConfig.DEBUG && defaults.getBoolean(LOCAL_OVERRIDE)) || reviewAccess.isGranted)
        private set
    var offering by mutableStateOf<Offering?>(null)
        private set

    /**
     * False until a customer record has actually been read (from RevenueCat's
     * cache or the network). `isPro` starts false on every launch, so acting
     * on `!isPro` before this is true treats every paid member as lapsed
     * while the record is still loading, or for the whole session offline.
     */
    var membershipResolved by mutableStateOf(false)
        private set

    /** The active entitlement is the free week, not a paid or lifetime membership. */
    var isTrialing by mutableStateOf(false)
        private set

    private var isConfigured = false
    private var forcePro = false
    private val impressionsThisSession = mutableSetOf<String>()

    /** Reviewer access from Settings: unlocks Bridge+ on this device only. */
    fun activateReviewAccess(code: String): Boolean {
        if (!reviewAccess.activate(code)) return false
        isPro = true
        return true
    }

    /** Debug-only: open the paid boundary for screenshots and tests. */
    fun forceProForDebug(value: Boolean = true) {
        if (!BuildConfig.DEBUG) return
        forcePro = value
        isPro = value
        membershipResolved = true
    }

    /** Debug-only Settings switch, like the iOS local override. */
    fun setLocalOverride(value: Boolean) {
        if (!BuildConfig.DEBUG) return
        defaults.putBoolean(LOCAL_OVERRIDE, value)
        isPro = value
    }

    suspend fun start() {
        if (!configureIfNeeded()) {
            // No store at all (debug without a key, screenshots): nothing
            // will ever load, so what we have is the answer.
            membershipResolved = true
            return
        }
        refreshCustomerInfo()
        loadOfferings()
    }

    /** `fetchCurrent` right after a purchase: the default policy can hand back a stale cached record. */
    suspend fun refreshCustomerInfo(fetchCurrent: Boolean = false) {
        if (!configureIfNeeded()) return
        val policy = if (fetchCurrent) CacheFetchPolicy.FETCH_CURRENT else CacheFetchPolicy.default()
        runCatching { Purchases.sharedInstance.awaitCustomerInfo(policy) }
            .onSuccess(::apply)
            .onFailure { if (it is CancellationException) throw it }
    }

    suspend fun loadOfferings() {
        if (!configureIfNeeded()) return
        try {
            val offerings = Purchases.sharedInstance.awaitOfferings()
            offering = offerings.all[ANDROID_OFFERING_ID] ?: offerings.current
        } catch (error: CancellationException) {
            throw error
        } catch (_: Throwable) {
            // Leave the previous offering; the paywall shows its retry line.
        }
    }

    /**
     * One more chance for offerings to land before calling the products missing.
     * Checks packages, not just the offering: an offering with zero packages is not ready.
     */
    suspend fun ensureOfferings(): Boolean {
        if (!configureIfNeeded()) return false
        if (hasPurchasablePackages) return true
        loadOfferings()
        return hasPurchasablePackages
    }

    private val hasPurchasablePackages: Boolean get() = offering?.availablePackages?.isNotEmpty() == true

    fun packageFor(plan: PaywallPlan): Package? = when (plan) {
        PaywallPlan.YEARLY -> offering?.annual
        PaywallPlan.MONTHLY -> offering?.monthly
        PaywallPlan.LIFETIME -> offering?.lifetime
    }

    /**
     * Whether the purchase surfaces may promise the free week for `plan`.
     * Play only returns the offers this account is eligible for, so a free
     * phase on the default option is the eligibility answer; no offering yet
     * means not known, and that gets plain pricing too.
     */
    fun offersFreeTrial(plan: PaywallPlan): Boolean =
        plan != PaywallPlan.LIFETIME && packageFor(plan)?.product?.defaultOption?.freePhase != null

    fun paywallPrice(plan: PaywallPlan): PaywallPrice? {
        val price = packageFor(plan)?.product?.price ?: return null
        return PaywallPrice(BigDecimal.valueOf(price.amountMicros, 6), price.formatted, price.currencyCode)
    }

    /** Feeds RevenueCat's paywall encounters; a custom paywall emits none of its own. */
    fun trackPaywallImpression(id: String, oncePerSession: Boolean = false) {
        if (!configureIfNeeded()) return
        if (oncePerSession && !impressionsThisSession.add(id)) return
        diagnostics.recordPitchView(id)
        syncConversionAttributes()
        runCatching { Purchases.sharedInstance.trackCustomPaywallImpression(CustomPaywallImpressionParams(id)) }
    }

    private fun syncConversionAttributes() {
        if (!isConfigured) return
        val attributes = diagnostics.subscriberAttributes.toMutableMap()
        if (attributes.isEmpty()) return
        offering?.identifier?.let { attributes["offering_id"] = it }
        runCatching { Purchases.sharedInstance.setAttributes(attributes) }
    }

    /** A cancel is an outcome, not an error. Throws only with a player-facing message. */
    suspend fun purchase(activity: Activity, pkg: Package?): PurchaseOutcome {
        if (!configureIfNeeded() || pkg == null) throw PurchaseException(UNAVAILABLE)
        return try {
            val result = Purchases.sharedInstance.awaitPurchase(PurchaseParams.Builder(activity, pkg).build())
            apply(result.customerInfo)
            // What Play actually sold, not what the product offers. An entitlement
            // that has not landed yet is lag for `confirmEntitlement`, not a pending
            // payment: a real pending payment arrives as PaymentPendingError below.
            val startedTrial = result.customerInfo.entitlements.active.values.any { it.periodType == PeriodType.TRIAL }
            diagnostics.recordConversion(pkg.product.id, startedTrial, pkg.presentedOfferingContext.offeringIdentifier)
            syncConversionAttributes()
            PurchaseOutcome.PURCHASED
        } catch (error: PurchasesTransactionException) {
            when {
                error.userCancelled -> PurchaseOutcome.CANCELLED
                error.code == PurchasesErrorCode.PaymentPendingError -> PurchaseOutcome.PENDING
                else -> throw PurchaseException("Couldn't complete the purchase. Please try again.")
            }
        }
    }

    /** Play says the money moved; the entitlement can take a beat to catch up. */
    suspend fun confirmEntitlement(attempts: Int = 3): Boolean {
        if (!isConfigured) return isPro
        repeat(attempts) { attempt ->
            refreshCustomerInfo(fetchCurrent = true)
            if (isPro) return true
            if (attempt < attempts - 1) delay(1_200)
        }
        return isPro
    }

    suspend fun restore() {
        if (!configureIfNeeded()) throw PurchaseException(UNAVAILABLE)
        try {
            apply(Purchases.sharedInstance.awaitRestore())
        } catch (error: CancellationException) {
            throw error
        } catch (_: Throwable) {
            throw PurchaseException("Couldn't restore purchases. Try again.")
        }
    }

    /** The active subscription's product id, for the Play manage-subscription link. */
    var activeProductId by mutableStateOf<String?>(null)
        private set

    /**
     * The project has one entitlement, `Bridge+`, which is what iOS checks. Any
     * active entitlement still counts, so a future rename on the dashboard can
     * never lock out someone who just paid.
     */
    private fun apply(info: CustomerInfo) {
        membershipResolved = true
        if (forcePro) return
        val active = info.entitlements.active.values
        val entitlement = active.firstOrNull { it.identifier == Membership.NAME } ?: active.firstOrNull()
        activeProductId = entitlement?.productIdentifier?.substringBefore(":")
        val override = BuildConfig.DEBUG && defaults.getBoolean(LOCAL_OVERRIDE)
        isPro = active.isNotEmpty() || override || reviewAccess.isGranted
        isTrialing = active.isNotEmpty() && active.all { it.periodType == PeriodType.TRIAL }
    }

    private fun configureIfNeeded(): Boolean {
        if (isConfigured) return true
        if (forcePro) return false
        val key = BuildConfig.REVENUECAT_API_KEY
        if (key.isBlank()) return false
        // Never the production Play key in a debug build, and never a test key in release.
        if (BuildConfig.DEBUG && key.startsWith("goog_")) return false
        if (!BuildConfig.DEBUG && !key.startsWith("goog_")) return false
        Purchases.logLevel = if (BuildConfig.DEBUG) LogLevel.DEBUG else LogLevel.ERROR
        val builder = PurchasesConfiguration.Builder(context, key)
        // Test Store runs share one tester instead of a fresh anonymous customer
        // per install, so test installs don't inflate the live project's
        // customer charts. Never with the Play key: real buyers would share one
        // identity.
        if (key.startsWith("test_")) builder.appUserID(QA_APP_USER_ID)
        Purchases.configure(builder.build())
        Purchases.sharedInstance.updatedCustomerInfoListener = UpdatedCustomerInfoListener { apply(it) }
        isConfigured = true
        return true
    }

    companion object {
        private const val QA_APP_USER_ID = "qa-android"
        private const val LOCAL_OVERRIDE = "subscription.localProOverride"
        private const val ANDROID_OFFERING_ID = "android"
        private const val UNAVAILABLE = "Google Play isn't reachable right now. Check your connection and try again."
    }
}

/**
 * Price and terms strings, live from the store. An unresolved product shows a
 * placeholder, never an invented amount.
 */
object PaywallPricing {
    const val PLACEHOLDER = "Loading price…"

    fun price(service: SubscriptionService, plan: PaywallPlan): String? {
        val base = service.paywallPrice(plan)?.localized ?: return null
        return when (plan) {
            PaywallPlan.YEARLY -> "$base/year"
            PaywallPlan.MONTHLY -> "$base/month"
            PaywallPlan.LIFETIME -> base
        }
    }

    fun priceText(service: SubscriptionService, plan: PaywallPlan): String = price(service, plan) ?: PLACEHOLDER

    fun perMonthEquivalent(service: SubscriptionService): String? {
        val yearly = service.paywallPrice(PaywallPlan.YEARLY) ?: return null
        val monthly = yearly.amount.divide(BigDecimal(12), 2, RoundingMode.HALF_UP)
        val format = NumberFormat.getCurrencyInstance().apply {
            runCatching { currency = Currency.getInstance(yearly.currencyCode) }
        }
        return "${format.format(monthly)}/mo"
    }

    fun monthlyAnchor(service: SubscriptionService): String? =
        service.paywallPrice(PaywallPlan.MONTHLY)?.let { "${it.localized}/mo" }

    fun savingsPercent(service: SubscriptionService): Int? {
        val yearly = service.paywallPrice(PaywallPlan.YEARLY) ?: return null
        val monthly = service.paywallPrice(PaywallPlan.MONTHLY) ?: return null
        val twelve = monthly.amount.multiply(BigDecimal(12))
        if (twelve.signum() <= 0 || yearly.amount >= twelve) return null
        val percent = twelve.subtract(yearly.amount).divide(twelve, 6, RoundingMode.HALF_UP)
            .multiply(BigDecimal(100)).setScale(0, RoundingMode.HALF_UP).toInt()
        return percent.takeIf { it > 0 }
    }

    fun savingsBadge(service: SubscriptionService): String =
        savingsPercent(service)?.let { "SAVE $it%" } ?: "BEST VALUE"

    fun terms(service: SubscriptionService, plan: PaywallPlan): String =
        terms(price(service, plan), plan, service.offersFreeTrial(plan))

    /** The free week appears only when Play offers it to this account. */
    fun terms(amount: String?, plan: PaywallPlan, freeTrial: Boolean): String = when {
        plan == PaywallPlan.LIFETIME && amount == null -> "One-time purchase. Not a subscription, nothing renews."
        plan == PaywallPlan.LIFETIME -> "$amount one-time. Not a subscription, nothing renews."
        amount == null && freeTrial -> "Includes 7 days free. Auto-renews until canceled."
        amount == null -> "Auto-renews until canceled."
        freeTrial -> "7 days free, then $amount. Auto-renews until canceled in Google Play."
        else -> "$amount. Auto-renews until canceled in Google Play."
    }
}
