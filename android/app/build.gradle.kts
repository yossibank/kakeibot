import javax.inject.Inject

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.yossibank.kakeibot"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.yossibank.kakeibot"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

kotlin {
    jvmToolchain(17)
}

val sqliteNatives: Configuration = configurations.create("sqliteNatives") {
    isCanBeConsumed = false
    isTransitive = false

    attributes {
        attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage.JAVA_RUNTIME))
    }
}

dependencies {
    implementation(project(":core"))
    implementation(project(":store"))
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.kotlinx.coroutines.core)
    debugImplementation(libs.androidx.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.kotlinx.coroutines.test)

    sqliteNatives(libs.sqlite.bundled.jvm)
}

interface ArchiveAccess {
    @get:Inject
    val archives: ArchiveOperations
}

val sqliteNativeDirectory = layout.buildDirectory.dir("sqlite-natives")

val syncSqliteNatives = tasks.register<Sync>("syncSqliteNatives") {
    val archives = objects.newInstance<ArchiveAccess>().archives

    from(sqliteNatives.elements.map { jars -> jars.map { archives.zipTree(it) } }) {
        include("natives/**")
    }

    into(sqliteNativeDirectory)
}

val sqliteNativePlatform: Pair<String, String> = run {
    val os = System.getProperty("os.name").lowercase()
    val arm = System.getProperty("os.arch") in setOf("aarch64", "arm64")

    when {
        os.contains("mac") -> "osx_arm64" to "libsqliteJni.dylib"
        os.contains("win") -> "windows_x64" to "sqliteJni.dll"
        arm -> "linux_arm64" to "libsqliteJni.so"
        else -> "linux_x64" to "libsqliteJni.so"
    }
}

tasks.withType<Test>().configureEach {
    val (platform, library) = sqliteNativePlatform
    val directory = sqliteNativeDirectory.get().dir("natives/$platform").asFile

    dependsOn(syncSqliteNatives)
    systemProperty("androidx.sqlite.driver.bundled.path", directory.absolutePath)
    systemProperty("androidx.sqlite.driver.bundled.name", library)
}
