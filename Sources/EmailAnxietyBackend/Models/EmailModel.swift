/*

Email comes in from pub/sub, backend creates an entry under the email entry and assigns a pid 
pid is sent in the notification context
the pid value is supplied for all create/update operations as well as getting drafts

*/
import Foundation
#if canImport(FoundationNetworking) // for render since it runs on linux. This is stupid honestly
import FoundationNetworking
#endif
import Supabase
import Vapor

// linux needs a auth storage when creating the client, but we don't use this at all
final class UselessAuthStorage: AuthLocalStorage {
    func store(key: String, value: Data) throws {
        return
    }
    func retrieve(key: String) throws -> Data? {
        return nil
    }
    func remove(key: String) throws {
        return
    }
}

let supabase = SupabaseClient(
    supabaseURL: URL(string: Environment.get("SUPABASE_URL")!)!,
    supabaseKey: Environment.get("SUPABASE_KEY")!,
    options: .init(
        auth: .init(
            storage: UselessAuthStorage()
        ),
        global: .init(
            session: URLSession.shared
        )
    )
)

struct SupabaseEmail: Codable {
    let email_id: String
    let subject: String
    let recipient: String
    let sender: String
    let body: String

    func getEmail() -> EmailResponse.SenderEmail {
        let email = Email(from: sender, to: recipient, subject: subject, date: nil, body: body)
        return EmailResponse.SenderEmail(emailId: self.email_id, body: email)
    }
}

struct SupabaseEmailResponse: Codable {
    let stage: Int
    let draft_id: String
    let email: SupabaseEmail

    func getEmailResponse() -> EmailResponse {
        return EmailResponse(stage: self.stage, draftId: self.draft_id, email: self.email.getEmail())
    }

}

struct EmailResponse: Codable {

    struct SenderEmail: Codable {
        let emailId: String
        let body: Email
    }

    let stage: Int
    let draftId: String
    let email: SenderEmail
}

struct SupabaseEmailResponseRequest: Codable {
    let stage: Int
    let draft_id: String
    let email_id: String
    let usercode: String
}

class EmailModel {

    func getEmails(userCode: UserCode) async throws-> [EmailResponse] {
        let supabaseResponses: [SupabaseEmailResponse] = try await supabase   
                                                            .from("email_response")
                                                            .select("""
                                                                    stage,
                                                                    draft_id,
                                                                    email (
                                                                        email_id,
                                                                        subject,
                                                                        recipient,
                                                                        sender,
                                                                        body
                                                                    )
                                                                    """)
                                                            .eq("usercode", value: userCode)
                                                            .execute()
                                                            .value
        return supabaseResponses.map { cur in
            return cur.getEmailResponse()
        }
    }

    func addEmail(email: SupabaseEmail) async throws {
        try await supabase
                    .from("EMAIL")
                    .insert(email)
                    .execute()
    }

    func addDraft(emailId: String, draftId: String, userCode: UserCode) async throws {
        let supabaseResponse = SupabaseEmailResponseRequest(stage: 1, draft_id: draftId, email_id: emailId, usercode: userCode)
        try await supabase
                    .from("email_response")
                    .insert(supabaseResponse)
                    .execute()
    }

    func editDraft(emailId: String, newDraftId: String) async throws {
        try await supabase
                    .from("email_response")
                    .update(["draft_id": newDraftId])
                    .eq("email_id", value: emailId)
                    .execute()
    }

}



