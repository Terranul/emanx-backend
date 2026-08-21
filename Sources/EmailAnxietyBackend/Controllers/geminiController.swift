import Vapor

struct geminiController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("edit", use: getArtificial)
    }

    func getArtificial(req: Request) async throws -> Response {
        if let result = validateRequest(req: req) {
            return result
        }
        do {
            print("entered")
            let email: Email = try req.content.decode(Email.self)
            print("passed the amil decode")
            
            let modifiedEmail = try await GeminiService.getDefaultArtificialResponse(email: email)
            print("passedv the mofiied email")
            return try await modifiedEmail.encodeResponse(for: req)
            print("passed encoding repsonse")
        } catch(let err) {
            print(err)
            throw Abort(.internalServerError)
        }
    }

    
}