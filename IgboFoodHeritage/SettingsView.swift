import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.supabaseEnabled {
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            StyledText(text: model.t("account"), kind: .eyebrow, color: colors.textMuted)
                            if let session = model.session {
                                StyledText(text: session.email ?? session.userId, kind: .subtitle, color: colors.text)
                                if session.isAdmin {
                                    StyledText(text: model.t("admin"), kind: .label, color: colors.accent)
                                }
                                PrimaryButton(title: model.t("refreshPermissions"), outline: true) {
                                    Task { await model.refreshClaims() }
                                }
                                if session.isAdmin {
                                    NavigationLink(value: HomeRoute.admin) {
                                        outlineLabel(model.t("editRecipesAdmin"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                PrimaryButton(title: model.t("signOut"), outline: true) {
                                    Task { await model.signOut() }
                                }
                            } else {
                                StyledText(text: model.t("guestNotSignedIn"), kind: .body, color: colors.textMuted)
                            }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        StyledText(text: model.t("language"), kind: .eyebrow, color: colors.textMuted)
                        FlowChips {
                            ForEach(Lang.allCases) { lang in
                                Chip(label: lang.label, active: model.settings.language == lang) {
                                    model.setLanguage(lang)
                                }
                            }
                            Chip(label: model.t("toggle")) {
                                model.haptic()
                                model.setLanguage(model.settings.language.next)
                            }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        StyledText(text: model.t("fontSize"), kind: .eyebrow, color: colors.textMuted)
                        FlowChips {
                            ForEach(FontScaleKey.allCases) { size in
                                Chip(label: model.t(size.labelKey), active: model.settings.fontScale == size) {
                                    model.updateSettings { $0.fontScale = size }
                                }
                            }
                        }
                        Toggle(isOn: Binding(
                            get: { model.settings.highContrast },
                            set: { value in model.updateSettings { $0.highContrast = value } }
                        )) {
                            StyledText(text: model.t("highContrast"), kind: .body, color: colors.text)
                        }
                        .tint(colors.forestLight)
                        Toggle(isOn: Binding(
                            get: { model.settings.audioGuidance },
                            set: { value in model.updateSettings { $0.audioGuidance = value } }
                        )) {
                            StyledText(text: model.t("audioNavigation"), kind: .body, color: colors.text)
                        }
                        .tint(colors.forestLight)
                    }
                }

                StyledText(text: model.t("notifications"), kind: .caption, color: colors.textMuted)
                StyledText(text: model.t("privacy"), kind: .caption, color: colors.textMuted)
                PrimaryButton(title: model.t("replayOnboarding"), outline: true) {
                    model.resetOnboarding()
                }
            }
            .padding(20)
        }
        .appBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func outlineLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17 * model.settings.fontScale.multiplier, weight: .bold))
            .foregroundStyle(colors.forest)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .overlay(Capsule().stroke(colors.forest, lineWidth: 1.5))
    }
}

struct FlowChips<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        FlowLayout(spacing: 8) {
            content()
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let rows = rows(width: width, subviews: subviews)
        let height = rows.map { $0.map(\.height).max() ?? 0 }.reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map(\.height).max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: item.width, height: item.height))
                x += item.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [[(view: LayoutSubview, width: CGFloat, height: CGFloat)]] {
        var rows: [[(view: LayoutSubview, width: CGFloat, height: CGFloat)]] = [[]]
        var used: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if used > 0, used + spacing + size.width > width {
                rows.append([])
                used = 0
            }
            rows[rows.count - 1].append((view, size.width, size.height))
            used += (used > 0 ? spacing : 0) + size.width
        }
        return rows
    }
}
