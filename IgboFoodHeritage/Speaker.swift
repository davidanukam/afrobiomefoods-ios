import AVFoundation
import Foundation

@MainActor
final class Speaker {
    private let synth = AVSpeechSynthesizer()

    @discardableResult
    func speak(_ text: String, language: Lang, rate: Float = 0.95) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let voice = voice(for: language) else { return false }
        activateSession()
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate
        synth.speak(utterance)
        return true
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
        guard !installed.isEmpty else { return nil }
        let wanted = languagePrefix(language.speechCode)
        if let match = installed.first(where: { languagePrefix($0.language) == wanted }) {
            return match
        }
        if let english = installed.first(where: { languagePrefix($0.language) == "en" }) {
            return english
        }
        return installed.first
    }

    private func languagePrefix(_ code: String) -> String {
        code.split(separator: "-").first.map(String.init)?.lowercased() ?? code.lowercased()
    }

    private func isUsable(_ voice: AVSpeechSynthesisVoice) -> Bool {
        !voice.identifier.isEmpty && !voice.language.isEmpty
    }
}
