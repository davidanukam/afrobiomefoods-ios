import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

struct SupabaseConfig {
    let url: URL
    let key: String

    static var current: SupabaseConfig? {
        let rawURL = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawKey = (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawURL.isEmpty, !rawKey.isEmpty, let url = URL(string: rawURL) else { return nil }
        return SupabaseConfig(url: url, key: rawKey)
    }
}

struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var userId: String
    var email: String?
    var fullName: String?
    var isAdmin: Bool

    var displayName: String {
        if let fullName, !fullName.isEmpty { return fullName }
        if let email, let name = email.split(separator: "@").first, !name.isEmpty {
            return String(name)
        }
        return "Member"
    }

    init(json: [String: Any]) throws {
        guard let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw SupabaseError.failure("Check your email to confirm the account, then sign in.")
        }
        let user = json["user"] as? [String: Any] ?? [:]
        let metadata = user["user_metadata"] as? [String: Any] ?? [:]
        let appMetadata = user["app_metadata"] as? [String: Any] ?? [:]
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = user["id"] as? String ?? ""
        self.email = user["email"] as? String
        self.fullName = metadata["full_name"] as? String
        if let flag = appMetadata["admin"] as? Bool {
            isAdmin = flag
        } else if let flag = appMetadata["admin"] as? NSNumber {
            isAdmin = flag.boolValue
        } else {
            isAdmin = (appMetadata["admin"] as? String)?.lowercased() == "true"
        }
    }
}

struct RemoteRecipe: Identifiable {
    let id: String
    let sourceId: String?
    let doc: [String: Any]
}

enum SupabaseError: LocalizedError {
    case failure(String)

    var errorDescription: String? {
        switch self {
        case .failure(let text):
            return text
        }
    }
}

@MainActor
final class SupabaseClient: NSObject, ASWebAuthenticationPresentationContextProviding {
    let config: SupabaseConfig
    var session: AuthSession?
    private var webSession: ASWebAuthenticationSession?

    init(config: SupabaseConfig, session: AuthSession?) {
        self.config = config
        self.session = session
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let json = try await post(
            path: "auth/v1/token",
            query: "grant_type=password",
            body: ["email": email, "password": password],
            bearer: nil,
            retry: false
        )
        let next = try AuthSession(json: object(json))
        session = next
        return next
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        let json = try await post(
            path: "auth/v1/signup",
            body: ["email": email, "password": password],
            bearer: nil,
            retry: false
        )
        let next = try AuthSession(json: object(json))
        session = next
        return next
    }

    func refreshClaims() async throws -> AuthSession {
        try await refreshSession()
        let json = try await send(method: "GET", path: "auth/v1/user", bearer: session?.accessToken, retry: true)
        guard var current = session else { throw SupabaseError.failure("Not signed in") }
        let user = object(json)
        let appMetadata = user["app_metadata"] as? [String: Any] ?? [:]
        if let flag = appMetadata["admin"] as? Bool {
            current.isAdmin = flag
        } else if let flag = appMetadata["admin"] as? NSNumber {
            current.isAdmin = flag.boolValue
        }
        current.email = user["email"] as? String ?? current.email
        let metadata = user["user_metadata"] as? [String: Any] ?? [:]
        current.fullName = metadata["full_name"] as? String ?? current.fullName
        if let id = user["id"] as? String, !id.isEmpty { current.userId = id }
        session = current
        return current
    }

    func signOut() async {
        _ = try? await send(method: "POST", path: "auth/v1/logout", bearer: session?.accessToken, retry: false)
        session = nil
    }

