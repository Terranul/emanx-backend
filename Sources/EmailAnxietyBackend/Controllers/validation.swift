import Vapor

func validateRequest(req: Request) -> (Response)? {
    guard let apiKey = req.parameters.get("api_key") else {
        let response = Response(status: HTTPResponseStatus.badRequest)
        response.body = Response.Body(string: "api_key missing")
        return response
    }
    let internalApiKey = Environment.get("INTERNAL_API_KEY")!
    if (apiKey != internalApiKey) {
        return Response(status: .forbidden)
    }
    return nil
}
