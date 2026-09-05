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

typealias Gmail = String
typealias UserCode = String


struct User {
    let refreshToken: String
    let refreshExpiration: Date?
    let token: String
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

    func getSubscriber() throws -> Subscriber {
        let urlEndpoint = URL(string: self.endpoint)!
        let publicKey = try P256.KeyAgreement.PublicKey(pemRepresentation: self.public_key)
        let authKey = Data(base64Encoded: self.auth_key)!
        let keyMaterial = UserAgentKeyMaterial(publicKey: publicKey, authenticationSecret: authKey)
        let vapidKey = try VAPID.Key(base64URLEncoded: self.vapid_key).id
        return Subscriber(endpoint: urlEndpoint, userAgentKeyMaterial: keyMaterial, vapidKeyID: vapidKey)
    }
}

extension Subscriber {

    func getSupabaseSubscriber(gmail: String) -> SubscriberSupabase {
        let endpoint = self.endpoint.absoluteString
        let publicKey = self.userAgentKeyMaterial.publicKey.pemRepresentation
        let authKey = self.userAgentKeyMaterial.authenticationSecret.base64EncodedString()
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