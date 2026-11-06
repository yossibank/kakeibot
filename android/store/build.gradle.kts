plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.ksp)
    alias(libs.plugins.room)
}

kotlin {
    jvmToolchain(17)
}

room {
    schemaDirectory("$projectDir/schemas")
}

dependencies {
    implementation(project(":core"))
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.room.runtime)
    implementation(libs.sqlite.bundled)

    ksp(libs.room.compiler)

    testImplementation(libs.junit)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.kotlinx.coroutines.test)
}

tasks.test {
    val fixtures = rootDir.resolve("../spec/fixtures")

    inputs.dir(fixtures).withPathSensitivity(PathSensitivity.RELATIVE)
    systemProperty("fixtures", fixtures.absolutePath)
}
