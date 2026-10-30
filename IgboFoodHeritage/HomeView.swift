import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let featured = model.featuredRecipe {
                        NavigationLink(value: HomeRoute.recipe(featured.recipe_id)) {
                            ZStack(alignment: .bottomLeading) {
                                PhotoView(filename: featured.final_image, height: 240)
                                colors.overlay.frame(maxWidth: .infinity, maxHeight: .infinity)
                                VStack(alignment: .leading, spacing: 6) {
                                    StyledText(text: model.t("featuredRecipe"), kind: .eyebrow, color: colors.inverse)
                                    StyledText(text: model.displayName(featured), kind: .subtitle, color: colors.inverse)
                                }
                                .padding(18)
                            }
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(model.displayName(featured))
                    }

                    Card(fill: colors.forest) {
                        VStack(alignment: .leading, spacing: 8) {
                            StyledText(text: model.t("healthTipToday"), kind: .eyebrow, color: colors.inverse)
                            StyledText(text: model.t("healthTipUtazi"), kind: .body, color: colors.inverse)
                        }
                    }

                    StyledText(text: model.t("quickActions"), kind: .subtitle, color: colors.text)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        NavigationLink(value: HomeRoute.nutrition) {
                            tileLabel(model.t("nutrition"), "leaf")
                        }
                        .buttonStyle(.plain)
                        Button { model.tab = .recipes } label: { tileLabel(model.t("recipes"), "book") }
                            .buttonStyle(.plain)
                        Button { model.tab = .community } label: { tileLabel(model.t("community"), "person.2") }
                            .buttonStyle(.plain)
                        Button { model.tab = .services } label: { tileLabel(model.t("services"), "mappin.and.ellipse") }
                            .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .appBackground()
            .navigationTitle(model.t("appTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(value: HomeRoute.settings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(colors.forest)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(model.t("settings"))
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .nutrition:
                    NutritionView()
                case .settings:
                    SettingsView()
                case .admin:
                    AdminRecipesView()
                case .recipe(let id):
                    RecipeDetailView(recipeId: id, host: .home)
                case .cooking(let id):
                    CookingView(recipeId: id)
                }
            }
        }
    }

    private func tileLabel(_ title: String, _ symbol: String) -> some View {
        Card {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(colors.forest)
                    .frame(width: 44, height: 44)
                    .background(colors.cream)
                    .clipShape(Circle())
                StyledText(text: title, kind: .label, color: colors.text, alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}
