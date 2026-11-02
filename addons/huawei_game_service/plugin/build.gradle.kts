plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.logitivity.huawei"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = "HuaweiGameService"
        manifestPlaceholders["godotPluginPackageName"] = "com.logitivity.huawei"
        setProperty("archivesBaseName", "HuaweiGameService")
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }
}

dependencies {
    compileOnly("org.godotengine:godot:4.7.0.stable")
    implementation("com.huawei.hms:hwid:6.12.0.300")
    // Huawei removed achievement and leaderboard APIs in 6.14.0.300; 6.13 retains them.
    implementation("com.huawei.hms:game:6.13.0.300")
}
val copyDebugAar by tasks.registering(Copy::class) {
    from(layout.buildDirectory.file("outputs/aar/HuaweiGameService-debug.aar"))
    into(layout.projectDirectory.dir("../bin/debug"))
}
val copyReleaseAar by tasks.registering(Copy::class) {
    from(layout.buildDirectory.file("outputs/aar/HuaweiGameService-release.aar"))
    into(layout.projectDirectory.dir("../bin/release"))
}

tasks.configureEach { if (name == "assembleDebug") finalizedBy(copyDebugAar) }
tasks.configureEach { if (name == "assembleRelease") finalizedBy(copyReleaseAar) }


