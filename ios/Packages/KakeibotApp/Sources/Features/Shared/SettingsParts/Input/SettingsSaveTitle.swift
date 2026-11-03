enum SettingsSaveTitle {
    static func text(
        problem: String?,
        isEditing: Bool
    ) -> String {
        if let problem {
            return problem
        }

        return isEditing ? "変更を保存" : "追加する"
    }
}
