import Vapor

func routes(_ app: Application) throws {

    app.middleware.use(
        FileMiddleware(publicDirectory: app.directory.publicDirectory, defaultFile: "index.html")
    )

    let v1 = app.grouped("v1")
    try v1.register(collection: GeminiController())
    try v1.register(collection: GmailController())
    try v1.register(collection: UserController())
}

