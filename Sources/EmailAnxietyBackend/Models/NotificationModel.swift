/*
To be converted to a proper database later.
In this state for testing purposes
*/

import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
import WebPush


struct User {
    let refreshToken: String
    let refreshExpiration: Date?
    let token: String
}

actor UserInfo {
    private static let userInfo: UserInfo = UserInfo()
    var users: [String: User] = [:]
    var subscriptions: [String: Subscriber] = [:]

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

    func addSubscription(subscription: Subscriber, gmail: String) {
        subscriptions[gmail] = subscription
    }

    func getSubscription(gmail: String) -> Subscriber? {
        return self.subscriptions[gmail]
    }
}