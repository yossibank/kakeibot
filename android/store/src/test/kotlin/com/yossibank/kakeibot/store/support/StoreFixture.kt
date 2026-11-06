package com.yossibank.kakeibot.store.support

import java.io.File

object StoreFixture {
    fun data(path: String): ByteArray {
        val root = System.getProperty("fixtures") ?: error("fixtures の場所が渡されていない")

        return File(root, path).readBytes()
    }
}
