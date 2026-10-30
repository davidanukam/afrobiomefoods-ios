import SwiftUI

enum RecipeHost {
    case home, recipes
}

struct RecipesView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @State private var query = ""
    @State private var category = "all"

    private var chips: [(id: String, label: String)] {
        [("all", model.t("categoryAll"))] + model.catalog.categories.map { ($0.id, model.categoryLabel($0)) }
    }

    private var filtered: [Recipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return model.catalog.recipes
            .filter { recipe in
                let matchesCategory = category == "all" || recipe.category == category
                let matchesQuery = q.isEmpty
                    || recipe.name_en.lowercased().contains(q)
                    || recipe.name_ig.lowercased().contains(q)
                    || recipe.health_tags.contains { $0.lowercased().contains(q) }
                return matchesCategory && matchesQuery
            }
            .sorted {
                model.displayName($0).localizedStandardCompare(model.displayName($1)) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField(model.t("search"), text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17 * model.settings.fontScale.multiplier))
                        .padding(.horizontal, 18)
                        .frame(minHeight: 48)
                        .background(colors.card)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(colors.border, lineWidth: model.settings.highContrast ? 2 : 0))
                        .accessibilityLabel(model.t("search"))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(chips, id: \.id) { chip in
                                Chip(label: chip.label, active: category == chip.id) {
                                    category = chip.id
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if filtered.isEmpty {
                        StyledText(text: model.t("recipesEmpty"), kind: .body, color: colors.textMuted, alignment: .center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        ForEach(filtered) { recipe in
                            NavigationLink(value: RecipeRoute.detail(recipe.recipe_id)) {
                                recipeCard(recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: RecipeRoute.self) { route in
                switch route {
                case .detail(let id):
                    RecipeDetailView(recipeId: id, host: .recipes)
                case .cooking(let id):
                    CookingView(recipeId: id)
                }
            }
        }
    }

    private func recipeCard(_ recipe: Recipe) -> some View {
        HStack(spacing: 14) {
            PhotoView(filename: recipe.final_image)
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                StyledText(text: model.displayName(recipe), kind: .subtitle, color: colors.text)
                StyledText(
                    text: "\(recipe.cook_minutes) min · \(recipe.health_tags.first ?? "")",
                    kind: .caption,
                    color: colors.textMuted
                )
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(colors.border, lineWidth: model.settings.highContrast ? 2 : 0)
        )
        .shadow(color: model.settings.highContrast ? .clear : Color(hex: 0x14201A).opacity(0.12), radius: 16, y: 8)
    }
}

struct RecipeDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    var recipeId: String
    var host: RecipeHost
    @State private var notice: Notice?

    var body: some View {
        Group {
            if let recipe = model.recipe(id: recipeId) {
                detail(recipe)
            } else {
                StyledText(text: model.t("recipeNotFound"), kind: .body, color: colors.text)
                    .padding(24)
                    .appBackground()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .noticeAlert($notice)
        .onDisappear { model.speaker.stop() }
    }

    private func detail(_ recipe: Recipe) -> some View {
        let copy = model.recipeCopy(recipe)
        return ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    StyledText(text: copy.name, kind: .title, color: colors.text)
                        .padding(.bottom, 4)
                    PhotoView(filename: recipe.ingredient_image, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .accessibilityLabel("\(copy.name), \(model.t("ingredientPhoto"))")

                    StyledText(text: model.t("listen"), kind: .caption, color: colors.textMuted)
                        .padding(.top, 8)
                    HStack(spacing: 8) {
                        listenButton(model.t("listenEn"), fill: model.settings.highContrast ? colors.forest : colors.gold, text: model.settings.highContrast ? colors.inverse : colors.forest) {
                            read(recipe, language: .en)
                        }
                        listenButton(model.t("listenIg"), fill: colors.forestLight, text: colors.inverse) {
                            read(recipe, language: .ig)
                        }
                        listenButton(model.t("listenFr"), fill: model.settings.highContrast ? colors.forest : Color(hex: 0x8C4A32), text: colors.inverse) {
                            read(recipe, language: .fr)
                        }
                    }

                    StyledText(text: model.t("ingredients"), kind: .subtitle, color: colors.text)
                        .padding(.top, 8)
                    ForEach(Array(copy.ingredients.enumerated()), id: \.offset) { _, line in
                        StyledText(text: "• \(line)", kind: .body, color: colors.text)
                    }
                }

                Group {
                    PhotoView(filename: recipe.final_image, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(.top, 8)
                        .accessibilityLabel("\(copy.name), \(model.t("finishedDishPhoto"))")

                    StyledText(text: model.t("instructions"), kind: .subtitle, color: colors.text)
                        .padding(.top, 8)
                    ForEach(Array(copy.instructions.enumerated()), id: \.offset) { index, line in
                        StyledText(text: "\(index + 1). \(line)", kind: .body, color: colors.text)
                    }

                    StyledText(text: model.t("culturalNotes"), kind: .subtitle, color: colors.text)
                        .padding(.top, 8)
                    StyledText(text: copy.cultural, kind: .body, color: colors.text)
                }

                Group {
                    StyledText(text: model.t("healthBenefits"), kind: .subtitle, color: colors.text)
                        .padding(.top, 8)
                    StyledText(
                        text: "kcal: \(recipe.nutrition.calories) · Protein: \(recipe.nutrition.protein)g · Fiber: \(recipe.nutrition.fiber)g",
                        kind: .caption,
                        color: colors.textMuted
                    )
                    ForEach(Array(recipe.health_tags.enumerated()), id: \.offset) { _, tag in
                        StyledText(text: "• \(tag)", kind: .body, color: colors.text)
                    }

                    cookingLink(recipe)
                        .padding(.top, 12)
                    HStack(spacing: 12) {
                        Button {
                            notice = Notice(title: model.t("save"), message: model.t("savedRecipesPhase2"))
                        } label: {
                            outlineLabel(model.t("save"))
                        }
                        .buttonStyle(.plain)
                        ShareLink(item: shareBody(copy)) {
                            outlineLabel(model.t("share"))
                        }
                        .buttonStyle(.plain)
                    }
                    StyledText(text: model.t("demoAudio"), kind: .caption, color: colors.textMuted)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .padding(.bottom, 16)
        }
        .appBackground()
    }

    @ViewBuilder
    private func cookingLink(_ recipe: Recipe) -> some View {
        switch host {
        case .home:
            NavigationLink(value: HomeRoute.cooking(recipe.recipe_id)) {
                PrimaryButtonLabel(title: model.t("startCookingMode"))
            }
            .buttonStyle(.plain)
        case .recipes:
            NavigationLink(value: RecipeRoute.cooking(recipe.recipe_id)) {
                PrimaryButtonLabel(title: model.t("startCookingMode"))
            }
            .buttonStyle(.plain)
        }
    }

    private func outlineLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
            .foregroundStyle(colors.accent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .overlay(Capsule().stroke(colors.forest, lineWidth: 1.5))
    }

    private func listenButton(_ title: String, fill: Color, text: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
                .foregroundStyle(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(fill)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(model.t("listen")) \(title)")
    }

    private func read(_ recipe: Recipe, language: Lang) {
        let copy = model.recipeCopy(recipe, language: language)
        let steps = copy.instructions.enumerated().map { "Step \($0.offset + 1). \($0.element)" }
        let body = (copy.ingredients + [""] + steps).joined(separator: ". ")
        model.speaker.speak(body, language: language)
    }

    private func shareBody(_ copy: RecipeCopy) -> String {
        let lines = copy.ingredients.map { "• \($0)" }.joined(separator: "\n")
        return "\(copy.name)\n\n\(lines)"
    }
}

struct CookingView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    var recipeId: String
    @State private var index = 0

    private var activeRecipe: Recipe? {
        model.recipe(id: recipeId)
    }

    private var activeSteps: [String] {
        guard let recipe = activeRecipe else { return [] }
        return model.recipeCopy(recipe).instructions
    }

    var body: some View {
        Group {
            if let recipe = activeRecipe, !activeSteps.isEmpty {
                cooking(recipe, activeSteps)
            } else {
                StyledText(text: model.t("noStepsFound"), kind: .body, color: colors.text)
                    .padding(24)
            }
        }
        .appBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onDisappear { model.speaker.stop() }
    }

    private func cooking(_ recipe: Recipe, _ steps: [String]) -> some View {
        let current = steps[min(index, steps.count - 1)]
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StyledText(text: model.displayName(recipe), kind: .subtitle, color: colors.text)
                StyledText(
                    text: model.t("stepOf", ["current": index + 1, "total": steps.count]),
                    kind: .caption,
                    color: colors.textMuted
                )
                Card {
                    StyledText(text: current, kind: .body, color: colors.text)
                }
                StyledText(text: model.t("cookingDemoNote"), kind: .caption, color: colors.textMuted)
                VStack(spacing: 12) {
                    control(model.t("pause")) { model.speaker.stop() }
                    control(model.t("replay")) { model.speaker.speak(current, language: model.settings.language, rate: 0.92) }
                    control(model.t("nextStep"), disabled: index >= steps.count - 1) {
                        index = min(index + 1, steps.count - 1)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

    private func control(_ title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17 * model.settings.fontScale.multiplier, weight: .bold))
                .foregroundStyle(colors.inverse)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(colors.forest)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
}
