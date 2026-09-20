import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseSigning = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
).all { key ->
    val value = keystoreProperties.getProperty(key)
    !value.isNullOrBlank()
}

android {
    namespace = "com.omisu.launcher"
    // permission_handler_android 14+ (permission_handler ^13) requires API 37.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.omisu.launcher"
        manifestPlaceholders["appName"] = "OmiSU"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("boolean", "PRELOADED_OEM", "true")
    }

    buildFeatures {
        buildConfig = true
    }

    flavorDimensions += "distribution"
    productFlavors {
        create("gamesir") {
            dimension = "distribution"
            manifestPlaceholders["appName"] = "OmiSU"
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        freeCompilerArgs.add(
            "-opt-in=io.github.thibaultbee.streampack.core.utils.InternalStreamPackApi",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.github.Swordfish90:LibretroDroid:0.13.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("androidx.lifecycle:lifecycle-common:2.8.7")
    implementation("io.github.thibaultbee.streampack:streampack-core:3.2.0")
    implementation("io.github.thibaultbee.streampack:streampack-services:3.2.0")
    implementation("io.github.thibaultbee.streampack:streampack-rtmp:3.2.0")
}
