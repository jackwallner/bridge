package com.jackwallner.bridge.content

import com.jackwallner.bridge.model.Room

object DrillLibrary {
    val rooms: List<Room> get() = BridgeContent.library.rooms

    fun room(id: String): Room? = rooms.firstOrNull { it.id == id }

    /** The room a drill belongs to, so drill screens can report per-room accuracy. */
    fun roomID(forDrillID: String): String =
        rooms.firstOrNull { room -> room.drills.any { it.id == forDrillID } }?.id ?: ""
}

object HowToPlayContent {
    val pages: List<HowToPlayPage> get() = BridgeContent.library.primer

    /** The room recommended at the end of the primer for an onboarding skill level. */
    fun recommendedRoom(skillLevel: String): Room {
        val roomID = when (skillLevel) {
            "basics" -> "auction-room"
            "played" -> "declarer-room"
            else -> "card-room"
        }
        return DrillLibrary.room(roomID) ?: DrillLibrary.rooms.first()
    }
}
