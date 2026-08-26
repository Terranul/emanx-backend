// gmail api is filled with things I don't need
// this will just give me the important fields right when I encode

enum GmailDecodingError: Error {
    case NoData(String)
}

import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
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

struct Draft: Decodable {
    let message: UserMessageResponse
}

struct UserMessageResponse: Decodable {
    let payload: UserMessage
}

struct UserMessage: Decodable {
    let mimeType: String?
    let body: Body
    let parts: [UserMessage]?
    let headers: [Header]
    
    struct Body: Decodable {
        let size: Int
        let data: String?
    }

    struct Header: Decodable {
        let name: String
        let value: String
    }

    // refactor this later please
    func getEmail() throws -> Email? {
        var email = Email()
        for header in headers {
            switch (header.name) {
                case "From":
                    email.from = header.value
                case "To":
                    email.to = header.value
                case "Subject":
                    email.subject = header.value
                default:
                    continue   
            }
        }      
        if (mimeType == "text/plain" && body.size != 0) {
            if let rawString = getRawString(body.data!) {
                email.body = rawString
                return email
            }
        } 
        if let parts {
            for part in parts {
                if (part.mimeType == "text/plain") {
                    guard part.body.size != 0 else {
                        // text/plain part entries can never have subcontent, so we can assume this message carries no body data
                        throw GmailDecodingError.NoData("Body size is 0. Email is malformed")
                    }
                    if let rawString = getRawString(part.body.data!) {
                        email.body = rawString
                        return email
                    }
                }
            }
        }
        return nil
    }

    private func getRawString(_ value: String) -> String? {
        if let base44 = Data(base64Encoded: value) {
            return String(data: base44, encoding: .utf8)
        }
        return nil
    }
}

struct MessageResponse: Decodable {
    let id: String
}

struct Email: Content {
    var from: String
    var to: String
    var subject: String
    let date: Date?
    var body: String

    init(from: String, to: String, subject: String, date: Date?, body: String) {
        self.from = from
        self.to = to
        self.subject = subject
        self.date = date
        self.body = body
    }

    init() {
        self.from = ""
        self.to = ""
        self.subject = ""
        self.date = nil
        self.body = ""
    }

    // Data is base-44 encoded utf-8
    init(body: Data) throws {
        throw RequestError.encodingError
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

struct GeminiResponse: Decodable {

    struct GeminiSteps: Decodable {

        struct GeminiContent: Decodable {
            let type: String
            let text: String
        }

        // annoyingly for us, the gemini api may contain a step value that does not contain any Content
        let type: String
        let content: [GeminiContent]?
    }
    let status: String?
    let steps: [GeminiSteps]
}

struct EmailRequest: Decodable {
    let gmailId: String
    let email: Email?
}