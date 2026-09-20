package com.omisu.embedded

import android.content.Context
import java.io.File
import java.io.FileOutputStream

object EmbeddedSavesManager {
    const val MAX_SLOTS = 4

    fun statesRoot(context: Context): File =
        File(context.filesDir, "omisu/states").apply { mkdirs() }

    fun sramRoot(context: Context): File =
        File(context.filesDir, "omisu/saves").apply { mkdirs() }

    fun romBaseName(romPath: String): String {
        val name = File(romPath).name
        val dot = name.lastIndexOf('.')
        return if (dot > 0) name.substring(0, dot) else name
    }

    fun slotFile(
        context: Context,
        coreName: String,
        romBase: String,
        slot: Int,
    ): File {
        require(slot in 1..MAX_SLOTS) { "slot must be 1..$MAX_SLOTS" }
        return File(statesRoot(context), "$coreName/$romBase.slot$slot")
    }

    fun autosaveFile(context: Context, coreName: String, romBase: String): File =
        File(statesRoot(context), "$coreName/$romBase.state")

    /** Libretro writes battery saves flat under [sramRoot] (Lemuroid convention). */
    fun libretroSramFile(context: Context, romBase: String): File =
        File(sramRoot(context), "$romBase.srm")

    /** Manual flush path (core-scoped); kept for backward compatibility. */
    fun sramFile(context: Context, coreName: String, romBase: String): File =
        File(sramRoot(context), "$coreName/$romBase.srm")

    /** Newest non-empty SRAM among libretro flat + legacy core-scoped paths. */
    fun newestSramFile(context: Context, coreName: String, romBase: String): File? =
        listOf(libretroSramFile(context, romBase), sramFile(context, coreName, romBase))
            .filter { it.exists() && it.length() > 0L }
            .maxByOrNull { it.lastModified() }

    fun previewFile(
        context: Context,
        coreName: String,
        romBase: String,
        slot: Int,
    ): File {
        require(slot in 1..MAX_SLOTS) { "slot must be 1..$MAX_SLOTS" }
        return File(
            File(context.filesDir, "omisu/state-previews/$coreName"),
            "$romBase.slot$slot.png",
        )
    }

    fun previewsRoot(context: Context): File =
        File(context.filesDir, "omisu/state-previews").apply { mkdirs() }

    /** Write via temp file + rename to avoid truncated saves on sudden exit. */
    fun writeBytesAtomic(file: File, bytes: ByteArray) {
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, "${file.name}.part")
        FileOutputStream(tmp).use { stream ->
            stream.write(bytes)
            stream.fd.sync()
        }
        if (!tmp.renameTo(file)) {
            tmp.copyTo(file, overwrite = true)
            tmp.delete()
        }
    }
}
