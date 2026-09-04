import Vapor
//     /create /update /edit /notify /send /get /sendCred
// 

struct GmailController: RouteCollection {

    struct DraftsResponse: Content {
        let drafts: [EmailResponse]
    }

    let userService = UserService()

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.put(["users", ":user", "drafts"], use: writeEmail)
        routes.patch(["users", ":user", "drafts", ":draft"], use: updateEmail)
        routes.get(["users", ":user", "drafts"], use: getDrafts)
        routes.get(["users", ":user", "drafts", ":draft"], use: getDraft)
    }

    func writeEmail(req: Request) async throws -> Response {
        let userCode: String = try req.parameters.require("user")
        let gmailCode = try await userService.getOauthToken(code: userCode)
        let gmailService = GmailService(accessCode: gmailCode)
        let emailInfo = try req.content.decode(EmailRequest.self)
        return try await self.createEmail(email: emailInfo.email!) { email in
            return try await gmailService.writeDraft(email: email)
        } databaseOperation: { emailCode in
            try await userService.createDatabaseDraft(draftId: emailCode, emailId: emailInfo.gmailId, userCode: try req.parameters.require("user"))
        }
    }

    func updateEmail(req: Request) async throws -> Response {
        let gmailCode = try await extractAuthToken(req: req)
        let emailInfo: EmailRequest = try req.content.decode(EmailRequest.self)
        let id = emailInfo.gmailId
        let gmailService  = GmailService(accessCode: gmailCode)
        return try await self.createEmail(email: emailInfo.email!) { email in
            return try await gmailService.updateDraft(email: email, id: id)
        } databaseOperation: { emailCode in
            try await userService.editDatabaseDraft(newDraftId: emailCode, emailId: emailInfo.gmailId)
        }   
    }

    func createEmail(email: Email, _ option: (Email) async throws -> String, databaseOperation: (String) async throws -> Void) async throws -> Response {
        do {
            let emailCode: String = try await option(email)
            try await databaseOperation(emailCode)
            let response = Response(status: .accepted, body: .init(string: "{emailCode: \(emailCode)}"))
            response.headers.contentType = .json
            return response
        } catch(let err) {
            print(err)
            throw Abort(.internalServerError)
        }
    }

    func getDrafts(req: Request) async throws -> Response {
        print("testngg")
        let userCode = try req.parameters.require("user")
        let drafts = try await userService.getEmails(userCode: userCode)
        print("passed drafts")
        let response = DraftsResponse(drafts: drafts)
        print("passed response")
        return try await response.encodeResponse(for: req)
    }

    func getDraft(req: Request) async throws -> Response {
        print("testing")
        let draftId = try req.parameters.require("draft")
        let authToken = try await extractAuthToken(req: req)
        let gmailService  = GmailService(accessCode: authToken)
        let email = try await gmailService.getDraft(code: draftId)
        return try await email.encodeResponse(for: req)
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