package com.omisu.streaming

enum class StreamAudioMode {
    GAME,
    MIC,
    MIXED,
    ;

    companion object {
        fun fromWire(value: String?): StreamAudioMode =
            when (value?.lowercase()) {
                "mic", "microphone" -> MIC
                "mixed", "game_and_mic", "game+mic" -> MIXED
                else -> GAME
            }
    }
}
