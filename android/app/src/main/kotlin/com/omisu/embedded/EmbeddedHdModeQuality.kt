package com.omisu.embedded

enum class EmbeddedHdModeQuality {
    LOW,
    MEDIUM,
    HIGH,
    ;

    companion object {
        fun parse(value: Any?): EmbeddedHdModeQuality {
            return when (value) {
                is Number -> {
                    val index = value.toInt()
                    entries.getOrNull(index) ?: MEDIUM
                }
                is String ->
                    when (value.lowercase()) {
                        "low" -> LOW
                        "medium", "med" -> MEDIUM
                        "high" -> HIGH
                        else -> MEDIUM
                    }
                else -> MEDIUM
            }
        }
    }
}
