import Foundation

class UserService {

    struct TokenResponse: Decodable {
        let access_token: String
        let expires_in: Int
        let token_type: String
    }

    static let TOKEN_EXPIRATION_TIME: Double = 3400 // 3600 is standard, use 3400 to account for processing time

    func uploadUser(user: User, gmail: String) async {
        if user.refreshExpiration == nil {
            var current = Date()
            current.addTimeInterval(UserService.TOKEN_EXPIRATION_TIME)
            let newUser = User(refreshToken: user.refreshToken, refreshExpiration: current, token: user.token)
            await UserInfo.shared.addUser(user: newUser, gmail: gmail)
        } else {
            await UserInfo.shared.addUser(user: user, gmail: gmail)
        }
    }

    func isRegistered(gmail: String) async -> Bool {
        return await UserInfo.shared.users.keys.contains(gmail)
    }

    func getOauthToken(gmail: String) async throws -> String {
        if let user = await UserInfo.shared.getUser(gmail: gmail) {
            if (Date() > user.refreshExpiration!) {
                return try await fetchAuthToken(refreshToken: user.refreshToken)
            } else {
                return user.token
            }
        } else {
            // throw here
            return ""
        }
    }

    private func fetchAuthToken(refreshToken: String) async throws -> String {
        var request = URLRequest(
            url: URL(string: "https://oauth2.googleapis.com/token")!
        )
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        let body = [
            "client_id": "902542881032-oqjda56jk9584ejcba4gmqjn5dul7ogp.apps.googleusercontent.com",
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        return response.access_token
    }





}