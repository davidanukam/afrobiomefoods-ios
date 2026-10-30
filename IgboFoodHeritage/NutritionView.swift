import SwiftUI

struct NutritionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StyledText(text: model.t("conditionGuides"), kind: .subtitle, color: colors.text)
                ForEach(model.catalog.nutrition.conditions) { topic in
                    ConditionCard(topic: topic)
                }

                StyledText(text: model.t("ingredientSpotlight"), kind: .subtitle, color: colors.text)
                    .padding(.top, 8)
                ForEach(model.catalog.nutrition.ingredients) { item in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            StyledText(
                                text: Localized.text(model.settings.language, en: item.name_en, ig: item.name_ig, fr: item.name_fr),
                                kind: .subtitle,
                                color: colors.text
                            )
                            StyledText(
                                text: Localized.text(model.settings.language, en: item.uses_en, ig: item.uses_ig, fr: item.uses_fr),
                                kind: .body,
                                color: colors.text
                            )
                            StyledText(
                                text: Localized.text(model.settings.language, en: item.science_en, ig: item.science_ig, fr: item.science_fr),
                                kind: .caption,
                                color: colors.textMuted
                            )
                        }
                    }
                }

                StyledText(text: model.t("mythVsFact"), kind: .subtitle, color: colors.text)
                    .padding(.top, 8)
                ForEach(Array(model.catalog.nutrition.myths.enumerated()), id: \.offset) { _, myth in
                    Card {
                        VStack(alignment: .leading, spacing: 4) {
                            StyledText(text: model.t("myth"), kind: .caption, color: colors.textMuted)
                            StyledText(
                                text: Localized.text(model.settings.language, en: myth.myth_en, ig: myth.myth_ig, fr: myth.myth_fr),
                                kind: .body,
                                color: colors.text
                            )
                            StyledText(text: model.t("fact"), kind: .caption, color: colors.accent)
                                .padding(.top, 6)
                            StyledText(
                                text: Localized.text(model.settings.language, en: myth.fact_en, ig: myth.fact_ig, fr: myth.fact_fr),
                                kind: .body,
                                color: colors.text
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .appBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onDisappear { model.speaker.stop() }
    }
}

private struct ConditionCard: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    let topic: ConditionTopic

    var body: some View {
        card
    }

    private var card: some View {
        let title = Localized.text(model.settings.language, en: topic.title_en, ig: topic.title_ig, fr: topic.title_fr)
        let summary = Localized.text(model.settings.language, en: topic.summary_en, ig: topic.summary_ig, fr: topic.summary_fr)
        let tips = Localized.list(model.settings.language, en: topic.tips_en, ig: topic.tips_ig, fr: topic.tips_fr)
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                StyledText(text: title, kind: .subtitle, color: colors.text)
                StyledText(text: summary, kind: .body, color: colors.text)
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    StyledText(text: "• \(tip)", kind: .body, color: colors.text)
                }
                Button(action: { model.speaker.speak("\(title). \(summary)", language: model.settings.language) }) {
                    Text(model.t("listenTTS"))
                        .font(.system(size: 15 * model.settings.fontScale.multiplier, weight: .semibold))
                        .foregroundStyle(colors.inverse)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(colors.forestLight)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }
}
