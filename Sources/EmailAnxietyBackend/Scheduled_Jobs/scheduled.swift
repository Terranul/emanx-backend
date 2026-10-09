import Foundation

// suite of functions use vapors scheduled processes api
// this is represented by an endpoint on the server (becuase of Render free tier), but github actions will only call this

// updates the watch we have on each user for inbox updates
// runs daily, looks for users that are about to expire
func updateWatch() async throws {
    let expiredUsers = try await NotificationModel().getExpiringWatchUsers()
    try await withThrowingTaskGroup { group in
        for user in expiredUsers {
            group.addTask {
                try await updateWatchStatus(user: user)
            }
        }
        try await group.waitForAll()
    }
}

fileprivate func updateWatchStatus(user: User) async throws {
    let authToken: String = try await UserService().getOauthToken(code: user.userCode)
    let gmailService = GmailService(accessCode: authToken)
    try await gmailService.registerUser()
    // user.expiration = getNextDate() TODO add to schema
    try await NotificationModel().updateUser(to: user)
}


func getNextDate() -> Date {
    var cur: Date = Date()
    let oneDay: TimeInterval = 86_400
    cur.addTimeInterval(oneDay)
    return cur
}