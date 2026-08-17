import Vapor
import FluentPostgresDriver
import Fluent

/// configures your application
func configure(_ app: Application) async throws {

     guard let databaseURL = Environment.get("DATABASE_URL") else {
        throw Abort(.internalServerError, reason: "DATABASE_URL is not configured")
    }

    try app.databases.use(
        .postgres(url: databaseURL),
        as: .psql
    )
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
