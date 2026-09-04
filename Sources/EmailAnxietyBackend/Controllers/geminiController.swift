import Vapor

struct GeminiController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.get(["users", ":user", "drafts", ":draft", "artificial"], use: getArtificial)
    }

    func getArtificial(req: Request) async throws -> Response {
        let userCode: String = try req.parameters.require("user")
        let gmailCode = try await UserService().getOauthToken(code: userCode)
        let gmailService = GmailService(accessCode: gmailCode)
        let email = try await gmailService.getDraft(code: gmailCode)
        do {
            let modifiedEmail = try await GeminiService.getDefaultArtificialResponse(email: email)
            return try await modifiedEmail.encodeResponse(for: req)
        } catch(let err) {
            print(err)
            throw Abort(.internalServerError)
        }
    }

    
}
