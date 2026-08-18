import Foundation

enum RequestError: Error {
    case requestError
}



final class gmailService: Sendable {

    let accessCode: String

    init(accessCode: String) {
        self.accessCode = accessCode 
    }
 
    private func getURLRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: "") else {
            throw NSError()
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(self.accessCode)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
 
    func getRecentMessageLinks(scope: Int) async throws -> UserMessageLinks {
        var (data, response) = try await URLSession.shared.data(for: try getURLRequest(path: ""))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.requestError
        }
        var messages = try JSONDecoder().decode(UserMessageLinks.self, from: data)
        messages.links.removeLast(messages.links.count - scope)
        return messages
    }

    func getMessage(code: String) async throws -> UserMessage {
        let request = try self.getURLRequest(path: "/gmail/v1/users/me/messages/\(code)?format=full")
        var (data, response) = try await URLSession.shared.data(for: request)
        var message = try JSONDecoder().decode(UserMessage.self, from: data)
        return message
    }

    func getMessages(scope: Int) async throws -> [UserMessage] {
        let links: [String] = await try getRecentMessageLinks(scope: scope).links
        return await withThrowingTaskGroup(of: UserMessage.self) { body in
        var messageResults = Array<UserMessage>()
            for link in links {
                body.addTask {
                    return try await self.getMessage(code: link)
                }
                while !body.isEmpty {
                    do {
                        if let message = try await body.next() {
                            messageResults.append(message)
                        }
                    } catch {
                        body.cancelAll()
                    }
                }
            }
            return messageResults
        }
    }

    func writeDraft(email: Email) async throws {
        guard let body: Data = Data(base64Encoded: email.getRFCEncoding()) else {
            debugPrint("issue with encoding email string")
            return
        }
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/drafts")
        request.httpMethod = "POST"
        request.httpBody = body
        


    }
}