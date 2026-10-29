import Core

public extension RecurringEditModel {
    var isNotificationDenied: Bool {
        remindDaysBefore != nil && authorization == .denied
    }

    func refreshAuthorization(_ permission: NotificationPermission) async {
        authorization = await permission.authorization()
    }
}
