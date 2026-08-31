import Vapor

struct UserController: RouteCollection {

    struct RegisterUpload: Decodable {
        let authToken: String
        let refreshToken: String
        let gmail: String
    }

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("notify", use: notify)
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
        // if (validateRequest(req: req) != nil) {
        //     throw Abort(.forbidden)
        // }
        // let data: HistoryResponse = try req.content.decode(HistoryResponse.self)
        // let newEmails = data.history.map { cur in
        //     cur.added
        // }


    }

    
}