package com.yossibank.kakeibot.store.records.settingkeys

import com.yossibank.kakeibot.core.concepts.date.HolidayShift
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.core.concepts.setting.LaunchScreen
import com.yossibank.kakeibot.core.concepts.setting.Setting

val SettingKey.Companion.monthStartDay: SettingKey<MonthStartDay>
    get() {
        val day = of(
            key = Setting.Key.monthStartDay,
            default = MonthStartDay.first,
            decode = { text -> decimalInt(text)?.let { MonthStartDay.of(it) } },
            encode = { it.day.toString() },
        )

        val shift = monthStartShift

        return SettingKey(
            defaultValue = day.defaultValue,
            read = { database ->
                val startDay = day.read(database)
                val holidayShift = shift.read(database)

                startDay.shifted(holidayShift)
            },
            write = { startDay, database ->
                day.write(startDay, database)
                shift.write(startDay.shift, database)
            },
        )
    }

val SettingKey.Companion.budgetCarryoverFrom: SettingKey<YearMonth?>
    get() = of(
        key = Setting.Key.budgetCarryoverFrom,
        default = null,
        decode = { YearMonth.parse(it) },
        encode = { it?.toString() },
    )

val SettingKey.Companion.weekStart: SettingKey<Weekday>
    get() = raw(
        key = Setting.Key.weekStart,
        default = Weekday.sunday,
        parse = Weekday::of,
        rawValue = { it.rawValue },
    )

val SettingKey.Companion.reminderTime: SettingKey<ReminderTime?>
    get() = of(
        key = Setting.Key.reminderTime,
        default = null,
        decode = { ReminderTime.parse(it) },
        encode = { it?.toString() },
    )

val SettingKey.Companion.launchScreen: SettingKey<LaunchScreen>
    get() = raw(
        key = Setting.Key.launchScreen,
        default = LaunchScreen.home,
        parse = LaunchScreen::of,
        rawValue = { it.rawValue },
    )

private val SettingKey.Companion.monthStartShift: SettingKey<HolidayShift>
    get() = of(
        key = Setting.Key.monthStartShift,
        default = HolidayShift.none,
        decode = { HolidayShift.of(it) },
        encode = { if (it == HolidayShift.none) null else it.rawValue },
    )
