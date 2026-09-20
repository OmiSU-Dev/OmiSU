package com.omisu.embedded

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.zip.ZipInputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

data class ResolvedRom(
    val gameFilePath: String,
    val displayName: String,
)

object CoreResolver {
    private const val TAG = "CoreResolver"
    private const val CORES_BASE = "https://github.com/Swordfish90/LemuroidCores/raw"

    var statusListener: ((String) -> Unit)? = null

    private fun emitStatus(message: String) {
        statusListener?.invoke(message)
    }

    fun resolve(context: Context, mapping: CoreMapping): File {
        findBundled(context, mapping)?.let {
            emitStatus("ready")
            return it
        }
        findDownloaded(context, mapping)?.let {
            emitStatus("ready")
            return it
        }
        return downloadCore(context, mapping)
    }

    fun downloadCoreToStore(
        context: Context,
        mapping: CoreMapping,
        version: String,
    ): File {
        val dest = File(coresDirectory(context, version), mapping.libretroFileName)
        if (dest.exists() && dest.length() > 0) {
            return dest
        }
        return downloadCore(context, mapping, version, dest)
    }

    private fun findBundled(context: Context, mapping: CoreMapping): File? {
        val nativeDir = File(context.applicationInfo.nativeLibraryDir)
        return nativeDir.listFiles()?.firstOrNull { it.name == mapping.libretroFileName }
    }

    private fun coresDirectory(context: Context, version: String): File {
        return File(context.filesDir, "omisu/cores/$version").apply { mkdirs() }
    }

    private fun findDownloaded(context: Context, mapping: CoreMapping): File? {
        val version = BuiltinCoresStore.getActiveVersion(context)
        val file = File(coresDirectory(context, version), mapping.libretroFileName)
        return file.takeIf { it.exists() && it.length() > 0 }
    }

    private fun downloadCore(context: Context, mapping: CoreMapping): File {
        val version = BuiltinCoresStore.getActiveVersion(context)
        val dest = File(coresDirectory(context, version), mapping.libretroFileName)
        return downloadCore(context, mapping, version, dest)
    }

    private fun downloadCore(
        context: Context,
        mapping: CoreMapping,
        version: String,
        dest: File,
    ): File {
        if (Looper.getMainLooper().thread != Thread.currentThread()) {
            return downloadCoreNetwork(context, mapping, version, dest)
        }

        // PlatformView creation runs on the main thread; network there throws
        // NetworkOnMainThreadException and leaves the loading overlay stuck.
        val result = AtomicReference<File>()
        val error = AtomicReference<Exception>()
        val latch = CountDownLatch(1)
        Thread(
            {
                try {
                    result.set(downloadCoreNetwork(context, mapping, version, dest))
                } catch (e: Exception) {
                    error.set(e)
                } finally {
                    latch.countDown()
                }
            },
            "omisu-core-download",
        ).start()

        if (!latch.await(150, TimeUnit.SECONDS)) {
            throw IllegalStateException(
                "Timed out downloading ${mapping.libretroFileName}. Check your network connection.",
            )
        }
        error.get()?.let { throw it }
        return result.get()
            ?: throw IllegalStateException(
                "Failed to download ${mapping.libretroFileName}",
            )
    }

    private fun downloadCoreNetwork(
        context: Context,
        mapping: CoreMapping,
        version: String,
        dest: File,
    ): File {
        val abi = Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"
        val url =
            "$CORES_BASE/$version/lemuroid_core_${mapping.coreName}/src/main/jniLibs/$abi/${mapping.libretroFileName}"
        dest.parentFile?.mkdirs()
        emitStatus("Preparing built-in player…")
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 30_000
        connection.readTimeout = 120_000
        connection.requestMethod = "GET"
        connection.instanceFollowRedirects = true
        try {
            connection.connect()
            if (connection.responseCode !in 200..299) {
                throw IllegalStateException("Core download failed (${connection.responseCode}): $url")
            }
            connection.inputStream.use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            if (!dest.exists() || dest.length() == 0L) {
                throw IllegalStateException("Downloaded core is empty: ${mapping.libretroFileName}")
            }
            emitStatus("ready")
            return dest
        } finally {
            connection.disconnect()
        }
    }

    fun pruneOldCoreVersions(context: Context, keepVersion: String) {
        val coresRoot = File(context.filesDir, "omisu/cores")
        if (!coresRoot.exists()) return
        coresRoot.listFiles()?.forEach { dir ->
            if (dir.isDirectory && dir.name != keepVersion) {
                dir.deleteRecursively()
            }
        }
    }

