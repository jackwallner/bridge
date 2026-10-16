package com.jackwallner.bridge.model

/** Beginner Standard American opening choices used by hand-reading drills. */
enum class HandCategory(val raw: String, val displayName: String) {
    PASS("pass", "Pass"),
    ONE_CLUB("oneClub", "1♣"),
    ONE_DIAMOND("oneDiamond", "1♦"),
    ONE_HEART("oneHeart", "1♥"),
    ONE_SPADE("oneSpade", "1♠"),
    ONE_NOTRUMP("oneNotrump", "1NT");

    companion object {
        fun fromRaw(raw: String): HandCategory = entries.first { it.raw == raw }
    }
}

/** A two-option self-test on a card's front. */
data class CardChoice(val options: List<String>, val answerIndex: Int)

data class Flashcard(
    val id: String,
    val frontTitle: String,
    val frontCards: List<BridgeCard> = emptyList(),
    val frontSubtitle: String? = null,
    val backTitle: String,
    val backBody: String,
    val choice: CardChoice? = null,
)

data class QuizQuestion(
    val id: String,
    val prompt: String,
    val cards: List<BridgeCard> = emptyList(),
    val choices: List<String>,
    val answerIndex: Int,
    val explanation: String,
)

data class HandMatchQuestion(
    val id: String,
    val cards: List<BridgeCard>,
    val choices: List<HandCategory>,
    val answer: HandCategory,
    val explanation: String,
)

data class PlayScenario(
    val id: String,
    val situation: String,
    val cards: List<BridgeCard>,
    val answerIndex: Int,
    val reasoning: String,
    val tip: String,
)

sealed interface DrillKind {
    data class Flashcards(val cards: List<Flashcard>) : DrillKind
    data class Quiz(val questions: List<QuizQuestion>) : DrillKind
    data class HandMatch(val questions: List<HandMatchQuestion>) : DrillKind
    data class Play(val scenarios: List<PlayScenario>) : DrillKind

    val itemCount: Int
        get() = when (this) {
            is Flashcards -> cards.size
            is Quiz -> questions.size
            is HandMatch -> questions.size
            is Play -> scenarios.size
        }

    val unitName: String
        get() = when (this) {
            is Flashcards -> "cards"
            is Quiz -> "questions"
            is HandMatch -> "hands"
            is Play -> "deals"
        }
}

data class Drill(
    val id: String,
    val title: String,
    val subtitle: String,
    val kind: DrillKind,
    /** Extra practice sets inside an otherwise free room, locked behind Bridge+. */
    val isPlus: Boolean = false,
)

data class Room(
    val id: String,
    val name: String,
    val tagline: String,
    val icon: String,
    /** A free room opens for everyone; its `isPlus` drills are the locked extras. */
    val isFree: Boolean,
    val drills: List<Drill>,
) {
    /** Drills a member unlocks here: the whole room if it is paid, otherwise the extra sets. */
    val plusDrillCount: Int get() = if (isFree) drills.count { it.isPlus } else drills.size

    fun isLocked(drill: Drill, isMember: Boolean): Boolean = !isMember && (!isFree || drill.isPlus)
}
