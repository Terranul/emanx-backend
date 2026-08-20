import Vapor

struct geminiController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("t", use: getArtificial)
        
    }

    func getArtificial(req: Request) async throws -> Response {
        if let result = validateRequest(req: req) {
            return result
        }
        do {
            let email: Email = try req.content.decode(Email.self)
            let modifiedEmail = await GeminiService.getDefaultArtificialResponse(email: email)
            return try await modifiedEmail.encodeResponse(for: req)
        } catch {
            throw Abort(.internalServerError)
        }
    }

    
}