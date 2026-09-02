import Vapor
import WebPush

struct UserController: RouteCollection {

    let userService = UserService()

    struct RegisterUpload: Decodable {
        let authToken: String
        let refreshToken: String
        let gmail: String
    }

    struct PubSubResponse: Decodable {
        let data: String
    }

    struct HistoryResponse: Decodable {
        let emailAddress: String
        let historyId: String
    }

    struct WebPushOptions: Codable, Content, Hashable, Sendable {
        //static let defaultContentType = HTTPMediaType(type: "application", subType: "webpush-options+json")
        var vapid: VAPID.Key.ID
}

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("register", use: register)

        // used for Pub/Sub only
        routes.post("notify", use: notify)

        // used for PWA only
        routes.get("vapidKey", use: getVapidKey)
        routes.post("subscribe", use: subscribe)
    }

    func register(req: Request) async throws -> Response {
        if (validateRequest(req: req) != nil) {
            throw Abort(.forbidden)
        }
        let upload: UserController.RegisterUpload = try req.content.decode(RegisterUpload.self)
        let gmailService = GmailService(accessCode: upload.authToken)
        try await gmailService.registerUser(gmail: upload.gmail)
        let userService = UserService()
        let user = User(refreshToken: upload.refreshToken, refreshExpiration: nil, token: upload.authToken)
        await userService.uploadUser(user: user, gmail: upload.gmail)
        return Response(status: .accepted)
    }

    func notify(req: Request) async throws -> Response {
        print("hit notfiy")
        return Response(status: .ok)
        if (validateRequest(req: req) != nil) {
            throw Abort(.forbidden)
        }
        let pbsb = try req.content.decode(PubSubResponse.self)
        let data = Data(base64Encoded: pbsb.data)!
        let history = try JSONDecoder().decode(UserController.HistoryResponse.self, from: data)
        let gmailService = GmailService(accessCode: try await UserService().getOauthToken(gmail: history.emailAddress))
        let newEmails = try await gmailService.getHistoryEmails(historyId: history.historyId)
    }

    func getVapidKey(req: Request) async throws -> WebPushOptions {
        return WebPushOptions(vapid: UserService().getVapidPublicKey())
    }

    func subscribe(req: Request) async throws -> Response {
        let subscription = try req.content.decode(Subscriber.self, as: .jsonAPI)
        let gmailCode = try await extractAuthToken(req: req)
        await self.userService.uploadSubscription(subscription: subscription, gmail: gmailCode)
        return Response(status: .ok)
    }
}