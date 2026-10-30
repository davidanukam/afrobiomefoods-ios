import SwiftUI

struct CommunityView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @State private var filter = "all"

    private var visible: [CommunityPost] {
        if filter == "all" { return model.posts }
        return model.posts.filter { $0.kind == filter }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    StyledText(text: model.t("communityIntro"), kind: .body, color: colors.textMuted)
                    HStack(spacing: 8) {
                        Chip(label: model.t("allPosts"), active: filter == "all") { filter = "all" }
                        Chip(label: model.t("kindRecipe"), active: filter == "recipe") { filter = "recipe" }
                        Chip(label: model.t("kindMemory"), active: filter == "memory") { filter = "memory" }
                    }
                    NavigationLink(value: CommunityRoute.share("recipe")) {
                        PrimaryButtonLabel(title: model.t("shareRecipe"))
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: CommunityRoute.share("memory")) {
                        outline(model.t("shareMemory"))
                    }
                    .buttonStyle(.plain)

                    if visible.isEmpty {
                        StyledText(text: model.t("communityEmpty"), kind: .body, color: colors.textMuted)
                    } else {
                        ForEach(visible) { post in
                            Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Text(String(post.author.prefix(1)).uppercased())
                                            .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
                                            .foregroundStyle(colors.inverse)
                                            .frame(width: 40, height: 40)
                                            .background(colors.forest)
                                            .clipShape(Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            StyledText(text: post.author, kind: .label, color: colors.text)
                                            StyledText(text: model.t(kindKey(post.kind)), kind: .caption, color: colors.textMuted)
                                        }
                                    }
                                    StyledText(text: post.content(for: model.settings.language), kind: .body, color: colors.text)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await model.refreshCommunity() }
            .task {
                guard model.supabaseEnabled else { return }
                await model.refreshCommunity()
            }
            .navigationDestination(for: CommunityRoute.self) { route in
                switch route {
                case .share(let kind):
                    ShareView(kind: kind)
                }
            }
        }
    }

    private func kindKey(_ kind: String) -> String {
        switch kind {
        case "recipe": return "kindRecipe"
        case "memory": return "kindMemory"
        default: return "kindStory"
        }
    }

    private func outline(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17 * model.settings.fontScale.multiplier, weight: .bold))
            .foregroundStyle(colors.forest)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .overlay(Capsule().stroke(colors.forest, lineWidth: 1.5))
    }
}

struct ShareView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @Environment(\.dismiss) private var dismiss
    @State var kind: String
    @State private var text = ""
    @State private var audience = "community"
    @State private var busy = false
    @State private var notice: Notice?
    @State private var postedDemo = false

    private var maxWords: Int { kind == "recipe" ? 250 : 150 }
    private var words: Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.split { $0.isWhitespace }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StyledText(text: model.t("choosePostType"), kind: .caption, color: colors.textMuted)
                HStack(spacing: 12) {
                    Chip(label: model.t("kindRecipe"), active: kind == "recipe", expands: true) { kind = "recipe" }
                    Chip(label: model.t("kindMemory"), active: kind == "memory", expands: true) { kind = "memory" }
                }
                StyledText(
                    text: kind == "recipe" ? model.t("typeRecipePrompt") : model.t("typeMemoryPrompt"),
                    kind: .subtitle,
                    color: colors.text
                )
                TextEditor(text: $text)
                    .font(.system(size: 18 * model.settings.fontScale.multiplier))
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .foregroundStyle(colors.text)
                StyledText(
                    text: model.t("wordCount", ["count": words, "max": maxWords]),
                    kind: .caption,
                    color: words > maxWords ? colors.danger : colors.textMuted
                )
                StyledText(text: model.t("chooseAudience"), kind: .caption, color: colors.textMuted)
                HStack(spacing: 12) {
                    Chip(label: model.t("community"), active: audience == "community", expands: true) { audience = "community" }
                    Chip(label: model.t("familyOnly"), active: audience == "family", expands: true) { audience = "family" }
                }
                PrimaryButton(title: model.t("post"), disabled: busy || words > maxWords) {
                    Task { await post() }
                }
                if busy {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(model.t("posting"))
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .appBackground()
        .navigationTitle(kind == "recipe" ? model.t("shareRecipe") : model.t("shareMemory"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .noticeAlert($notice)
        .alert(model.t("postedDemo"), isPresented: $postedDemo) {
            Button("OK") { dismiss() }
        } message: {
            Text(model.t("demoPostNoSupabase"))
        }
    }

    private func post() async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            notice = Notice(title: model.t("headsUp"), message: model.t("storyTooShort"))
            return
        }
        guard words <= maxWords else {
            notice = Notice(title: model.t("headsUp"), message: model.t("storyTooLong", ["max": maxWords]))
            return
        }
        guard model.supabaseEnabled else {
            postedDemo = true
            return
        }
        guard model.session != nil else {
            notice = Notice(title: model.t("signInRequired"), message: model.t("signInToPost"))
            return
        }
        busy = true
        defer { busy = false }
        do {
            try await model.publishPost(kind: kind, body: body, audience: audience)
            dismiss()
        } catch {
            notice = Notice(title: model.t("errorPost"), message: error.localizedDescription)
        }
    }
}
