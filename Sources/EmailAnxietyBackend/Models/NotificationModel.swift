/*
To be converted to a proper database later.
In this state for testing purposes
*/

import Foundation

struct User {
    let refreshToken: String
    let refreshExpiration: Date?
    let token: String
}

actor UserInfo {
    private static let userInfo: UserInfo = UserInfo()
    var users: [String: User] = [:]

    static var shared: UserInfo {
        return userInfo
    }

    func addUser(user: User, gmail: String) {
        print("user added to db")
        users[gmail] = user
    }

    func getUser(gmail: String) -> User? {
        return self.users[gmail]
    }
}