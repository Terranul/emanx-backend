class UserService {

    func addNotificationProxy(gmail: String, notificationId: String) async {
       await UserInfo.shared.addUser(gmail: gmail, notificationId: notificationId)
    }
}