    /**
     * Resolves a ROM to a local filesystem path LibretroDroid can load.
     * SAF [content://] URIs are copied into app cache (Lemuroid pattern for most cores).
     */
    fun resolveRomForPlay(context: Context, romPath: String): ResolvedRom {
        if (!romPath.startsWith("content://")) {
            val file = File(romPath)
            if (!file.exists() || file.length() == 0L) {
                throw IllegalStateException("ROM file missing or empty: $romPath")
            }
            val loadable = prepareLoadableRomFile(file)
            Log.i(TAG, "Using filesystem ROM ${loadable.name} (${loadable.length()} bytes)")
            return ResolvedRom(
                gameFilePath = loadable.absolutePath,
                displayName = loadable.name,
            )
        }

        val uri = Uri.parse(romPath)
        val displayName = queryDisplayName(context, uri) ?: "rom_${uri.hashCode()}.bin"
        val cacheDir = File(context.cacheDir, "omisu/rom_cache").apply { mkdirs() }
        val dest = File(cacheDir, "${uri.hashCode()}_$displayName")
        if (!dest.exists() || dest.length() == 0L) {
            emitStatus("Loading game…")
            context.contentResolver.openInputStream(uri)?.use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            } ?: throw IllegalStateException("Cannot open ROM URI: $romPath")
            if (!dest.exists() || dest.length() == 0L) {
                throw IllegalStateException("Copied ROM is empty: $displayName")
            }
        }
        val loadable = prepareLoadableRomFile(dest)
        Log.i(
            TAG,
            "Using cached ROM ${loadable.name} (${loadable.length()} bytes) from content URI",
        )
        return ResolvedRom(
            gameFilePath = loadable.absolutePath,
            displayName = loadable.name,
        )
    }

    private val loadableRomExtensions =
        setOf(
            "smc", "sfc", "fig", "swc", "nes", "fds", "unf", "unif",
            "gb", "gbc", "gba", "md", "smd", "gen", "bin", "cue", "iso",
            "cso", "pbp", "chd",
            "pce", "ngp", "ngc", "ws", "wsc", "n64", "z64", "v64", "nds",
        )

    /**
     * Libretro cores handle some archives, but loading the inner ROM file directly
     * is more reliable (especially for SNES zip sets with multiple files).
     */
    private fun prepareLoadableRomFile(source: File): File {
        if (!source.name.endsWith(".zip", ignoreCase = true)) {
            return source
        }
        val extractRoot =
            File(source.parentFile, "${source.nameWithoutExtension}_unzipped").apply { mkdirs() }
        val marker = File(extractRoot, ".source_${source.length()}_${source.lastModified()}")
        if (marker.exists()) {
            findLoadableRomIn(extractRoot)?.let { return it }
        }
        extractRoot.listFiles()?.forEach { it.deleteRecursively() }
        extractRoot.mkdirs()

        var chosen: File? = null
        ZipInputStream(source.inputStream()).use { zip ->
            var entry = zip.nextEntry
            while (entry != null) {
                if (!entry.isDirectory && isLoadableRomEntry(entry.name)) {
                    val outName = sanitizeRomFileName(File(entry.name).name)
                    val outFile = File(extractRoot, outName)
                    outFile.outputStream().use { output -> zip.copyTo(output) }
                    if (chosen == null || outFile.length() > (chosen?.length() ?: 0L)) {
                        chosen = outFile
                    }
                }
                zip.closeEntry()
                entry = zip.nextEntry
            }
        }
        val extracted =
            chosen?.takeIf { it.exists() && it.length() > 0L }
                ?: throw IllegalStateException("No loadable ROM found inside ${source.name}")
        marker.writeText(source.absolutePath)
        Log.i(TAG, "Extracted ${extracted.name} from ${source.name}")
        return extracted
    }

    private fun findLoadableRomIn(dir: File): File? =
        dir.walkTopDown()
            .filter { it.isFile && isLoadableRomEntry(it.name) }
            .maxByOrNull { it.length() }

    private fun isLoadableRomEntry(name: String): Boolean {
        val ext = name.substringAfterLast('.', "").lowercase(Locale.US)
        return ext in loadableRomExtensions
    }

    private fun sanitizeRomFileName(name: String): String =
        name.replace(Regex("[^A-Za-z0-9._-]"), "_")

    fun resolveRomPath(context: Context, romPath: String): String =
        resolveRomForPlay(context, romPath).gameFilePath

    private fun queryDisplayName(context: Context, uri: Uri): String? {
        context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }
}
