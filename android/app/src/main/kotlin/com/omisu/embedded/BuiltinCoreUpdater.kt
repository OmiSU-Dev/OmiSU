package com.omisu.embedded

import android.content.Context

object BuiltinCoreUpdater {
    const val BUNDLED_LIBRETRODROID_VERSION = "0.13.2"

    fun getCoresVersion(context: Context): String =
        BuiltinCoresStore.getActiveVersion(context)

    fun setCoresVersion(context: Context, version: String) {
        BuiltinCoresStore.setActiveVersion(context, version)
        CoreResolver.pruneOldCoreVersions(context, version)
    }

    /**
     * Downloads all registered libretro cores for [version]. Returns count of cores
     * successfully present after the pass (existing or newly downloaded).
     */
    fun downloadAllCores(context: Context, version: String): Int {
        var successCount = 0
        for (mapping in CoreMappingRegistry.uniqueCores()) {
            try {
                if (mapping.coreName == "ppsspp") {
                    PpssppAssetsManager.ensureAssets(context)
                }
                CoreResolver.downloadCoreToStore(context, mapping, version)
                successCount++
            } catch (_: Exception) {
                // Caller decides whether partial success is acceptable.
            }
        }
        return successCount
    }

    fun downloadLibretroDroidEngine(context: Context, version: String): Boolean =
        LibretroDroidEngineUpdater.downloadAndInstall(context, version)

    fun getActiveLibretroDroidVersion(context: Context): String =
        LibretroDroidEngineUpdater.getActiveVersion(context)
}
