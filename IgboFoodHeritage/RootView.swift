import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.loadError != nil, model.catalog.recipes.isEmpty {
                Text(model.loadError ?? "The recipe catalog could not be loaded.")
                    .padding(24)
            } else if model.settings.onboardingComplete {
                MainTabs()
            } else {
                OnboardingView()
            }
        }
        .environment(\.palette, model.colors)
        .environment(\.appFontScale, model.settings.fontScale.multiplier)
        .environment(\.highContrast, model.settings.highContrast)
        .tint(model.colors.forest)
        .onAppear(perform: applyChrome)
        .onChange(of: model.settings.highContrast) { _ in applyChrome() }
        .onChange(of: model.settings.fontScale) { _ in applyChrome() }
    }

    private func applyChrome() {
        let colors = model.colors
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = colors.uiCard
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = colors.uiCream
        nav.shadowColor = .clear
        let title = UIFont.systemFont(ofSize: 20 * model.settings.fontScale.multiplier, weight: .heavy)
        nav.titleTextAttributes = [.foregroundColor: colors.uiForest, .font: title]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = colors.uiForest
    }
}

struct MainTabs: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        TabView(selection: $model.tab) {
            HomeView()
                .tabItem { Label(model.t("home"), systemImage: "house.fill") }
                .tag(AppTab.home)
            RecipesView()
                .tabItem { Label(model.t("recipes"), systemImage: "book.fill") }
                .tag(AppTab.recipes)
            CommunityView()
                .tabItem { Label(model.t("community"), systemImage: "person.2.fill") }
                .tag(AppTab.community)
            ServicesView()
                .tabItem { Label(model.t("services"), systemImage: "mappin.and.ellipse") }
                .tag(AppTab.services)
        }
        .tint(colors.forest)
    }
}