    func signInWithGoogle() async throws -> AuthSession? {
        let verifier = Self.randomVerifier()
        let challenge = Self.challenge(for: verifier)
        let authorize = config.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/auth/v1/authorize"
        var components = URLComponents(string: authorize)
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: "igbo-food-heritage://auth-callback"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "s256"),
            URLQueryItem(name: "apikey", value: config.key),
        ]
        guard let url = components?.url else { throw SupabaseError.failure("Could not start Google sign-in.") }

        let code: String? = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "igbo-food-heritage") { callback, error in
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    continuation.resume(returning: nil)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: SupabaseError.failure("Google sign-in did not return a code."))
                    return
                }
                let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
                if let description = items.first(where: { $0.name == "error_description" })?.value {
                    continuation.resume(throwing: SupabaseError.failure(description.removingPercentEncoding ?? description))
                    return
                }
                guard let code = items.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: SupabaseError.failure("Google sign-in did not return a code."))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webSession = session
            session.start()
        }
        guard let code else { return nil }
        let json = try await post(
            path: "auth/v1/token",
            query: "grant_type=pkce",
            body: ["auth_code": code, "code_verifier": verifier],
            bearer: nil,
            retry: false
        )
        let next = try AuthSession(json: object(json))
        session = next
        return next
    }

    func fetchCommunity() async throws -> [CommunityPost] {
        let json = try await send(
            method: "GET",
            path: "rest/v1/community_posts",
            query: "select=*&order=created_at.desc",
            bearer: bearer,
            retry: true
        )
        guard let rows = json as? [[String: Any]], !rows.isEmpty else { return [] }
        return rows.compactMap { Self.mapPost($0) }
    }

    func insertPost(title: String, content: String, language: String, kind: String, audience: String) async throws {
        guard let session else { throw SupabaseError.failure("Sign in required") }
        let body: [String: Any] = [
            "title": title,
            "content": content,
            "author_uid": session.userId,
            "author_name": session.displayName,
            "language": language,
            "kind": kind,
            "audience": audience,
        ]
        _ = try await send(
            method: "POST",
            path: "rest/v1/community_posts",
            body: body,
            bearer: session.accessToken,
            prefer: "return=representation",
            retry: true
        )
    }

    func fetchServices() async throws -> [ServiceItem] {
        let json = try await send(
            method: "GET",
            path: "rest/v1/services",
            query: "select=id,doc",
            bearer: bearer,
            retry: true
        )
        guard let rows = json as? [[String: Any]], !rows.isEmpty else { return [] }
        let mapped = rows.compactMap { Self.mapService($0) }
        return mapped.filter { !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func fetchRecipes() async throws -> [RemoteRecipe] {
        let json = try await send(
            method: "GET",
            path: "rest/v1/recipes",
            query: "select=id,source_id,doc&order=source_id.asc",
            bearer: bearer,
            retry: true
        )
        guard let rows = json as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let id = row["id"] as? String else { return nil }
            return RemoteRecipe(
                id: id,
                sourceId: row["source_id"] as? String,
                doc: row["doc"] as? [String: Any] ?? [:]
            )
        }
    }

    func saveRecipe(existingId: String?, sourceId: String, doc: [String: Any]) async throws {
        let body: [String: Any] = ["source_id": sourceId, "doc": doc]
        if let existingId {
            _ = try await send(
                method: "PATCH",
                path: "rest/v1/recipes",
                query: "id=eq.\(existingId)",
                body: body,
                bearer: bearer,
                prefer: "return=representation",
                retry: true
            )
        } else {
            _ = try await send(
                method: "POST",
                path: "rest/v1/recipes",
                body: body,
                bearer: bearer,
                prefer: "return=representation",
                retry: true
            )
        }
    }

    func deleteRecipe(id: String) async throws {
        _ = try await send(
            method: "DELETE",
            path: "rest/v1/recipes",
            query: "id=eq.\(id)",
            bearer: bearer,
            retry: true
        )
    }

    private var bearer: String { session?.accessToken ?? config.key }

    @discardableResult
    private func refreshSession() async throws -> AuthSession {
        guard let refresh = session?.refreshToken else { throw SupabaseError.failure("Not signed in") }
        let json = try await post(
            path: "auth/v1/token",
            query: "grant_type=refresh_token",
            body: ["refresh_token": refresh],
            bearer: nil,
            retry: false
        )
        let next = try AuthSession(json: object(json))
        session = next
        return next
    }

    private func post(path: String, query: String? = nil, body: Any, bearer: String?, retry: Bool) async throws -> Any {
        try await send(method: "POST", path: path, query: query, body: body, bearer: bearer, retry: retry)
    }

    private func send(
        method: String,
        path: String,
        query: String? = nil,
        body: Any? = nil,
        bearer: String?,
        prefer: String? = nil,
        retry: Bool
    ) async throws -> Any {
        var request = URLRequest(url: makeURL(path: path, query: query))
        request.httpMethod = method
        request.setValue(config.key, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearer { request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        if let prefer { request.setValue(prefer, forHTTPHeaderField: "Prefer") }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401, retry, session?.refreshToken != nil {
            _ = try await refreshSession()
            return try await send(
                method: method,
                path: path,
                query: query,
                body: body,
                bearer: self.session?.accessToken,
                prefer: prefer,
                retry: false
            )
        }
        if status >= 400 {
            throw SupabaseError.failure(Self.message(from: data, status: status))
        }
        if data.isEmpty { return [:] }
        return try JSONSerialization.jsonObject(with: data)
    }

    private func makeURL(path: String, query: String?) -> URL {
        let base = config.url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let joined = "\(base)/\(path)"
        guard let query, !query.isEmpty else { return URL(string: joined)! }
        return URL(string: "\(joined)?\(query)")!
    }

    private func object(_ json: Any) -> [String: Any] {
        json as? [String: Any] ?? [:]
    }

    nonisolated private static func message(from data: Data, status: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let message = (object["error_description"] as? String)
                ?? (object["msg"] as? String)
                ?? (object["message"] as? String)
                ?? (object["error"] as? String)
            if let message, !message.isEmpty { return message }
        }
        return "Request failed (\(status))"
    }

    nonisolated private static func mapPost(_ row: [String: Any]) -> CommunityPost? {
        guard let id = row["id"] as? String else { return nil }
        let content = string(row["content"])
        let language = row["language"] as? String
        let kind = row["kind"] as? String
        let payload: [String: Any] = [
            "post_id": id,
            "author": string(row["author_name"]).isEmpty ? (string(row["author"]).isEmpty ? "Member" : string(row["author"])) : string(row["author_name"]),
            "content_en": string(row["content_en"]).isEmpty ? content : string(row["content_en"]),
            "content_ig": string(row["content_ig"]).isEmpty ? content : string(row["content_ig"]),
            "language": language == "ig" || language == "fr" ? language! : "en",
            "timestamp": string(row["created_at"]).isEmpty ? string(row["timestamp"]) : string(row["created_at"]),
            "kind": kind == "memory" || kind == "recipe" || kind == "story" ? kind! : "story",
        ]
        return decode(CommunityPost.self, from: payload)
    }

    nonisolated private static func mapService(_ row: [String: Any]) -> ServiceItem? {
        let doc = row["doc"] as? [String: Any] ?? [:]
        let id = (row["id"] as? String) ?? string(doc["service_id"])
        guard !id.isEmpty else { return nil }
        var payload: [String: Any] = [
            "service_id": id,
            "name": string(doc["name"]),
            "category": string(doc["category"]).isEmpty ? "market" : string(doc["category"]),
            "lat": number(doc["lat"]),
            "lng": number(doc["lng"]),
            "distance_km": number(doc["distance_km"]),
            "contact": firstString(doc["contact"], doc["contactInfo"], doc["phone"]),
            "address": string(doc["address"]),
            "hours_en": firstString(doc["hours_en"], doc["hours"]),
            "accessibility_notes_en": firstString(doc["accessibility_notes_en"], doc["description"]),
        ]
        let email = string(doc["email"])
        let website = string(doc["website"])
        if !email.isEmpty { payload["email"] = email }
        if !website.isEmpty { payload["website"] = website }
        return decode(ServiceItem.self, from: payload)
    }

    nonisolated private static func decode<T: Decodable>(_ type: T.Type, from payload: [String: Any]) -> T? {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    nonisolated private static func string(_ value: Any?) -> String {
        value as? String ?? ""
    }

    nonisolated private static func firstString(_ values: Any?...) -> String {
        for value in values {
            let text = string(value)
            if !text.isEmpty { return text }
        }
        return ""
    }

    nonisolated private static func number(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String, let number = Double(text) { return number }
        return 0
    }

    nonisolated private static func randomVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URL
    }

    nonisolated private static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URL
    }
}

private extension Data {
    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
