import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.apc.automotionplus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            // key.properties is ignored by git (see android/.gitignore)
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.apc.automotionplus"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Required for pay_android plugin
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // MEmu (and some other emulators) may run apps as a 32-bit process even on x86_64 system images.
        // Flutter 3.32+ debug APKs ship `libflutter.so` for x86_64 but not for x86 (32-bit), which can crash with:
        // "libflutter.so is 64-bit instead of 32-bit".
        //
        // Exclude x86 (32-bit) to avoid CMake configuration errors and only build for x86_64.
        // Set FORCE_X86_64=0 (or false/no) in your shell before `flutter run` to include x86 if needed.
        // Example (PowerShell):
        //   $env:FORCE_X86_64=1; flutter run -d <deviceId>
        val forceX86_64Env = (System.getenv("FORCE_X86_64") ?: "1").trim().lowercase()
        val forceX86_64 = forceX86_64Env != "0" && forceX86_64Env != "false" && forceX86_64Env != "no"
        if (forceX86_64) {
            ndk {
                abiFilters += setOf("x86_64", "arm64-v8a", "armeabi-v7a")
                abiFilters -= setOf("x86")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Fail fast if someone tries to build a release without configuring signing.
afterEvaluate {
    val isReleaseTask = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
    val keyPropertiesMissing = !rootProject.file("key.properties").exists()
    if (isReleaseTask && keyPropertiesMissing) {
        throw GradleException(
            "Missing android/key.properties. Copy android/key.properties.example to android/key.properties and fill it in."
        )
    }
}
