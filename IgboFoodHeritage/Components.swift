import SwiftUI
import UIKit

enum BundleImage {
    private static let cache = NSCache<NSString, UIImage>()

    static func load(_ filename: String) -> UIImage? {
        let key = filename as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let ext = (filename as NSString).pathExtension
        let base = (filename as NSString).deletingPathExtension
        let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Resources/Images")
            ?? Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Images")
            ?? Bundle.main.url(forResource: base, withExtension: ext)
        guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}

struct PhotoView: View {
    var filename: String
    var height: CGFloat? = nil

    var body: some View {
        Group {
            if let image = BundleImage.load(filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let fallback = BundleImage.load("app-icon.png") {
                Image(uiImage: fallback)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }
}

struct Card<Content: View>: View {
    @Environment(\.palette) private var colors
    @Environment(\.highContrast) private var highContrast
    var fill: Color? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill ?? colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(colors.border, lineWidth: highContrast ? 2 : 0)
        )
        .shadow(color: highContrast ? .clear : Color(hex: 0x14201A).opacity(0.12), radius: 16, y: 8)
    }
}

struct Chip: View {
    @Environment(\.palette) private var colors
    @Environment(\.appFontScale) private var scale
    var label: String
    var active = false
    var expands = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(active ? colors.inverse : colors.text)
                .padding(.horizontal, 14)
                .frame(maxWidth: expands ? .infinity : nil)
                .frame(minHeight: 40)
                .background(active ? colors.forest : colors.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(active ? Color.clear : colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    @Environment(\.palette) private var colors
    @Environment(\.appFontScale) private var scale
    var title: String
    var outline = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17 * scale, weight: .bold))
                .foregroundStyle(outline ? colors.forest : colors.inverse)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(outline ? Color.clear : colors.forest)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(colors.forest, lineWidth: outline ? 1.5 : 0))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }
}

struct FieldLabel: View {
    @Environment(\.palette) private var colors
    var text: String

    var body: some View {
        StyledText(text: text, kind: .caption, color: colors.textMuted)
    }
}

struct RoundedField: View {
    @Environment(\.palette) private var colors
    @Environment(\.appFontScale) private var scale
    var placeholder: String
    @Binding var text: String
    var secure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var autocapitalize = true

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(size: 17 * scale))
        .textFieldStyle(.plain)
        .keyboardType(keyboard)
        .textContentType(contentType)
        .textInputAutocapitalization(autocapitalize ? .sentences : .never)
        .autocorrectionDisabled(!autocapitalize)
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(colors.text)
    }
}

extension View {
    func noticeAlert(_ notice: Binding<Notice?>) -> some View {
        alert(notice.wrappedValue?.title ?? "", isPresented: Binding(
            get: { notice.wrappedValue != nil },
            set: { if !$0 { notice.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notice.wrappedValue?.message ?? "")
        }
    }

    func appBackground() -> some View {
        modifier(AppBackground())
    }
}

private struct AppBackground: ViewModifier {
    @Environment(\.palette) private var colors

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(colors.cream.ignoresSafeArea())
    }
}
