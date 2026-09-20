package com.omisu.embedded

import android.content.Context
import android.util.Log
import com.swordfish.libretrodroid.ShaderConfig

object EmbeddedShaderChooser {
    private const val TAG = "EmbeddedShader"

    fun shaderFor(
        context: Context,
        systemId: String,
        filter: String,
        hdMode: Boolean,
        requestedHdModeQuality: EmbeddedHdModeQuality = EmbeddedHdModeQuality.MEDIUM,
    ): ShaderConfig {
        val hdModeQuality =
            if (EmbeddedGlUtils.getGLSLVersion(context) >= 3) {
                requestedHdModeQuality
            } else {
                Log.i(
                    TAG,
                    "GLES2 device — clamping HD quality to LOW (requested=$requestedHdModeQuality)",
                )
                EmbeddedHdModeQuality.LOW
            }

        return if (hdMode) {
            hdShaderForSystem(systemId, hdModeQuality)
        } else {
            when (filter) {
                "crt" -> ShaderConfig.CRT
                "lcd" -> ShaderConfig.LCD
                "sharp" -> ShaderConfig.Sharp
                "smooth" -> ShaderConfig.Default
                else -> defaultForSystem(systemId)
            }
        }
    }

    private fun hdShaderForSystem(
        systemId: String,
        hdModeQuality: EmbeddedHdModeQuality,
    ): ShaderConfig {
        return when (hdModeQuality) {
            EmbeddedHdModeQuality.LOW -> lowQualityHdShader(systemId)
            EmbeddedHdModeQuality.MEDIUM -> mediumQualityHdShader(systemId)
            EmbeddedHdModeQuality.HIGH -> highQualityHdShader(systemId)
        }
    }

    /** Lemuroid low-quality HD presets (CUT). */
    private fun lowQualityHdShader(systemId: String): ShaderConfig {
        val upscale8BitsMobile =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.85f,
            )
        val upscale8Bits =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
            )
        val upscale16BitsMobile =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.60f,
                blendMaxSharpness = 0.85f,
            )
        val upscale16Bits =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.60f,
                blendMaxSharpness = 0.75f,
            )
        val upscale32Bits =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.25f,
                blendMaxContrastEdge = 0.75f,
                blendMaxSharpness = 0.75f,
            )
        val modern =
            ShaderConfig.CUT(
                blendMinContrastEdge = 0.25f,
                blendMaxContrastEdge = 0.75f,
                blendMaxSharpness = 0.50f,
            )
        return hdPresetForSystem(
            systemId,
            upscale16BitsMobile,
            upscale8BitsMobile,
            upscale32Bits,
            upscale16Bits,
            upscale8Bits,
            modern,
        )
    }

    /** Lemuroid medium-quality HD presets (CUT2) — previous OmiSU default. */
    private fun mediumQualityHdShader(systemId: String): ShaderConfig {
        val upscale8BitsMobile =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.30f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.50f,
            )
        val upscale8Bits =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.30f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.50f,
            )
        val upscale16BitsMobile =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.75f,
            )
        val upscale16Bits =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        val upscale32Bits =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        val modern =
            ShaderConfig.CUT2(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.50f,
                hardEdgesSearchMaxError = 0.25f,
            )
        return hdPresetForSystem(
            systemId,
            upscale16BitsMobile,
            upscale8BitsMobile,
            upscale32Bits,
            upscale16Bits,
            upscale8Bits,
            modern,
        )
    }

    /** Lemuroid high-quality HD presets (CUT3). */
    private fun highQualityHdShader(systemId: String): ShaderConfig {
        val upscale8BitsMobile =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.30f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.50f,
            )
        val upscale8Bits =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.00f,
                blendMaxContrastEdge = 0.30f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.50f,
            )
        val upscale16BitsMobile =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        val upscale16Bits =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        val upscale32Bits =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        val modern =
            ShaderConfig.CUT3(
                blendMinContrastEdge = 0.10f,
                blendMaxContrastEdge = 0.50f,
                blendMaxSharpness = 0.75f,
                hardEdgesSearchMaxError = 0.25f,
            )
        return hdPresetForSystem(
            systemId,
            upscale16BitsMobile,
            upscale8BitsMobile,
            upscale32Bits,
            upscale16Bits,
            upscale8Bits,
            modern,
        )
    }

    private fun hdPresetForSystem(
        systemId: String,
        upscale16BitsMobile: ShaderConfig,
        upscale8BitsMobile: ShaderConfig,
        upscale32Bits: ShaderConfig,
        upscale16Bits: ShaderConfig,
        upscale8Bits: ShaderConfig,
        modern: ShaderConfig,
    ): ShaderConfig {
        return when (canonicalSystemId(systemId)) {
            "gba" -> upscale16BitsMobile
            "gbc", "gb", "gg", "lynx", "ngp", "ngpc" -> upscale8BitsMobile
            "n64", "fbneo", "mame2003", "nds", "psx", "dos" -> upscale32Bits
            "ws", "wsc" -> upscale16BitsMobile
            "md", "scd", "pce", "snes" -> upscale16Bits
            "nes", "sms", "a26", "a78" -> upscale8Bits
            "psp", "3ds" -> modern
            else -> upscale16Bits
        }
    }

    private fun defaultForSystem(systemId: String): ShaderConfig {
        return when (canonicalSystemId(systemId)) {
            "gb", "gbc", "gba", "gg", "lynx", "ngp", "ngpc", "ws", "wsc", "psp", "nds", "3ds" ->
                ShaderConfig.LCD
            else -> ShaderConfig.CRT
        }
    }

    private fun canonicalSystemId(systemId: String): String =
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
        )[systemId] ?: systemId
}
