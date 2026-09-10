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
import Crypto
import Vapor

typealias Gmail = String
typealias UserCode = String

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        self.init(base64Encoded: base64)
    }
}


struct User {
    let refreshToken: String
    var refreshExpiration: Date?
    var token: String
    let userCode: UserCode
    let gmail: String

    func supabaseConvert() -> UserSupabase {
        return UserSupabase(usercode: userCode, refresh_expiration: refreshExpiration!, auth_code: token, refresh_code: refreshToken, gmail: gmail)
    }
}

struct UserSupabase: Codable {
    let usercode: String
    let refresh_expiration: Date
    let auth_code: String
    let refresh_code: String
    let gmail: String

    func getUser() -> User {
        return User(refreshToken: refresh_code, refreshExpiration: refresh_expiration, token: auth_code, userCode: usercode, gmail: gmail)
    }
}

struct SubscriberSupabase: Codable {
    let gmail: String
    let data: String

    func getSubscriber() throws -> Subscriber {
        print("passed get subscriber")
        let jsonData = Data(base64URLEncoded: self.data)!
        print("pased json data")
        return try JSONDecoder().decode(Subscriber.self, from: jsonData)
        print("end get subscriber")
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

    func getUser(gmail: Gmail) async throws -> User {
        let supaUser: UserSupabase = try await supabase 
                                        .from("app_user")
                                        .select()
                                        .eq("gmail", value: gmail)
                                        .single()
                                        .execute()
                                        .value
        return supaUser.getUser()
    }

    func setTokenExpiration(userCode: UserCode, to date: Date) async throws {
        try await supabase
                    .from("app_user")
                    .update(["refresh_expiration": date])
                    .eq("usercode", value: userCode)
                    .execute()        
    }

    func updateUser(to user: User) async throws {
        let supaUser: UserSupabase = user.supabaseConvert()
        try await supabase
                .from("app_user")
                .update(supaUser)
                .execute()   
    }

    func setUser(user: User) async throws {
        let supaUser: UserSupabase = user.supabaseConvert()
        try await supabase
                .from("app_user")
                .insert(supaUser)
                .execute()      
    }

    func getSubscriber(email: Gmail) async throws -> Subscriber {
        let supaSubscriber: SubscriberSupabase = try await supabase
                                                    .from("subscriber")
                                                    .select()
                                                    .eq("gmail", value: email)
                                                    .single()
                                                    .execute()
                                                    .value
        return try supaSubscriber.getSubscriber()
    }

    // subscriber data is the jsonData you recieve from the body of the request to subscribe
    func setSubscriber(email: Gmail, subscriberData: Data) async throws {
        let subscriberText = subscriberData.base64URLEncodedString()
        let supaSubscriber = SubscriberSupabase(gmail: email, data: subscriberText)
        try await supabase
                .from("subscriber")
                .insert(supaSubscriber)
                .execute()
    }
}