plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "gt.kan.kan_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    val releaseKeystore = System.getenv("ZPK_RELEASE_KEYSTORE")
    val releaseStorePassword = System.getenv("ZPK_RELEASE_STORE_PASSWORD")
    val releaseKeyAlias = System.getenv("ZPK_RELEASE_KEY_ALIAS")
    val releaseKeyPassword = System.getenv("ZPK_RELEASE_KEY_PASSWORD")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "gt.kan.kan_app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (
            releaseKeystore != null &&
            releaseStorePassword != null &&
            releaseKeyAlias != null &&
            releaseKeyPassword != null
        ) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            // Suffix permite instalar APK debug junto al release sin chocar
            // de firma. Resultado: gt.kan.kan_app.citizenpreview side-by-side.
            applicationIdSuffix = ".citizenpreview"
            versionNameSuffix = "-citizenpreview"
        }
        release {
            signingConfigs.findByName("release")?.let {
                signingConfig = it
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.ai.edge.litertlm:litertlm-android:0.10.2")
    implementation("com.google.mlkit:genai-prompt:1.0.0-beta1")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}
