//
//  SoundManager.swift
//  Level10
//
//  Created by Dennis Beatty on 7/19/22.
//

import AVFoundation

enum SoundEffect: String {
    case buttonTap = "button-tap"
    case levelComplete = "level-complete"
    case notify = "notify"
    case roundOverLost = "round-over-lost"
    case roundOverWon = "round-over-won"
}

enum Volume: Float {
    case extraLow = 0.005
    case low = 0.01
    case medium = 0.05
    case high = 0.1
}

class SoundManager {
    static let shared = SoundManager()
    
    var player: AVAudioPlayer?
    
    private init() {}
    
    func playButtonTap(volume: Volume = .medium) {
        playSound(.buttonTap, volume: volume.rawValue)
    }
    
    func playLevelComplete(volume: Volume = .medium) {
        playSound(.levelComplete, volume: volume.rawValue)
    }
    
    func playNotify(volume: Volume = .medium) {
        playSound(.notify, volume: volume.rawValue)
    }
    
    func playRoundOverLost(volume: Volume = .medium) {
        playSound(.roundOverLost, volume: volume.rawValue)
    }
    
    func playRoundOverWon(volume: Volume = .medium) {
        playSound(.roundOverWon, volume: volume.rawValue)
    }
    
    private func playSound(_ sound: SoundEffect, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            guard let player = player else { return }

            player.volume = volume
            player.play()

        } catch let error {
            print("Error playing sound effect: ", error.localizedDescription)
        }
    }
}

