import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            LanguageStep()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .accessibility:
                        AccessibilityStep()
                    case .signIn:
                        SignInStep()
                    }
                }
        }
    }
}

private struct LanguageStep: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        VStack(spacing: 16) {
            StyledText(text: model.t("appSubtitle"), kind: .eyebrow, color: colors.textMuted, alignment: .center)
                .frame(maxWidth: .infinity)
            StyledText(text: model.t("appTitle"), kind: .title, color: colors.text, alignment: .center)
                .frame(maxWidth: .infinity)
            StyledText(text: model.t("chooseLanguage"), kind: .subtitle, color: colors.text)
                .padding(.top, 16)
            HStack(spacing: 10) {
                ForEach(Lang.allCases) { lang in
                    Chip(label: lang.label, active: model.settings.language == lang, expands: true) {
                        model.haptic()
                        model.setLanguage(lang)
                    }
                }
            }
            StyledText(text: model.t("audioPromptAvailable"), kind: .caption, color: colors.textMuted, alignment: .center)
                .frame(maxWidth: .infinity)
            Spacer()
            NavigationLink(value: OnboardingStep.accessibility) {
                PrimaryButtonLabel(title: model.t("continue"))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct AccessibilityStep: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors

    var body: some View {
        VStack(spacing: 16) {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    StyledText(text: model.t("textSize"), kind: .subtitle, color: colors.text)
                    HStack(spacing: 10) {
                        ForEach(FontScaleKey.allCases) { size in
                            Chip(label: model.t(size.labelKey), active: model.settings.fontScale == size) {
                                model.updateSettings { $0.fontScale = size }
                            }
                        }
                    }
                }
            }
            Card {
                Toggle(isOn: Binding(
                    get: { model.settings.highContrast },
                    set: { value in model.updateSettings { $0.highContrast = value } }
                )) {
                    StyledText(text: model.t("highContrast"), kind: .body, color: colors.text)
                }
                .tint(colors.forestLight)
            }
            Card {
                Toggle(isOn: Binding(
                    get: { model.settings.audioGuidance },
                    set: { value in model.updateSettings { $0.audioGuidance = value } }
                )) {
                    StyledText(text: model.t("audioNavigation"), kind: .body, color: colors.text)
                }
                .tint(colors.forestLight)
            }
            Spacer()
            NavigationLink(value: OnboardingStep.signIn) {
                PrimaryButtonLabel(title: model.t("continue"))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .appBackground()
        .navigationTitle(model.t("accessibilityTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct SignInStep: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.palette) private var colors
    @State private var mode = "login"
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var busy = false
    @State private var notice: Notice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                StyledText(text: model.t("signInSubtitle"), kind: .body, color: colors.textMuted, alignment: .center)
                    .frame(maxWidth: .infinity)
                if !model.supabaseEnabled {
                    StyledText(text: model.t("supabaseMissingGuest"), kind: .caption, color: colors.textMuted, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
                HStack(spacing: 10) {
                    Chip(label: model.t("signIn"), active: mode == "login", expands: true) { mode = "login" }
                    Chip(label: model.t("register"), active: mode == "register", expands: true) { mode = "register" }
                }
                .padding(.vertical, 8)
                FieldLabel(text: "Email")
                RoundedField(placeholder: "you@example.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress, autocapitalize: false)
                FieldLabel(text: model.t("password"))
                RoundedField(placeholder: "••••••••", text: $password, secure: true, contentType: .password, autocapitalize: false)
                if mode == "register" {
                    FieldLabel(text: model.t("confirmPassword"))
                    RoundedField(placeholder: "••••••••", text: $confirm, secure: true, contentType: .password, autocapitalize: false)
                }
                PrimaryButton(title: buttonTitle, disabled: busy) {
                    Task { await submit() }
                }
                if model.supabaseEnabled {
                    StyledText(text: model.t("orWord"), kind: .caption, color: colors.textMuted, alignment: .center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    Button {
                        Task { await google() }
                    } label: {
                        Text("Continue with Google")
                            .font(.system(size: 17 * model.settings.fontScale.multiplier, weight: .semibold))
                            .foregroundStyle(colors.text)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .background(colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(colors.border))
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                }
                PrimaryButton(title: model.t("guestContinue"), outline: true) {
                    model.completeOnboarding(guest: true)
                }
                .padding(.top, 12)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .appBackground()
        .navigationTitle(model.t("signIn"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(colors.cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .noticeAlert($notice)
        .onChange(of: model.session?.userId) { _, userId in
            if userId != nil {
                model.completeOnboarding(guest: false)
            }
        }
    }

    private var buttonTitle: String {
        if mode == "login" { return busy ? model.t("signingIn") : model.t("signIn") }
        return busy ? model.t("creatingAccount") : model.t("createAccount")
    }

    private func submit() async {
        guard model.supabaseEnabled else {
            notice = Notice(title: "Supabase", message: model.t("supabaseEnvSetup"))
            return
        }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), password.count >= 6 else {
            notice = Notice(title: model.t("checkInput"), message: model.t("invalidEmailPassword"))
            return
        }
        if mode == "register", password != confirm {
            notice = Notice(title: model.t("password"), message: model.t("passwordsMismatch"))
            return
        }
        busy = true
        defer { busy = false }
        do {
            if mode == "login" {
                try await model.signIn(email: trimmed, password: password)
            } else {
                try await model.register(email: trimmed, password: password)
            }
            model.completeOnboarding(guest: false)
        } catch {
            notice = Notice(title: model.t("authError"), message: error.localizedDescription)
        }
    }

    private func google() async {
        busy = true
        defer { busy = false }
        do {
            try await model.signInWithGoogle()
            if model.session != nil {
                model.completeOnboarding(guest: false)
            }
        } catch {
            notice = Notice(title: "Google Sign-In", message: error.localizedDescription)
        }
    }
}

struct PrimaryButtonLabel: View {
    @Environment(\.palette) private var colors
    @Environment(\.appFontScale) private var scale
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 17 * scale, weight: .bold))
            .foregroundStyle(colors.inverse)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(colors.forest)
            .clipShape(Capsule())
    }
}
