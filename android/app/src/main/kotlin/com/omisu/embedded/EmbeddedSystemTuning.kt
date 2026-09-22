package com.omisu.embedded

/**
 * Per-system libretro tuning ported from Lemuroid [GameSystem] / [SystemCoreConfig].
 *
 * Device-tier defaults from Flutter may be overridden here when a core needs fixed
 * frame timing (N64, PSX) or stability-oriented core variables.
 */
data class EmbeddedSystemTuning(
    /** When null, keep the device-tier value from [LaunchTuning]. */
    val skipDuplicateFrames: Boolean? = null,
    val coreVariables: Map<String, String> = emptyMap(),
)

object EmbeddedSystemTuningRegistry {
    private val folderAliases =
        mapOf(
            "fc" to "nes",
            "fds" to "nes",
            "sfc" to "snes",
            "genesis" to "md",
            "mark3" to "sms",
            "mcd" to "scd",
            "tg16" to "pce",
            "arc" to "fbneo",
            "atari2600" to "a26",
            "atari7800" to "a78",
            "2600" to "a26",
            "7800" to "a78",
            "a2600" to "a26",
            "a7800" to "a78",
            "ps1" to "psx",
            "ngpc" to "ngp",
            "mame" to "mame2003",
            "nds" to "nds",
            "ds" to "nds",
        )

    private val byCanonical =
        mapOf(
            "nes" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                ),
            "snes" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                ),
            "gb" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                ),
            "gbc" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                ),
            "n64" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                    coreVariables =
                        mapOf(
                            "mupen64plus-43screensize" to "320x240",
                            "mupen64plus-FrameDuping" to "True",
                        ),
                ),
            "psx" to
                EmbeddedSystemTuning(
                    skipDuplicateFrames = false,
                    coreVariables =
                        mapOf(
                            "pcsx_rearmed_drc" to "disabled",
                        ),
                ),
            "psp" to
                EmbeddedSystemTuning(
                    coreVariables =
                        mapOf(
                            "ppsspp_frame_duplication" to "enabled",
                        ),
                ),
            "nds" to
                EmbeddedSystemTuning(
                    coreVariables =
                        mapOf(
                            "melonds_number_of_screen_layouts" to "1",
                            "melonds_touch_mode" to "Touch",
                            "melonds_threaded_renderer" to "enabled",
                        ),
                ),
            "3ds" to
                EmbeddedSystemTuning(
                    coreVariables =
                        mapOf(
                            "citra_use_acc_mul" to "disabled",
                            "citra_touch_touchscreen" to "enabled",
                            "citra_mouse_touchscreen" to "disabled",
                            "citra_render_touchscreen" to "disabled",
                            "citra_use_hw_shader_cache" to "disabled",
                        ),
                ),
        )

    fun canonicalSystemId(systemFolder: String): String =
        folderAliases[systemFolder] ?: systemFolder

    fun forSystem(systemFolder: String): EmbeddedSystemTuning =
        byCanonical[canonicalSystemId(systemFolder)] ?: EmbeddedSystemTuning()

    fun merge(base: LaunchTuning, systemFolder: String): LaunchTuning {
        val system = forSystem(systemFolder)
        return base.copy(
            skipDuplicateFrames =
                system.skipDuplicateFrames ?: base.skipDuplicateFrames,
            variables = system.coreVariables + base.variables,
        )
    }
}
