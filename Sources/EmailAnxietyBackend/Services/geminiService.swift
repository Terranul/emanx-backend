import Foundation
import Vapor

class GeminiService {

    static let geminiKey: String = Environment.get("GEMINI_KEY")!

    static func getRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/interactions")!)
        request.setValue(GeminiService.geminiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        return request
    }

    static func getDefaultArtificialResponse(email: Email) async throws -> Email {
        var request: URLRequest = self.getRequest()
        let textInput = email.body
        let systemInstructions = """
                                         You are to modify the text input in order to make it more formal and friendly.
                                         It is intended to be a response in the form of a message.
                                         The subject of the message is \(email.subject).
                                         The final result must be presented in complete sentences.
                                         You may not modify more than 30% of the message.
                                         The modification limitation may be overriden if it is impossible to accomplish one of the given goals without modifying more than 30% of the text input.
                                         """
        let geminiBody = GeminiRequest(model: "gemini-3.6-flash", input: textInput, system_instruction: systemInstructions)
        request.httpBody = try JSONEncoder().encode(geminiBody)
        var (data, response) = try await URLSession.shared.data(for: request)
        print("passed the request")
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        print("passed the decode")
        let responseText = geminiResponse.steps[0].content[0].text
        return Email(from: email.from, to: email.to, subject: email.subject, date: email.date, body: responseText)
    }
}