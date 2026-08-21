import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    let v1 = app.grouped("v1", ":api_key")
    try v1.register(collection: geminiController())
}

