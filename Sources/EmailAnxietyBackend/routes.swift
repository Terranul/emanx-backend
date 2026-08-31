import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    let v1 = app.grouped("v1")
    try v1.register(collection: GeminiController())
    try v1.register(collection: GmailController())
    try v1.register(collection: UserController())
}

