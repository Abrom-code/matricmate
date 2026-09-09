import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.abopia.matricet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // Required by flutter_local_notifications ^22.x
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.abopia.matricet"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val alias = keystoreProperties.getProperty("keyAlias")
                val keyPass = keystoreProperties.getProperty("keyPassword")
                val storePass = keystoreProperties.getProperty("storePassword")
                val storeFilePath = keystoreProperties.getProperty("storeFile")

                if (!alias.isNullOrEmpty() && !keyPass.isNullOrEmpty() && !storePass.isNullOrEmpty() && !storeFilePath.isNullOrEmpty()) {
                    val keystoreFile = rootProject.file(storeFilePath).takeIf { it.exists() }
                        ?: file(storeFilePath).takeIf { it.exists() }
                        ?: file(storeFilePath)

                    keyAlias = alias
                    keyPassword = keyPass
                    storePassword = storePass
                    storeFile = keystoreFile
                }
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Production releases must strictly use release signing. Never fall back to debug.
                signingConfig = null
            }

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Ensure release builds fail immediately and explicitly if signing configuration is missing
tasks.matching {
    (it.name.contains("Release", ignoreCase = true) || it.name.contains("bundle", ignoreCase = true)) &&
    !it.name.contains("lint", ignoreCase = true) &&
    !it.name.contains("test", ignoreCase = true)
}.configureEach {
    doFirst {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                """
                |
                |========================================================================================
                |RELEASE BUILD FAILED: Missing 'android/key.properties'.
                |Production release builds must be signed with your release/upload keystore.
                |Debug signing fallback is strictly disabled for release builds.
                |
                |Please create 'android/key.properties' with the following entries:
                |  storePassword=<your-store-password>
                |  keyPassword=<your-key-password>
                |  keyAlias=<your-key-alias>
                |  storeFile=app/upload-keystore.jks
                |========================================================================================
                """.trimMargin()
            )
        }
        val alias = keystoreProperties.getProperty("keyAlias")
        val keyPass = keystoreProperties.getProperty("keyPassword")
        val storePass = keystoreProperties.getProperty("storePassword")
        val storeFilePath = keystoreProperties.getProperty("storeFile")
        if (alias.isNullOrEmpty() || keyPass.isNullOrEmpty() || storePass.isNullOrEmpty() || storeFilePath.isNullOrEmpty()) {
            throw GradleException(
                """
                |
                |========================================================================================
                |RELEASE BUILD FAILED: 'android/key.properties' is incomplete.
                |It must specify: keyAlias, keyPassword, storePassword, and storeFile.
                |========================================================================================
                """.trimMargin()
            )
        }
        val keystoreFile = rootProject.file(storeFilePath).takeIf { it.exists() }
            ?: file(storeFilePath).takeIf { it.exists() }
        if (keystoreFile == null || !keystoreFile.exists()) {
            throw GradleException(
                """
                |
                |========================================================================================
                |RELEASE BUILD FAILED: Keystore file '$storeFilePath' defined in 'key.properties' does not exist.
                |========================================================================================
                """.trimMargin()
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}