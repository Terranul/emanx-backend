import Vapor

struct UserController: RouteCollection {

    struct RegisterUpload: Decodable {
        let authToken: String
        let refreshToken: String
        let notificationId: String
        let gmail: String
    }

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("register", use: register)
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

    // func nofify(req: Request) async throws -> Response {
    //     if (validateRequest(req: req) != nil) {
    //         throw Abort(.forbidden)
    //     }
    //     let data: HistoryResponse = try req.content.decode(HistoryResponse.self)
    //     let newEmails = data.history.map { cur in
    //         cur.added
    //     }


    // }

    
}