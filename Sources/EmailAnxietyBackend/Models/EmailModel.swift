/*

Email comes in from pub/sub, backend creates an entry under the email entry and assigns a pid 
pid is sent in the notification context
the pid value is supplied for all create/update operations as well as getting drafts

*/

import Supabase
import Foundation
import Vapor

let supabase = SupabaseClient(
    supabaseURL: URL(string: Environment.get("SUPABASE_URL")!)!,
    supabaseKey: Environment.get("SUPABASE_KEY")!
)

struct SupabaseEmail: Codable {
    let email_id: String
    let subject: String
    let recipient: String
    let sender: String
    let body: String

    func getEmail() -> Email {
        return Email(from: sender, to: recipient, subject: subject, date: nil, body: body)
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
    let stage: Int
    let draftId: String
    let email: Email
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



