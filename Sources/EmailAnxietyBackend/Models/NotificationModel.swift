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
        return UserSupabase(usercode: userCode, refresh_expiration: refreshExpiration!, auth_code: token, refresh_code: refreshToken)
    }
}

struct UserSupabase: Codable {
    let usercode: String
    let refresh_expiration: Date
    let auth_code: String
    let refresh_code: String

    func getUser() -> User {
        return User(refreshToken: refresh_code, refreshExpiration: refresh_expiration, token: auth_code, userCode: usercode)
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

    func addSubscription(subscription: Subscriber, gmail: Gmail) {
        subscriptions[gmail] = subscription
    }

    func getSubscription(gmail: Gmail) -> Subscriber? {
        return self.subscriptions[gmail]
    }
}