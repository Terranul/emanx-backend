import Foundation

enum RequestError: Error {
    case requestError
}

class gmailService {

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
 
    func getRecentMessages(scope: Int) async throws {
        var (data, response) = try await URLSession.shared.data(for: try getURLRequest(path: ""))
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        
    }
}