package com.yossibank.kakeibot.featuremodels.shared.datechoice

import com.yossibank.kakeibot.core.concepts.date.Weekday

val Weekday.shortName: String
    get() = when (this) {
        Weekday.monday -> "月"
        Weekday.tuesday -> "火"
        Weekday.wednesday -> "水"
        Weekday.thursday -> "木"
        Weekday.friday -> "金"
        Weekday.saturday -> "土"
        Weekday.sunday -> "日"
    }
