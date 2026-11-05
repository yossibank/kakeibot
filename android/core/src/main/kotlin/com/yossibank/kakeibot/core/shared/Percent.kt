package com.yossibank.kakeibot.core.shared

object Percent {
    fun floor(
        part: Int,
        of: Int,
    ): Int {
        if (of <= 0) {
            return 0
        }

        val percent = (part.toLong() * 100 / of).toInt()

        return percent.coerceIn(0, 100)
    }

    fun shares(parts: List<Int>): List<Int> {
        val whole = parts.fold(0L) { sum, part -> sum + part }

        if (whole <= 0) {
            return parts.map { 0 }
        }

        val percents = parts.map { (it.toLong() * 100 / whole).toInt() }.toMutableList()
        val rest = 100 - percents.sum()

        val order = parts.indices.sortedWith { lhs, rhs ->
            val lhsRest = parts[lhs].toLong() * 100 % whole
            val rhsRest = parts[rhs].toLong() * 100 % whole

            if (lhsRest == rhsRest) lhs.compareTo(rhs) else rhsRest.compareTo(lhsRest)
        }

        for (index in order.take(rest)) {
            percents[index] += 1
        }

        return percents
    }
}
