import Vapor
import WebPush

struct UserController: RouteCollection {

    let userService = UserService()

    struct RegisterUpload: Decodable {
        let authToken: String
        let refreshToken: String
    }

    struct PubSubResponse: Decodable {
        let message: DataResponse
        struct DataResponse: Decodable {
            let data: String
        }
    }

    struct HistoryResponse: Decodable {
        let emailAddress: String
        let historyId: String
    }

    struct NotifyResponse: Content {
        let senderEmails: [EmailResponse.SenderEmail]
    }

    struct WebPushOptions: Codable, Content, Hashable, Sendable {
        //static let defaultContentType = HTTPMediaType(type: "application", subType: "webpush-options+json")
        var vapid: VAPID.Key.ID
}

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.put(["users", "emails", ":email"], use: register)
        //routes.post("getEmails", user: getEmails)

        // used for Pub/Sub only
        routes.post(["users"], use: notify)

        // used for PWA only
        routes.get("vapidKey", use: getVapidKey)
        routes.put(["subscribe", ":email"], use: subscribe)
    }

    func register(req: Request) async throws -> Response {
        // TODO add email field to the User struct
        let upload: UserController.RegisterUpload = try req.content.decode(RegisterUpload.self)
        let gmailService = GmailService(accessCode: upload.authToken)
        try await gmailService.registerUser()
        let userService = UserService()
        let code = UUID().uuidString
        let gmail = try req.parameters.require("email")
        let user = User(refreshToken: upload.refreshToken, refreshExpiration: nil, token: upload.authToken, userCode: code, gmail: gmail)
        try await userService.uploadUser(user: user)
        return try await ["code" : code].encodeResponse(for: req)
    }

    // history id from sept2: "historyId": "672329"

    func notify(req: Request) async throws -> Response {
        print("hit notfiy")
        let pbsb = try req.content.decode(PubSubResponse.self)
        print("passed pbsb decoding")
        let data = Data(base64Encoded: pbsb.message.data)!
        print("passed data encoding")
        let history = try JSONDecoder().decode(UserController.HistoryResponse.self, from: data)
        print("passed history decoding")
        let subscriber = try await userService.getSubscription(gmail: history.emailAddress)
        let gmailService = GmailService(accessCode: try await userService.getOauthToken(gmail: history.emailAddress))
        print("passed gmail service")
        let newEmails = try await gmailService.getHistoryEmails(historyId: history.historyId)
        let emailResponses = try await self.userService.addEmails(emails: newEmails)
        let notifyResponse = NotifyResponse(senderEmails: emailResponses)
        try await userService.sendNotification(body: try JSONEncoder().encode(notifyResponse), subscription: subscriber)
        print("passed send notficiation")
        return Response(status: .ok)
    }

    func getVapidKey(req: Request) async throws -> WebPushOptions {
        return WebPushOptions(vapid: UserService().getVapidPublicKey())
    }

    func subscribe(req: Request) async throws -> Response {
        print("entered")
        let subscription = try req.content.decode(Subscriber.self)
        print(subscription.vapidKeyID)
        print("finished")
        let gmail = try req.parameters.require("email")
        try await self.userService.uploadSubscription(subscription: subscription, gmail: gmail)
        return Response(status: .ok)
    }

    // func getEmails(req: Request) async throws -> [EmailResponse] {
    //     let emails =  try await userService.getEmails()
    //     let body: [String: [EmailResponse]] = ["emails": emails]
    //     return body.ecode
    // }
}