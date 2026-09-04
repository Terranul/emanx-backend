/*
To be converted to a proper database later.
In this state for testing purposes
*/

import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
import WebPush
import Supabase

typealias Gmail = String
typealias UserCode = String


struct User {
    let refreshToken: String
    let refreshExpiration: Date?
    let token: String
    let userCode: UserCode

    func supabaseConvert() -> UserSupabase {
        return UserSupabase(usercode: userCode, refreshexpiration: refreshExpiration!, authcode: token, refreshcode: refreshToken)
    }
}

struct UserSupabase: Codable {
    let usercode: String
    let refreshexpiration: Date
    let authcode: String
    let refreshcode: String

    func getUser() -> User {
        return User(refreshToken: refreshcode, refreshExpiration: refreshexpiration, token: authcode, userCode: usercode)
    }
}

class NotificationModel {

    func getUser(userCode: UserCode) async throws -> User {
        let supaUser: UserSupabase = try await supabase 
                                        .from("app_user")
                                        .select()
                                        .eq("usercode", value: userCode)
                                        .single()
                                        .execute()
                                        .value
        return supaUser.getUser()
    }

    func setUser(user: User) async throws {
        let supaUser: UserSupabase = user.supabaseConvert()
        try await supabase
                .from("app_user")
                .insert(supaUser)
                .execute()      
    }
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