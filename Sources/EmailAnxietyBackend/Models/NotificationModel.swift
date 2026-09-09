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
    let endpoint: String
    let public_key: String
    let auth_key: String
    let vapid_key: String
    let gmail: String

    // https://stackoverflow.com/questions/63076554/problem-using-p256-signing-publickey-on-ios
    // assume the publicKey value is a base64 encoded string of a pem file
    // the reason this failed is becuase we escape some characters
    func getSubscriber() throws -> Subscriber {
        let urlEndpoint = URL(string: self.endpoint)!
        print("after base64url encoded string: " + public_key)
        print(Array(Data(base64URLEncoded: self.public_key)!))
        print("above is bytes")
        let publicKey = try P256.KeyAgreement.PublicKey(x963Representation: Data(base64URLEncoded: self.public_key)!)
        print("passed problem area")
        let authKey = Data(base64URLEncoded: self.auth_key)!
        let keyMaterial = UserAgentKeyMaterial(publicKey: publicKey, authenticationSecret: authKey)
        let vapidKey = try VAPID.Key(base64URLEncoded: self.vapid_key).id
        return Subscriber(endpoint: urlEndpoint, userAgentKeyMaterial: keyMaterial, vapidKeyID: vapidKey)
    }
}

extension Subscriber {

    func getSupabaseSubscriber(gmail: String) -> SubscriberSupabase {
        let endpoint = self.endpoint.absoluteString
        let publicKey: String = self.userAgentKeyMaterial.publicKey.x963Representation.base64URLEncodedString()
        print("before bytes")
        print(Array(self.userAgentKeyMaterial.publicKey.x963Representation))
        print("before base64urlencoded string" + self.userAgentKeyMaterial.publicKey.x963Representation.base64URLEncodedString())
        let authKey = self.userAgentKeyMaterial.authenticationSecret.base64URLEncodedString()
        let vapidKey = self.vapidKeyID.description
        return SubscriberSupabase(endpoint: endpoint, public_key: publicKey, auth_key: authKey, vapid_key: vapidKey, gmail: gmail)
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

    func setSubscriber(email: Gmail, subscriber: Subscriber) async throws {
        let supaSubscriber = subscriber.getSupabaseSubscriber(gmail: email)
        try await supabase
                .from("subscriber")
                .insert(supaSubscriber)
                .execute()
    }
}