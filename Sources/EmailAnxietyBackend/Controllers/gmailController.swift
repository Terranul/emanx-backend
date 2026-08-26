import Vapor
//     /create /update /edit /notify /send /get /sendCred
// 

struct GmailController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.post("create", use: writeEmail)
        routes.post("update", use: updateEmail)
        routes.post("get", use: getDraft)
    }

    func writeEmail(req: Request) async throws -> Response {
        if (validateRequest(req: req) != nil) {
            throw Abort(.forbidden)
        }
        guard let gmailCode = req.headers.first(name: "gmail") else {
            throw Abort(.badRequest, reason: "Missing google auth code in header")
        }
        let gmailService = GmailService(accessCode: gmailCode)
        let email = try req.content.decode(Email.self)
        // return try await self.createEmail(email: email, gmailService.writeDraft)
        return try await self.createEmail(email: email) { email in
            return try await gmailService.writeDraft(email: email)
        }
    }

    func updateEmail(req: Request) async throws -> Response {
        if (validateRequest(req: req) != nil) {
            throw Abort(.forbidden)
        }
        guard let gmailCode = req.headers.first(name: "gmail") else {
            throw Abort(.badRequest, reason: "Missing google auth code in header")
        }
        let emailInfo = try req.content.decode(EmailRequest.self)
        let id = ""
        let gmailService  = GmailService(accessCode: gmailCode)
        return try await self.createEmail(email: emailInfo.email!) { email in
            return try await gmailService.updateDraft(email: email, id: id)
        }

    }

    func createEmail(email: Email, _ option: (Email) async throws -> String) async throws -> Response{
        do {
            let emailCode = try await option(email)
            let response = Response(status: .accepted, body: .init(string: "{emailCode: \(emailCode)}"))
            response.headers.contentType = .json
            return response
        } catch(let err) {
            print(err)
            throw Abort(.internalServerError)
        }
    }

    func getDraft(req: Request) async throws -> Response {
        if (validateRequest(req: req) != nil) {
            throw Abort(.forbidden)
        }
        guard let gmailCode = req.headers.first(name: "gmail") else {
            throw Abort(.badRequest, reason: "Missing google auth code in header")
        }
        let gmailService  = GmailService(accessCode: gmailCode)
        let gmailId = try req.content.decode(EmailRequest.self).gmailId
        let email = try await gmailService.getDraft(code: gmailId)
        return try await self.createEmail(email: email) { email in
            return try await gmailService.writeDraft(email: email)
        }
    }

    // func getEmail(req: Request) async throws -> Response {
    //     if (validateRequest(req: req) != nil) {
    //         throw Abort(.forbidden)
    //     }
    //     guard let gmailCode = req.headers.first(name: "gmail") else {
    //         throw Abort(.badRequest, reason: "Missing google auth code in header")
    //     }

    // }

    




}