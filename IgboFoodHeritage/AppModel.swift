import Foundation
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var tab: AppTab = .home
    @Published private(set) var catalog: CatalogFile
    @Published var posts: [CommunityPost]
    @Published var services: [ServiceItem]
    @Published var session: AuthSession?
    @Published var loadError: String?
    @Published var authBusy = false

    let speaker = Speaker()
    let supabaseEnabled: Bool
    private let client: SupabaseClient?
    private let featuredId: String?
    private let settingsKey = "afrobiome.app-settings-v1"
    private let sessionKey = "afrobiome.auth-session"

    init() {
        let stored = UserDefaults.standard.data(forKey: "afrobiome.app-settings-v1")
            .flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
        settings = stored ?? AppSettings()

        let loadedSession = UserDefaults.standard.data(forKey: "afrobiome.auth-session")
            .flatMap { try? JSONDecoder().decode(AuthSession.self, from: $0) }

        if let config = SupabaseConfig.current {
            supabaseEnabled = true
            client = SupabaseClient(config: config, session: loadedSession)
            session = loadedSession
        } else {
            supabaseEnabled = false
            client = nil
            session = nil
        }

        do {
            let file = try CatalogFile.load()
            catalog = file
            posts = file.community
            services = file.services
            featuredId = file.recipes.randomElement()?.recipe_id
            loadError = nil
        } catch {
            catalog = CatalogFile(
                strings: ["en": [:], "ig": [:], "fr": [:]],
                categories: [],
                recipes: [],
                services: [],
                community: [],
                nutrition: NutritionBundle(conditions: [], ingredients: [], myths: [])
            )
            posts = []
            services = []
            featuredId = nil
            loadError = error.localizedDescription
        }
    }

    var colors: Palette { settings.highContrast ? .highContrast : .standard }
    var isAdmin: Bool { session?.isAdmin == true }
    var featuredRecipe: Recipe? {
        catalog.recipes.first { $0.recipe_id == featuredId } ?? catalog.recipes.first
    }

    func t(_ key: String, _ vars: [String: CustomStringConvertible] = [:]) -> String {
        let lang = settings.language.rawValue
        var text = catalog.strings[lang]?[key] ?? catalog.strings["en"]?[key] ?? key
        for (name, value) in vars {
            text = text.replacingOccurrences(of: "{{\(name)}}", with: String(describing: value))
        }
        return text
    }

    func displayName(_ recipe: Recipe) -> String {
        Localized.text(settings.language, en: recipe.name_en, ig: recipe.name_ig)
    }

    func recipeCopy(_ recipe: Recipe, language: Lang? = nil) -> RecipeCopy {
        let lang = language ?? settings.language
        return RecipeCopy(
            name: Localized.text(lang, en: recipe.name_en, ig: recipe.name_ig),
            ingredients: Localized.list(lang, en: recipe.ingredients_en, ig: recipe.ingredients_ig),
            instructions: Localized.list(lang, en: recipe.instructions_en, ig: recipe.instructions_ig),
            cultural: Localized.text(lang, en: recipe.cultural_notes_en, ig: recipe.cultural_notes_ig)
        )
    }

    func recipe(id: String) -> Recipe? {
        catalog.recipes.first { $0.recipe_id == id }
    }

    func categoryLabel(_ category: RecipeCategoryInfo) -> String {
        category.label(for: settings.language)
    }

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        var next = settings
        mutate(&next)
        settings = next
        if let data = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func setLanguage(_ language: Lang) {
        updateSettings { $0.language = language }
    }

    func completeOnboarding(guest: Bool) {
        updateSettings {
            $0.onboardingComplete = true
            $0.guestMode = guest
        }
    }

    func resetOnboarding() {
        updateSettings { $0.onboardingComplete = false }
    }

    func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func signIn(email: String, password: String) async throws {
        guard let client else { throw SupabaseError.failure(t("supabaseEnvSetup")) }
        let next = try await client.signIn(email: email, password: password)
        store(next)
    }

    func register(email: String, password: String) async throws {
        guard let client else { throw SupabaseError.failure(t("supabaseEnvSetup")) }
        let next = try await client.signUp(email: email, password: password)
        store(next)
    }

    func signInWithGoogle() async throws {
        guard let client else { throw SupabaseError.failure(t("supabaseEnvSetup")) }
        if let next = try await client.signInWithGoogle() {
            store(next)
        }
    }

    func refreshClaims() async {
        guard let client else { return }
        if let next = try? await client.refreshClaims() {
            store(next)
        }
    }

    func signOut() async {
        await client?.signOut()
        session = nil
        client?.session = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func refreshCommunity() async {
        guard let client else {
            posts = catalog.community
            return
        }
        if let remote = try? await client.fetchCommunity(), !remote.isEmpty {
            posts = remote.sorted { $0.timestamp > $1.timestamp }
        } else {
            posts = catalog.community
        }
    }

    func refreshServices() async {
        guard let client else {
            services = catalog.services
            return
        }
        if let remote = try? await client.fetchServices(), !remote.isEmpty {
            services = remote
        } else {
            services = catalog.services
        }
    }

    func publishPost(kind: String, body: String, audience: String) async throws {
        guard let client else { throw SupabaseError.failure(t("demoPostNoSupabase")) }
        guard session != nil else { throw SupabaseError.failure(t("signInToPost")) }
        let title = body.count > 120 ? "\(body.prefix(117))…" : body
        try await client.insertPost(
            title: title,
            content: body,
            language: settings.language.rawValue,
            kind: kind,
            audience: audience
        )
        await refreshCommunity()
    }

    func loadAdminRecipes() async throws -> [RemoteRecipe] {
        guard let client else { throw SupabaseError.failure(t("supabaseNotConfigured")) }
        return try await client.fetchRecipes()
    }

    func saveAdminRecipe(existingId: String?, sourceId: String, doc: [String: Any]) async throws {
        guard let client else { throw SupabaseError.failure(t("supabaseNotConfigured")) }
        try await client.saveRecipe(existingId: existingId, sourceId: sourceId, doc: doc)
    }

    func deleteAdminRecipe(id: String) async throws {
        guard let client else { throw SupabaseError.failure(t("supabaseNotConfigured")) }
        try await client.deleteRecipe(id: id)
    }

    private func store(_ next: AuthSession) {
        session = next
        client?.session = next
        if let data = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }
}
