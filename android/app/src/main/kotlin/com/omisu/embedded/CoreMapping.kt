package com.omisu.embedded

data class CoreMapping(
    val systemId: String,
    val coreName: String,
    val libretroFileName: String,
)

object CoreMappingRegistry {
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
            "ds" to "nds",
        )

    private val canonicalMappings =
        listOf(
            CoreMapping("nes", "fceumm", "libfceumm_libretro_android.so"),
            CoreMapping("snes", "snes9x", "libsnes9x_libretro_android.so"),
            CoreMapping("md", "genesis_plus_gx", "libgenesis_plus_gx_libretro_android.so"),
            CoreMapping("gb", "gambatte", "libgambatte_libretro_android.so"),
            CoreMapping("gbc", "gambatte", "libgambatte_libretro_android.so"),
            CoreMapping("gba", "mgba", "libmgba_libretro_android.so"),
            CoreMapping("n64", "mupen64plus_next_gles3", "libmupen64plus_next_gles3_libretro_android.so"),
            CoreMapping("sms", "genesis_plus_gx", "libgenesis_plus_gx_libretro_android.so"),
            CoreMapping("gg", "genesis_plus_gx", "libgenesis_plus_gx_libretro_android.so"),
            CoreMapping("psp", "ppsspp", "libppsspp_libretro_android.so"),
            CoreMapping("nds", "melonds", "libmelonds_libretro_android.so"),
            CoreMapping("a26", "stella", "libstella_libretro_android.so"),
            CoreMapping("a78", "prosystem", "libprosystem_libretro_android.so"),
            CoreMapping("ps1", "pcsx_rearmed", "libpcsx_rearmed_libretro_android.so"),
            CoreMapping("fbneo", "fbneo", "libfbneo_libretro_android.so"),
            CoreMapping("mame", "mame2003_plus", "libmame2003_plus_libretro_android.so"),
            CoreMapping("pce", "mednafen_pce_fast", "libmednafen_pce_fast_libretro_android.so"),
            CoreMapping("lynx", "handy", "libhandy_libretro_android.so"),
            CoreMapping("scd", "genesis_plus_gx", "libgenesis_plus_gx_libretro_android.so"),
            CoreMapping("ngp", "mednafen_ngp", "libmednafen_ngp_libretro_android.so"),
            CoreMapping("ngpc", "mednafen_ngp", "libmednafen_ngp_libretro_android.so"),
            CoreMapping("ws", "mednafen_wswan", "libmednafen_wswan_libretro_android.so"),
            CoreMapping("wsc", "mednafen_wswan", "libmednafen_wswan_libretro_android.so"),
            CoreMapping("dos", "dosbox_pure", "libdosbox_pure_libretro_android.so"),
            CoreMapping("3ds", "citra", "libcitra_libretro_android.so"),
        )

    private val byCanonicalId = canonicalMappings.associateBy { it.systemId }

    fun forSystem(systemId: String): CoreMapping? {
        val canonical = folderAliases[systemId] ?: systemId
        val base = byCanonicalId[canonical] ?: return null
        if (canonical == systemId) return base
        return base.copy(systemId = systemId)
    }

    fun uniqueCores(): List<CoreMapping> {
        val seen = mutableSetOf<String>()
        return canonicalMappings.filter { seen.add(it.coreName) }
    }
}
