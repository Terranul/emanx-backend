// gmail api is filled with things I don't need
// this will just give me the important fields right when I encode

import Foundation
import Vapor

struct UserMessageLinks: Decodable {

    var links: [String]

    enum CodingKeys: CodingKey {
        case messages
    }

    enum MessagesCodingKey: CodingKey {
        case payload
    }

    enum PayloadCodingKey: CodingKey {
        case body
    }

    enum BodyCodingKey: CodingKey {
        case link
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payload = try container.nestedContainer(keyedBy: MessagesCodingKey.self, forKey: .messages)
        let body = try payload.nestedContainer(keyedBy: PayloadCodingKey.self, forKey: .payload)
        var messages = try body.nestedUnkeyedContainer(forKey: .body)
        self.links = []
        while (!messages.isAtEnd) {
            links.append(try messages.decode(String.self))
        }
    }
}

struct UserMessage: Decodable {
    let mimeType: String?
    let body: Body?
    let parts: [UserMessage]?
    
    struct Body: Decodable {
        let data: String?
    }

    func getEmail() throws -> Email? {
        if (body == nil) {
            for part: UserMessage in parts! {
                if (mimeType == "text/plain") {
                    return try part.getEmail()
                }
            }
        } else {
            if let base44 = Data(base64Encoded: body!.data!) {
                return try Email(body: base44)
            } else {
                return nil
            }
        }
        return nil
    }
}

struct MessageResponse: Decodable {
    let id: String
}

struct Email: Content {
    let from: String
    let to: String
    let subject: String
    let date: Date?
    let body: String

    init(from: String, to: String, subject: String, date: Date?, body: String) {
        self.from = from
        self.to = to
        self.subject = subject
        self.date = date
        self.body = body
    }

    // Data is base-44 encoded utf-8
    init(body: Data) throws {
        if let rawString: String = String(data: body, encoding: .utf8) {
            rawString.firstMatch(of: /From: (.*?)/)
        }
    }

    // return rfc 2822 encoding
    func getRFCEncoding() -> String{
        return """
               From: \(self.from)
               To: \(self.to)
               Subject: \(self.subject)

               \(self.body)
               """    
    }
}

struct GeminiRequest: Encodable {
    let model: String
    let input: String
    let system_instruction: String
}