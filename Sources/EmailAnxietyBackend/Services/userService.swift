import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
import WebPush
import Vapor


final class UserService: Sendable {

    enum NotificationError: Error {
        case UndefinedUser
    }

    let pushManager: WebPushManager

    struct TokenResponse: Decodable {
        let access_token: String
        let expires_in: Int
        let token_type: String
    }

    init() {
        guard
            let rawVAPIDConfiguration = Environment.get("VAPID-CONFIG"),
            let vapidConfiguration = try? JSONDecoder().decode(
                VAPID.Configuration.self, from: Data(rawVAPIDConfiguration.utf8))
        else {
            fatalError(
                "VAPID keys are unavailable, please generate one and add it to the environment.")
        }
        self.pushManager = WebPushManager(vapidConfiguration: vapidConfiguration)
    }

    static let TOKEN_EXPIRATION_TIME: Double = 3400 // 3600 is standard, use 3400 to account for processing time

    func uploadUser(user: User) async throws {
        let notificationModel = NotificationModel()
        if user.refreshExpiration == nil {
            var current = Date()
            current.addTimeInterval(UserService.TOKEN_EXPIRATION_TIME)
            let newUser = User(refreshToken: user.refreshToken, refreshExpiration: current, token: user.token, userCode: user.userCode, gmail: user.gmail)
            try await notificationModel.setUser(user: newUser)
        } else {
            try await notificationModel.setUser(user: user)
        }
    }

    func getOauthToken(code: UserCode) async throws -> String {
        let user = try await NotificationModel().getUser(userCode: code) 
        if (Date() > user.refreshExpiration!) {
                return try await fetchAuthToken(refreshToken: user.refreshToken)
            } else {
                return user.token
        }
    }

    private func fetchAuthToken(refreshToken: String) async throws -> String {
        var request = URLRequest(
            url: URL(string: "https://oauth2.googleapis.com/token")!
        )
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        let body = [
            "client_id": "902542881032-oqjda56jk9584ejcba4gmqjn5dul7ogp.apps.googleusercontent.com",
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        return response.access_token
    }

    func uploadSubscription(subscription: Subscriber, gmail: String) async throws {
        try await NotificationModel().setSubscriber(email: gmail, subscriber: subscription)
    }

    func getSubscription(gmail: String) async throws -> Subscriber {
        return try await NotificationModel().getSubscriber(email: gmail)
    }

    func sendNotification(body: Data, gmail: String) async throws {
        let subscription: Subscriber = try await self.getSubscription(gmail: gmail)
        print("in send notification")
        try await self.pushManager.send(
            notification: PushMessage.Notification(
                destination: URL(string: "/")!,  // the "/" should define the origin specified in the manifest
                title: "Test Notification",
                body: String(data: body, encoding: .utf8)
            ),
            to: subscription
        )
    }

    func getVapidPublicKey() -> VAPID.Key.ID {
        return pushManager.nextVAPIDKeyID
    }

    func getEmails(userCode: UserCode) async throws -> [EmailResponse] {
        return try await EmailModel().getEmails(userCode: userCode)
    }

    func createDatabaseDraft(draftId: String, emailId: String, userCode: UserCode) async throws {
        try await EmailModel().addDraft(emailId: emailId, draftId: draftId, userCode: userCode)
    }

    func editDatabaseDraft(newDraftId draftId: String, emailId: String) async throws {
        try await EmailModel().editDraft(emailId: emailId, newDraftId: draftId)
    }

    func addEmail(email: Email) async throws -> String {
        let emailId = UUID().uuidString
        let supabaseEmail = SupabaseEmail(email_id: emailId, subject: email.subject, recipient: email.to, sender: email.from, body: email.body)
        try await EmailModel().addEmail(email: supabaseEmail)
        return emailId
    }

    func addEmails(emails: [Email]) async throws -> [EmailResponse.SenderEmail] {
         return try await withThrowingTaskGroup { body in
            for email in emails {
                body.addTask {
                    let emailId = try await self.addEmail(email: email)
                    return EmailResponse.SenderEmail(emailId: emailId, body: email)
                }
            }
            var result: [EmailResponse.SenderEmail] = []
            while !body.isEmpty {
                result.append(try await body.next()!)
            }
            return result
        }
    }

    
}

