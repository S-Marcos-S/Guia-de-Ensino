plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.guiadeensino.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.guiadeensino.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val keyAliasVal = System.getenv("ANDROID_KEY_ALIAS")
    val keyPasswordVal = System.getenv("ANDROID_KEY_PASSWORD")
    val isOfficialRelease = System.getenv("OFFICIAL_RELEASE")?.toBoolean() == true ||
        project.hasProperty("officialRelease")

    val hasReleaseSigning = !keystorePath.isNullOrBlank() &&
        !keystorePassword.isNullOrBlank() &&
        !keyAliasVal.isNullOrBlank() &&
        !keyPasswordVal.isNullOrBlank()

    signingConfigs {
        if (hasReleaseSigning) {
            val keyFile = file(keystorePath!!)
            if (!keyFile.exists()) {
                throw org.gradle.api.GradleException(
                    "Arquivo de keystore de produção '$keystorePath' especificado em ANDROID_KEYSTORE_PATH não foi encontrado."
                )
            }
            create("release") {
                storeFile = keyFile
                storePassword = keystorePassword
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (isOfficialRelease) {
                throw org.gradle.api.GradleException(
                    "Build oficial de produção rejeitado: OFFICIAL_RELEASE está ativo, mas as variáveis de assinatura de produção (ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD) não foram fornecidas."
                )
            } else {
                logger.warn(
                    "AVISO: Assinatura de produção não configurada. Utilizando chave debug para compilação local de desenvolvimento."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
