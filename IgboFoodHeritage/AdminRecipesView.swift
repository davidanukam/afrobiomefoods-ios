import SwiftUI

struct AdminRecipesView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @State private var rows: [RemoteRecipe] = []
    @State private var selectedId: String?
    @State private var form = RecipeForm()
    @State private var loading = false
    @State private var notice: Notice?
    @State private var confirmDelete = false

    private let categories = ["soups", "pepper_soups", "porridges", "delicacies", "snacks", "swallows", "vegetables", "soft"]
    private let difficulties = ["easy", "medium", "hard"]

    var body: some View {
        Group {
            if !model.supabaseEnabled {
                message(model.t("supabaseNotConfigured"))
            } else if !model.isAdmin {
                message("Admin access required.")
            } else {
                editor
            }
        }
        .navigationTitle("Admin Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
        .noticeAlert($notice)
        .alert("Delete recipe?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { Task { await removeSelected() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(selected?.sourceId ?? selected?.id ?? "")\".")
        }
    }

    private var selected: RemoteRecipe? { rows.first { $0.id == selectedId } }

    private var categoryChoices: [String] {
        var list = categories
        if !list.contains(form.category) { list.insert(form.category, at: 0) }
        return list
    }

    private var difficultyChoices: [String] {
        var list = difficulties
        if !list.contains(form.difficulty) { list.insert(form.difficulty, at: 0) }
        return list
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    PrimaryButton(title: "New recipe", outline: true) { startNew() }
                    PrimaryButton(title: loading ? "Refreshing..." : "Refresh", outline: true, disabled: loading) {
                        Task { await load() }
                    }
                }
                PrimaryButton(title: "Delete", outline: true, disabled: loading || selected == nil) {
                    confirmDelete = true
                }
                StyledText(text: "Recipes", kind: .subtitle, color: colors.text)
                ForEach(rows) { row in
                    Button {
                        selectedId = row.id
                        form = RecipeForm(row)
                    } label: {
                        Text(row.sourceId?.isEmpty == false ? row.sourceId! : row.id)
                            .font(.system(size: 13 * model.settings.fontScale.multiplier))
                            .foregroundStyle(colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 42)
                            .background(row.id == selectedId ? colors.gold.opacity(0.27) : colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(row.id == selectedId ? colors.forest : colors.border))
                    }
                    .buttonStyle(.plain)
                }

                field("source_id", text: $form.sourceId)
                StyledText(text: "Category", kind: .caption, color: colors.textMuted)
                FlowChips {
                    ForEach(categoryChoices, id: \.self) { category in
                        Chip(label: category, active: form.category == category) { form.category = category }
                    }
                }
                field("name_en", text: $form.nameEn)
                field("name_ig", text: $form.nameIg)
                field("cook_minutes", text: $form.cookMinutes, number: true)
                field("servings", text: $form.servings, number: true)
                StyledText(text: "difficulty", kind: .caption, color: colors.textMuted)
                FlowChips {
                    ForEach(difficultyChoices, id: \.self) { difficulty in
                        Chip(label: difficulty, active: form.difficulty == difficulty) { form.difficulty = difficulty }
                    }
                }
                field("calories", text: $form.calories, number: true)
                field("protein", text: $form.protein, number: true)
                field("fiber", text: $form.fiber, number: true)
                area("ingredients_en (one per line)", text: $form.ingredientsEn)
                area("ingredients_ig (one per line)", text: $form.ingredientsIg)
                area("instructions_en (one per line)", text: $form.instructionsEn)
                area("instructions_ig (one per line)", text: $form.instructionsIg)
                area("cultural_notes_en", text: $form.notesEn)
                area("cultural_notes_ig", text: $form.notesIg)
                area("health_tags (one per line)", text: $form.healthTags)
                field("image_hint", text: $form.imageHint)
                field("audio_en (optional URL)", text: $form.audioEn)
                field("audio_ig (optional URL)", text: $form.audioIg)
                PrimaryButton(title: loading ? "Saving..." : "Save to Supabase", disabled: loading) {
                    Task { await save() }
                }
                if let selected {
                    StyledText(text: "Editing row: \(selected.id)", kind: .caption, color: colors.textMuted)
                }
            }
            .padding(16)
        }
        .appBackground()
    }

    private func message(_ text: String) -> some View {
        StyledText(text: text, kind: .body, color: colors.text)
            .padding(24)
            .appBackground()
    }

    private func field(_ title: String, text: Binding<String>, number: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StyledText(text: title, kind: .caption, color: colors.textMuted)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .keyboardType(number ? .numberPad : .default)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.border))
        }
    }

    private func area(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StyledText(text: title, kind: .caption, color: colors.textMuted)
            TextEditor(text: text)
                .font(.system(size: 15))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.border))
        }
    }

    private func startNew() {
        selectedId = nil
        form = RecipeForm()
    }

    private func load() async {
        guard model.supabaseEnabled, model.isAdmin else { return }
        loading = true
        defer { loading = false }
        do {
            rows = try await model.loadAdminRecipes()
        } catch {
            notice = Notice(title: "Load failed", message: error.localizedDescription)
        }
    }

    private func save() async {
        guard model.isAdmin else {
            notice = Notice(title: "Admin only", message: "You need an admin claim to edit recipes.")
            return
        }
        let sourceId = form.sourceId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceId.isEmpty else {
            notice = Notice(title: "Missing source_id", message: "Add a stable source_id (e.g. ofe-oha).")
            return
        }
        guard !form.nameEn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            notice = Notice(title: "Missing name_en", message: "Please add an English recipe name.")
            return
        }
        loading = true
        defer { loading = false }
        let existing = rows.first { $0.sourceId == sourceId }
        do {
            try await model.saveAdminRecipe(existingId: existing?.id, sourceId: sourceId, doc: form.doc())
            notice = Notice(title: "Saved", message: "Recipe saved to Supabase.")
            rows = try await model.loadAdminRecipes()
            if let existing { selectedId = existing.id }
        } catch {
            notice = Notice(title: "Save failed", message: error.localizedDescription)
        }
    }

    private func removeSelected() async {
        guard let selected else { return }
        loading = true
        defer { loading = false }
        do {
            try await model.deleteAdminRecipe(id: selected.id)
            notice = Notice(title: "Deleted", message: "Recipe removed.")
            selectedId = nil
            form = RecipeForm()
            rows = try await model.loadAdminRecipes()
        } catch {
            notice = Notice(title: "Delete failed", message: error.localizedDescription)
        }
    }
}

