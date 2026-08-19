import Foundation
import Vapor

class GeminiService {

    static let geminiKey: String = Environment.get("GEMINI_KEY")!

    func getRequest() -> URLRequest {
        var request = URLRequest(url: URL(filePath: "https://generativelanguage.googleapis.com/v1/interactions"))
        request.setValue(GeminiService.geminiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func getDefaultArtificialResponse(email: Email) {
        var request: URLRequest = self.getRequest()
        let textInput = email.subject + ": " + email.body
        let systemInstructions = """
                                         You are to modify the text input in order to make it more formal and friendly.
                                         It is intended to be a response in the form of a message.
                                         The final result must be presented in complete sentences.
                                         You may not modify more than 30% of the message.
                                         The modification limitation may be overriden if it is impossible to accomplish one of the given goals without modifying more than 30% of the text input.
                                         """
        let geminiBody = GeminiRequest(model: "gemini-2.5-flash-lite", input: textInput, system_instruction: systemInstructions)
    }
}