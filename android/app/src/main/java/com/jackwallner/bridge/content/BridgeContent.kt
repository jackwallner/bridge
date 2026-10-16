package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.BridgeCard
import com.jackwallner.bridge.model.CardChoice
import com.jackwallner.bridge.model.Drill
import com.jackwallner.bridge.model.DrillKind
import com.jackwallner.bridge.model.Flashcard
import com.jackwallner.bridge.model.HandCategory
import com.jackwallner.bridge.model.HandMatchQuestion
import com.jackwallner.bridge.model.PlayScenario
import com.jackwallner.bridge.model.QuizQuestion
import com.jackwallner.bridge.model.Room
import org.json.JSONArray
import org.json.JSONObject

data class HowToPlayPage(
    val id: String,
    val icon: String,
    val title: String,
    val body: String,
    val cards: List<BridgeCard>,
    val tip: String?,
)

data class WhatsNewItem(val id: String, val icon: String, val title: String, val body: String, val isPlus: Boolean)

data class WhatsNewRelease(val version: String, val headline: String, val items: List<WhatsNewItem>)

class ContentLibrary(
    val rooms: List<Room>,
    val primer: List<HowToPlayPage>,
    val whatsNew: List<WhatsNewRelease>,
)

/**
 * Every authored drill, the primer and the release notes, exported from the
 * iOS sources by `scripts/sync-android-content.sh`. Loaded from a classpath
 * resource so JVM unit tests read exactly what the app reads.
 */
object BridgeContent {
    val library: ContentLibrary by lazy { load() }

    private fun load(): ContentLibrary {
        val stream = BridgeContent::class.java.classLoader!!.getResourceAsStream("bridge-content.json")
            ?: error("bridge-content.json is missing; run scripts/sync-android-content.sh")
        return parse(JSONObject(stream.bufferedReader().use { it.readText() }))
    }

    fun parse(json: JSONObject): ContentLibrary = ContentLibrary(
        rooms = json.getJSONArray("rooms").objects().map(::room),
        primer = json.getJSONArray("primer").objects().map { item ->
            HowToPlayPage(
                id = item.getString("id"),
                icon = item.getString("icon"),
                title = item.getString("title"),
                body = item.getString("body"),
                cards = item.getJSONArray("cards").cards(),
                tip = item.optStringOrNull("tip"),
            )
        },
        whatsNew = json.getJSONArray("whatsNew").objects().map { release ->
            WhatsNewRelease(
                version = release.getString("version"),
                headline = release.getString("headline"),
                items = release.getJSONArray("items").objects().map { item ->
                    WhatsNewItem(
                        id = item.getString("id"),
                        icon = item.getString("icon"),
                        title = item.getString("title"),
                        body = item.getString("body"),
                        isPlus = item.getBoolean("isPlus"),
                    )
                },
            )
        },
    )

    private fun room(json: JSONObject) = Room(
        id = json.getString("id"),
        name = json.getString("name"),
        tagline = json.getString("tagline"),
        icon = json.getString("icon"),
        isFree = json.getBoolean("isFree"),
        drills = json.getJSONArray("drills").objects().map(::drill),
    )

    private fun drill(json: JSONObject): Drill {
        val items = json.getJSONArray("items").objects()
        val kind = when (val raw = json.getString("kind")) {
            "flashcards" -> DrillKind.Flashcards(items.map(::flashcard))
            "quiz" -> DrillKind.Quiz(items.map(::quiz))
            "handMatch" -> DrillKind.HandMatch(items.map(::handMatch))
            "play" -> DrillKind.Play(items.map(::play))
            else -> error("Unknown drill kind $raw")
        }
        return Drill(
            id = json.getString("id"),
            title = json.getString("title"),
            subtitle = json.getString("subtitle"),
            kind = kind,
            isPlus = json.getBoolean("isPlus"),
        )
    }

    private fun flashcard(json: JSONObject) = Flashcard(
        id = json.getString("id"),
        frontTitle = json.getString("frontTitle"),
        frontCards = json.getJSONArray("frontCards").cards(),
        frontSubtitle = json.optStringOrNull("frontSubtitle"),
        backTitle = json.getString("backTitle"),
        backBody = json.getString("backBody"),
        choice = json.optJSONObject("choice")?.let {
            CardChoice(it.getJSONArray("options").strings(), it.getInt("answerIndex"))
        },
    )

    private fun quiz(json: JSONObject) = QuizQuestion(
        id = json.getString("id"),
        prompt = json.getString("prompt"),
        cards = json.getJSONArray("cards").cards(),
        choices = json.getJSONArray("choices").strings(),
        answerIndex = json.getInt("answerIndex"),
        explanation = json.getString("explanation"),
    )

    private fun handMatch(json: JSONObject) = HandMatchQuestion(
        id = json.getString("id"),
        cards = json.getJSONArray("cards").cards(),
        choices = json.getJSONArray("choices").strings().map(HandCategory::fromRaw),
        answer = HandCategory.fromRaw(json.getString("answer")),
        explanation = json.getString("explanation"),
    )

    private fun play(json: JSONObject) = PlayScenario(
        id = json.getString("id"),
        situation = json.getString("situation"),
        cards = json.getJSONArray("cards").cards(),
        answerIndex = json.getInt("answerIndex"),
        reasoning = json.getString("reasoning"),
        tip = json.getString("tip"),
    )
}

internal fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
internal fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }
internal fun JSONArray.cards(): List<BridgeCard> = strings().map(BridgeCard::fromCode)
internal fun JSONObject.optStringOrNull(key: String): String? = if (has(key) && !isNull(key)) getString(key) else null
