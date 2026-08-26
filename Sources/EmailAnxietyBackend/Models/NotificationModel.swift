/*
To be converted to a proper database later.
In this state for testing purposes
*/

import Foundation

actor UserInfo {
    private static let userInfo: UserInfo = UserInfo()
    private var users: [String : String] = Dictionary<String, String>()

    static var shared: UserInfo {
        return userInfo
    }

    func addUser(gmail: String, notificationId: String) {
        users[gmail] = notificationId
    }
}