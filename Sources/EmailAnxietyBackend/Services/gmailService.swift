import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif

enum RequestError: Error {
    case requestError
    case encodingError
}

final class GmailService: Sendable {

    let accessCode: String

    init(accessCode: String) {
        self.accessCode = accessCode 
    }
 
    private func getURLRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: path) else {
            throw RequestError.requestError
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(self.accessCode)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
 
    func getRecentMessageLinks(scope: Int) async throws -> UserMessageLinks {
        let (data, response) = try await URLSession.shared.data(for: try getURLRequest(path: ""))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.requestError
        }
        var messages = try JSONDecoder().decode(UserMessageLinks.self, from: data)
        messages.links.removeLast(messages.links.count - scope)
        return messages
    }

    func getMessage(code: String) async throws -> UserMessage {
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(code)?format=full")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8)!)
        let message = try JSONDecoder().decode(UserMessageResponse.self, from: data)
        return message.payload
    }

    func getMessages(scope: Int) async throws -> [UserMessage] {
        let links = try await getRecentMessageLinks(scope: scope).links
        return try await getMessages(links: links)
    }

    func getMessages(links: [String]) async throws -> [UserMessage] {
        return try await withThrowingTaskGroup(of: UserMessage.self) { group in
            for link in links {
                group.addTask {
                    try await self.getMessage(code: link)
                }
            }
            var messageResults = [UserMessage]()
            while let message = try await group.next() {
                messageResults.append(message)
            }
            return messageResults
        }
    }

    func writeDraft(email: Email) async throws -> String{
        let stringBase64 = email.getRFCEncoding().data(using: .utf8)!.base64EncodedString()
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/drafts")
        request.httpMethod = "POST"
        let body: [String : [String : String]] = ["message": ["raw": stringBase64]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let messageResponse: MessageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        return messageResponse.id
    }

    // important to note that the resulting id returned will not be the same as the one given
    func updateDraft(email: Email, id: String) async throws -> String {
        let stringBase64 = email.getRFCEncoding().data(using: .utf8)!.base64EncodedString()
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/drafts/\(id)")
        request.httpMethod = "PUT"
        let body: [String : [String : String]] = ["message": ["raw": stringBase64]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        return messageResponse.id
    }

    func getDraft(code: String) async throws -> Email {
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/drafts/\(code)")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        let messageResponse: Draft = try JSONDecoder().decode(Draft.self, from: data)
        if let email = try messageResponse.message.payload.getEmail() {
            return email
        }
        throw RequestError.encodingError
    }

    // ensure you have uploaded the user information to the db prior to calling this
    func registerUser(gmail: String) async throws {
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/watch")
        request.httpMethod = "POST"
        let body = """
                               {
                                    "topicName": "projects/gmanx-505500/topics/notifyGmanx",
                                    "labelIds": ["INBOX"],
                                    "labelFilterBehavior": "include"
                               }
                               """
        request.httpBody = body.data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: request)
        print("result:" + String(data: data, encoding: .utf8)!)
    }

    func getHistoryEmails(historyId: String) async throws -> [Email] {
        var request = try self.getURLRequest(path: "https://gmail.googleapis.com/gmail/v1/users/me/history?startHistoryId=\(historyId)")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print("pre decoding")
        print(String(data: data, encoding: .utf8)!)
        let history = try JSONDecoder().decode(HistoryResponse.self, from: data)
        print("post decoding")
        let messagesAddedHistory = history.history.first { cur in
            return  cur.messagesAdded != nil
        }
        guard let messagesAdded = messagesAddedHistory?.messagesAdded else {
            throw RequestError.requestError
        }
        let links: [String] = messagesAdded.map { addedMessage in
            return addedMessage.message.id
        }
        print("made it past finding all id's")
        let result: [UserMessage] = try await getMessages(links: links)
        return try result.map { userMessage in
            return try userMessage.getEmail()!
        }
    }
}