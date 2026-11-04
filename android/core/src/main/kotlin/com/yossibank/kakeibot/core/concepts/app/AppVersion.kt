package com.yossibank.kakeibot.core.concepts.app

class AppVersion private constructor(
    val parts: List<Int>,
) : Comparable<AppVersion> {
    override fun compareTo(other: AppVersion): Int {
        val count = maxOf(parts.size, other.parts.size)

        for (index in 0 until count) {
            val left = parts.getOrElse(index) { 0 }
            val right = other.parts.getOrElse(index) { 0 }

            if (left != right) {
                return left.compareTo(right)
            }
        }

        return 0
    }

    override fun equals(other: Any?): Boolean = other is AppVersion && parts == other.parts

    override fun hashCode(): Int = parts.hashCode()

    companion object {
        fun parse(text: String): AppVersion? {
            val pieces = text.split(".")

            val numbers = pieces.mapNotNull { piece ->
                if (piece.all { it in '0'..'9' }) piece.toIntOrNull() else null
            }

            if (numbers.size != pieces.size) {
                return null
            }

            val parts = numbers.dropLastWhile { it == 0 }.ifEmpty { listOf(0) }

            return AppVersion(parts)
        }

        fun isNewer(
            latest: String,
            seen: String?,
        ): Boolean {
            val latestVersion = parse(latest) ?: return false
            val seenVersion = seen?.let(::parse) ?: return true

            return latestVersion > seenVersion
        }
    }
}
