plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    testImplementation(libs.junit)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.kotlinx.serialization.json)
}

tasks.test {
    systemProperty("fixtures", rootDir.resolve("../spec/fixtures").absolutePath)
}
