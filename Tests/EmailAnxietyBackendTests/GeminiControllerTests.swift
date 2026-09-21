@testable import EmailAnxietyBackend
import VaporTesting
import Testing
import NIOFoundationEssentialsCompat

@Suite("Gemini Tests")
struct GeminiTests {
    
    func mockPubSubRequest(historyId: Int) throws  -> UserController.PubSubResponse{
        let historyResponse = UserController.HistoryResponse(emailAddress: "bfaraone920@gmail.com", historyId: historyId)
        let encodedData = try JSONEncoder().encode(historyResponse)
        let dataResponse = UserController.PubSubResponse.DataResponse(data: encodedData.base64EncodedString())
        let pubSubResponse = UserController.PubSubResponse(message: dataResponse)
        return pubSubResponse
    }

    // There is stll some manual input required. You must get a new email in the inbox before running each time, unless you keep a single one
    @Test("test nofity")
    func testNotify() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.POST, "v1/users", beforeRequest: { req in
                let pubSubResponse = try mockPubSubRequest(historyId: 701512) // update this  701264
                try req.content.encode(pubSubResponse)
            },
            afterResponse: { res async in
                do {
                    let reqBody = try JSONDecoder().decode(Dictionary<String, String>.self, from: res.body)
                    print(reqBody.debugDescription)
                } catch {
                    print("")
                }
            })
        }
    }
}