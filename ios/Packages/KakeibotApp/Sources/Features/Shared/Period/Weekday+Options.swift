import Core
import DesignSystem

extension Weekday {
    static var weekStartOptions: [CapsulePicker<Weekday>.Option] {
        [
            .init("日曜", value: .sunday),
            .init("月曜", value: .monday)
        ]
    }
}
