import Vapor

struct GeminiController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("edit", use: getArtificial)
    }

    func getArtificial(req: Request) async throws -> Response {
        if let result = validateRequest(req: req) {
            return result
        }
        do {
            let email: Email = try req.content.decode(Email.self) 
            let modifiedEmail = try await GeminiService.getDefaultArtificialResponse(email: email)
            return try await modifiedEmail.encodeResponse(for: req)
        } catch(let err) {
            print(err)
            throw Abort(.internalServerError)
        }
    }

    
}