struct RecipeForm {
    var sourceId = ""
    var category = "soups"
    var nameEn = ""
    var nameIg = ""
    var cookMinutes = "30"
    var servings = "4"
    var difficulty = "easy"
    var calories = "0"
    var protein = "0"
    var fiber = "0"
    var healthTags = ""
    var ingredientsEn = ""
    var ingredientsIg = ""
    var instructionsEn = ""
    var instructionsIg = ""
    var notesEn = ""
    var notesIg = ""
    var imageHint = "recipe"
    var audioEn = ""
    var audioIg = ""

    init() {}

    init(_ row: RemoteRecipe) {
        let doc = row.doc
        let nutrition = doc["nutrition"] as? [String: Any] ?? [:]
        sourceId = row.sourceId ?? ""
        category = Self.text(doc["category"]).isEmpty ? "soups" : Self.text(doc["category"])
        nameEn = Self.text(doc["name_en"])
        nameIg = Self.text(doc["name_ig"])
        cookMinutes = Self.number(doc["cook_minutes"], fallback: "30")
        servings = Self.number(doc["servings"], fallback: "4")
        difficulty = Self.text(doc["difficulty"]).isEmpty ? "easy" : Self.text(doc["difficulty"])
        calories = Self.number(nutrition["calories"], fallback: "0")
        protein = Self.number(nutrition["protein"], fallback: "0")
        fiber = Self.number(nutrition["fiber"], fallback: "0")
        healthTags = Self.lines(doc["health_tags"])
        ingredientsEn = Self.lines(doc["ingredients_en"])
        ingredientsIg = Self.lines(doc["ingredients_ig"])
        instructionsEn = Self.lines(doc["instructions_en"])
        instructionsIg = Self.lines(doc["instructions_ig"])
        notesEn = Self.text(doc["cultural_notes_en"])
        notesIg = Self.text(doc["cultural_notes_ig"])
        imageHint = Self.text(doc["image_hint"]).isEmpty ? "recipe" : Self.text(doc["image_hint"])
        audioEn = Self.text(doc["audio_en"])
        audioIg = Self.text(doc["audio_ig"])
    }

    func doc() -> [String: Any] {
        var payload: [String: Any] = [
            "category": category,
            "name_en": nameEn.trimmingCharacters(in: .whitespacesAndNewlines),
            "name_ig": nameIg.trimmingCharacters(in: .whitespacesAndNewlines),
            "ingredients_en": Self.split(ingredientsEn),
            "ingredients_ig": Self.split(ingredientsIg),
            "instructions_en": Self.split(instructionsEn),
            "instructions_ig": Self.split(instructionsIg),
            "cultural_notes_en": notesEn.trimmingCharacters(in: .whitespacesAndNewlines),
            "cultural_notes_ig": notesIg.trimmingCharacters(in: .whitespacesAndNewlines),
            "cook_minutes": Int(cookMinutes) ?? 0,
            "servings": Int(servings) ?? 0,
            "difficulty": difficulty,
            "nutrition": [
                "calories": Int(calories) ?? 0,
                "protein": Int(protein) ?? 0,
                "fiber": Int(fiber) ?? 0,
            ],
            "health_tags": Self.split(healthTags),
            "image_hint": imageHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "recipe" : imageHint.trimmingCharacters(in: .whitespacesAndNewlines),
        ]
        let audioEnglish = audioEn.trimmingCharacters(in: .whitespacesAndNewlines)
        let audioIgbo = audioIg.trimmingCharacters(in: .whitespacesAndNewlines)
        if !audioEnglish.isEmpty { payload["audio_en"] = audioEnglish }
        if !audioIgbo.isEmpty { payload["audio_ig"] = audioIgbo }
        return payload
    }

    private static func text(_ value: Any?) -> String { value as? String ?? "" }

    private static func number(_ value: Any?, fallback: String) -> String {
        if let number = value as? NSNumber { return number.stringValue }
        if let text = value as? String, !text.isEmpty { return text }
        return fallback
    }

    private static func lines(_ value: Any?) -> String {
        let items = (value as? [Any])?.compactMap { $0 as? String } ?? []
        return items.joined(separator: "\n")
    }

    private static func split(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
