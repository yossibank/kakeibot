import javax.inject.Inject

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.yossibank.kakeibot.featuremodels"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
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
    api(project(":core"))
    api(project(":store"))
    api(platform(libs.androidx.compose.bom))
    api(libs.androidx.compose.runtime)
    implementation(libs.kotlinx.coroutines.core)

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
        os.contains("mac") && arm -> "osx_arm64" to "libsqliteJni.dylib"
        os.contains("mac") -> error("sqlite-bundled-jvm に macOS の Intel 向けの部品が無い")
        os.contains("win") -> "windows_x64" to "sqliteJni.dll"
        arm -> "linux_arm64" to "libsqliteJni.so"
        else -> "linux_x64" to "libsqliteJni.so"
    }
}

tasks.withType<Test>().configureEach {
    val (platform, library) = sqliteNativePlatform
    val directory = sqliteNativeDirectory.get().dir("natives/$platform").asFile

    val fixtures = rootDir.resolve("../spec/fixtures")

    dependsOn(syncSqliteNatives)
    inputs.dir(fixtures).withPathSensitivity(PathSensitivity.RELATIVE)
    systemProperty("fixtures", fixtures.absolutePath)
    systemProperty("androidx.sqlite.driver.bundled.path", directory.absolutePath)
    systemProperty("androidx.sqlite.driver.bundled.name", library)
}
