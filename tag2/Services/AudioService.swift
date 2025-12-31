// AudioService.swift
// TAG2
//
// Audio service for playing sound effects

import AVFoundation
import Foundation
import Combine

class AudioService: ObservableObject {
    static let shared = AudioService()

    private var soundPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logWarning("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Effects

    func playSuccessSound() {
        guard let url = Bundle.main.url(forResource: "greatjob", withExtension: "mp3") else {
            logWarning("Sound file not found: greatjob.mp3")
            return
        }

        do {
            soundPlayer = try AVAudioPlayer(contentsOf: url)
            soundPlayer?.prepareToPlay()
            soundPlayer?.play()
        } catch {
            logWarning("Failed to play sound: \(error.localizedDescription)")
        }
    }

    func stopSound() {
        soundPlayer?.stop()
        soundPlayer = nil
    }
}
