/*
To be converted to a proper database later.
In this state for testing purposes
*/

import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
import WebPush

typealias Gmail = String
typealias UserCode = String


struct User {
    let refreshToken: String
    let refreshExpiration: Date?
    let token: String
}

actor UserInfo {
    private static let userInfo: UserInfo = UserInfo()
    var users: [UserCode: User] = [:]
    var subscriptions: [Gmail: Subscriber] = [:]

    static var shared: UserInfo {
        return userInfo
    }

    func addUser(user: User, code: UserCode) {
        print("user added to db")
        users[code] = user
    }

    func getUser(code: UserCode) -> User? {
        return self.users[code]
    }

    func addSubscription(subscription: Subscriber, gmail: Gmail) {
        subscriptions[gmail] = subscription
    }

    func getSubscription(gmail: Gmail) -> Subscriber? {
        return self.subscriptions[gmail]
    }
}