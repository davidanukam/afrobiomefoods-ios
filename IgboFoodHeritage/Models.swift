import Foundation

enum Lang: String, Codable, CaseIterable, Identifiable {
    case en, ig, fr

    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: "English"
        case .ig: "Igbo"
        case .fr: "Français"
        }
    }

    var speechCode: String {
        switch self {
        case .en: "en-US"
        case .ig: "ig-NG"
        case .fr: "fr-FR"
        }
    }

    var next: Lang {
        switch self {
        case .en: .ig
        case .ig: .fr
        case .fr: .en
        }
    }
}

enum FontScaleKey: String, Codable, CaseIterable, Identifiable {
    case normal, large, xlarge

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .normal: 1
        case .large: 1.15
        case .xlarge: 1.3
        }
    }

    var labelKey: String {
        switch self {
        case .normal: "normal"
        case .large: "large"
        case .xlarge: "extraLarge"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var language: Lang = .en
    var fontScale: FontScaleKey = .normal
    var highContrast = false
    var audioGuidance = false
    var onboardingComplete = false
    var guestMode = true
}

struct NutritionFacts: Codable, Hashable {
    var calories: Int
    var protein: Int
    var fiber: Int
}

struct Recipe: Codable, Identifiable, Hashable {
    var id: String { recipe_id }
    let recipe_id: String
    let category: String
    let name_en: String
    let name_ig: String
    let ingredients_en: [String]
    let ingredients_ig: [String]
    let instructions_en: [String]
    let instructions_ig: [String]
    let cultural_notes_en: String
    let cultural_notes_ig: String
    let cook_minutes: Int
    let servings: Int
    let difficulty: String
    let nutrition: NutritionFacts
    let health_tags: [String]
    let image_hint: String
    let final_image: String
    let ingredient_image: String
    let audio_en: String?
    let audio_ig: String?
}

struct RecipeCategoryInfo: Codable, Identifiable, Hashable {
    var id: String
    let label_en: String
    let label_ig: String
    let label_fr: String

    func label(for lang: Lang) -> String {
        switch lang {
        case .ig: label_ig
        case .fr: label_fr.isEmpty ? label_en : label_fr
        case .en: label_en
        }
    }
}

struct ServiceItem: Codable, Identifiable, Hashable {
    var id: String { service_id }
    let service_id: String
    let name: String
    let category: String
    let lat: Double
    let lng: Double
    let distance_km: Double
    let contact: String
    let address: String
    let email: String?
    let website: String?
    let hours_en: String
    let accessibility_notes_en: String

    var emails: [String] {
        guard let email else { return [] }
        return email
            .split { $0 == ";" || $0 == "," }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var hasCoordinates: Bool {
        lat.isFinite && lng.isFinite && abs(lat) <= 90 && abs(lng) <= 180
    }
}

struct CommunityPost: Codable, Identifiable, Hashable {
    var id: String { post_id }
    let post_id: String
    let author: String
    let content_en: String
    let content_ig: String
    let language: String
    let timestamp: String
    let kind: String

    func content(for lang: Lang) -> String {
        lang == .ig ? content_ig : content_en
    }
}

struct ConditionTopic: Codable, Identifiable, Hashable {
    let id: String
    let title_en: String
    let title_ig: String
    let title_fr: String
    let summary_en: String
    let summary_ig: String
    let summary_fr: String
    let tips_en: [String]
    let tips_ig: [String]
    let tips_fr: [String]
}

struct IngredientSpotlight: Codable, Identifiable, Hashable {
    let id: String
    let name_en: String
    let name_ig: String
    let name_fr: String
    let uses_en: String
    let uses_ig: String
    let uses_fr: String
    let science_en: String
    let science_ig: String
    let science_fr: String
}

struct MythFact: Codable, Hashable {
    let myth_en: String
    let myth_ig: String
    let myth_fr: String
    let fact_en: String
    let fact_ig: String
    let fact_fr: String
}

struct NutritionBundle: Codable, Hashable {
    let conditions: [ConditionTopic]
    let ingredients: [IngredientSpotlight]
    let myths: [MythFact]
}

struct CatalogFile: Codable {
    let strings: [String: [String: String]]
    let categories: [RecipeCategoryInfo]
    let recipes: [Recipe]
    let services: [ServiceItem]
    let community: [CommunityPost]
    let nutrition: NutritionBundle

    static func load() throws -> CatalogFile {
        let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "catalog", withExtension: "json")
        guard let url else { throw CocoaError(.fileNoSuchFile) }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CatalogFile.self, from: data)
    }
}

enum Localized {
    static func text(_ lang: Lang, en: String, ig: String, fr: String? = nil) -> String {
        switch lang {
        case .ig: ig
        case .fr:
            if let fr, !fr.isEmpty { fr } else { en }
        case .en: en
        }
    }

    static func list(_ lang: Lang, en: [String], ig: [String], fr: [String]? = nil) -> [String] {
        switch lang {
        case .ig: ig
        case .fr: (fr?.isEmpty == false ? fr! : en)
        case .en: en
        }
    }
}

struct RecipeCopy {
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let cultural: String
}

enum AppTab: Hashable {
    case home, recipes, community, services
}

enum HomeRoute: Hashable {
    case nutrition
    case settings
    case admin
    case recipe(String)
    case cooking(String)
}

enum RecipeRoute: Hashable {
    case detail(String)
    case cooking(String)
}

enum CommunityRoute: Hashable {
    case share(String)
}

enum OnboardingStep: Hashable {
    case accessibility
    case signIn
}

struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
