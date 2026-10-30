import AVFoundation
import Foundation

@MainActor
final class Speaker {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, language: Lang, rate: Float = 0.95) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activateSession()
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        if let voice = voice(for: language) {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func voice(for language: Lang) -> AVSpeechSynthesisVoice? {
        let installed = AVSpeechSynthesisVoice.speechVoices().filter(isUsable)
        let wanted = languagePrefix(language.speechCode)
        if let match = installed.first(where: { languagePrefix($0.language) == wanted }) {
            return match
        }
        if let english = installed.first(where: { languagePrefix($0.language) == "en" }) {
            return english
        }
        if let current = usable(AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())) {
            return current
        }
        if let english = usable(AVSpeechSynthesisVoice(language: "en-US")) {
            return english
        }
        for identifier in [
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.ttsbundle.siri_female_en-US_compact",
        ] {
            if let voice = usable(AVSpeechSynthesisVoice(identifier: identifier)) {
                return voice
            }
        }
        return installed.first
    }

    private func languagePrefix(_ code: String) -> String {
        code.split(separator: "-").first.map(String.init)?.lowercased() ?? code.lowercased()
    }

    private func usable(_ voice: AVSpeechSynthesisVoice?) -> AVSpeechSynthesisVoice? {
        guard let voice, isUsable(voice) else { return nil }
        return voice
    }

    private func isUsable(_ voice: AVSpeechSynthesisVoice) -> Bool {
        !voice.identifier.isEmpty && !voice.language.isEmpty
    }
}
