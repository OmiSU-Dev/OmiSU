package com.omisu.embedded

import android.content.Context
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.ZipInputStream

object PpssppAssetsManager {
    private const val ASSETS_VERSION = "1.17.0"
    private const val ASSETS_URL =
        "https://github.com/Swordfish90/LemuroidCores/raw/$ASSETS_VERSION/assets/ppsspp.zip"
    private const val FOLDER_NAME = "PPSSPP"

    fun ensureAssets(context: Context) {
        val systemDir = File(context.filesDir, "omisu/system").apply { mkdirs() }
        val assetsDir = File(systemDir, FOLDER_NAME)
        if (assetsDir.exists() && assetsDir.list()?.isNotEmpty() == true) {
            return
        }
        CoreResolver.statusListener?.invoke("Preparing PSP system files…")
        downloadAndExtract(assetsDir)
    }

    private fun downloadAndExtract(destRoot: File) {
        destRoot.deleteRecursively()
        destRoot.mkdirs()
        val connection = URL(ASSETS_URL).openConnection() as HttpURLConnection
        connection.connectTimeout = 30_000
        connection.readTimeout = 120_000
        try {
            connection.connect()
            if (connection.responseCode !in 200..299) {
                throw IllegalStateException("PPSSPP assets download failed (${connection.responseCode})")
            }
            connection.inputStream.use { raw ->
                ZipInputStream(raw).use { zip ->
                    while (true) {
                        val entry = zip.nextEntry ?: break
                        val out = File(destRoot, entry.name)
                        if (entry.isDirectory) {
                            out.mkdirs()
                        } else {
                            out.parentFile?.mkdirs()
                            out.outputStream().use { zip.copyTo(it) }
                        }
                        zip.closeEntry()
                    }
                }
            }
        } finally {
            connection.disconnect()
        }
    }
}
