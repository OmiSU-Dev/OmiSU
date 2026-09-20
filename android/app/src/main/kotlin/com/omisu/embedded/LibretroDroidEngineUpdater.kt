package com.omisu.embedded

import android.content.Context
import android.os.Build
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.ZipInputStream

object LibretroDroidEngineUpdater {
    private const val JITPACK_AAR =
        "https://jitpack.io/com/github/Swordfish90/LibretroDroid/%s/LibretroDroid-%s.aar"

    fun getActiveVersion(context: Context): String {
        val stored = LibretroDroidEngineStore.getActiveVersion(context)
        return if (hasInstalledEngineLibs(context, stored)) {
            stored
        } else {
            BuiltinCoreUpdater.BUNDLED_LIBRETRODROID_VERSION
        }
    }

    /**
     * Copies a previously downloaded engine into [nativeLibraryDir] so
     * [System.loadLibrary] picks it up before the first [GLRetroView] is created.
     */
    fun applyPendingEngineLibs(context: Context): Boolean {
        val version = getActiveVersion(context)
        if (!isVersionNewer(version, BuiltinCoreUpdater.BUNDLED_LIBRETRODROID_VERSION)) {
            return false
        }
        return copyEngineLibs(context, version)
    }

    /**
     * Downloads LibretroDroid [version] from JitPack, extracts JNI libs, and installs them.
     */
    fun downloadAndInstall(context: Context, version: String): Boolean {
        val engineRoot = engineDirectory(context, version)
        if (!engineRoot.exists() || !hasJniLibs(context, version)) {
            if (!downloadAar(context, version)) {
                return false
            }
        }
        if (!copyEngineLibs(context, version)) {
            return false
        }
        LibretroDroidEngineStore.setActiveVersion(context, version)
        pruneOldEngineVersions(context, version)
        return true
    }

    private fun downloadAar(context: Context, version: String): Boolean {
        val destRoot = engineDirectory(context, version)
        destRoot.mkdirs()
        val aarFile = File(context.cacheDir, "libretrodroid-$version.aar")
        val url = JITPACK_AAR.format(version, version)
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 30_000
        connection.readTimeout = 180_000
        connection.requestMethod = "GET"
        try {
            connection.connect()
            if (connection.responseCode !in 200..299) {
                return false
            }
            connection.inputStream.use { input ->
                aarFile.outputStream().use { output -> input.copyTo(output) }
            }
            if (!aarFile.exists() || aarFile.length() == 0L) {
                return false
            }
            return extractAar(aarFile, destRoot)
        } finally {
            connection.disconnect()
            aarFile.delete()
        }
    }

    private fun extractAar(aarFile: File, destRoot: File): Boolean {
        var extracted = false
        ZipInputStream(aarFile.inputStream()).use { zip ->
            var entry = zip.nextEntry
            while (entry != null) {
                if (!entry.isDirectory && entry.name.startsWith("jni/") && entry.name.endsWith(".so")) {
                    val outFile = File(destRoot, entry.name)
                    outFile.parentFile?.mkdirs()
                    outFile.outputStream().use { output -> zip.copyTo(output) }
                    extracted = true
                }
                zip.closeEntry()
                entry = zip.nextEntry
            }
        }
        return extracted
    }

    private fun hasJniLibs(context: Context, version: String): Boolean {
        val abi = Build.SUPPORTED_ABIS.firstOrNull() ?: return false
        val dir = File(engineDirectory(context, version), "jni/$abi")
        return dir.exists() && dir.listFiles()?.any { it.name.endsWith(".so") } == true
    }

    private fun copyEngineLibs(context: Context, version: String): Boolean {
        val abi = Build.SUPPORTED_ABIS.firstOrNull() ?: return false
        val sourceDir = File(engineDirectory(context, version), "jni/$abi")
        if (!sourceDir.exists()) return false
        val destDir = File(context.applicationInfo.nativeLibraryDir)
        var copied = 0
        sourceDir.listFiles()?.filter { it.isFile && it.name.endsWith(".so") }?.forEach { source ->
            val dest = File(destDir, source.name)
            source.inputStream().use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            dest.setReadable(true, false)
            dest.setExecutable(true, false)
            copied++
        }
        return copied > 0
    }

    private fun engineDirectory(context: Context, version: String): File =
        File(context.filesDir, "omisu/engine/$version")

    private fun hasInstalledEngineLibs(context: Context, version: String): Boolean =
        hasJniLibs(context, version)

    fun pruneOldEngineVersions(context: Context, keepVersion: String) {
        val root = File(context.filesDir, "omisu/engine")
        if (!root.exists()) return
        root.listFiles()?.forEach { dir ->
            if (dir.isDirectory && dir.name != keepVersion) {
                dir.deleteRecursively()
            }
        }
    }

    fun isVersionNewer(candidate: String, baseline: String): Boolean {
        fun parse(v: String): List<Int> =
            v.split('.').map { part -> part.trim().toIntOrNull() ?: 0 }
        val a = parse(candidate)
        val b = parse(baseline)
        val len = maxOf(a.size, b.size)
        for (i in 0 until len) {
            val av = a.getOrElse(i) { 0 }
            val bv = b.getOrElse(i) { 0 }
            if (av != bv) return av > bv
        }
        return false
    }
}
