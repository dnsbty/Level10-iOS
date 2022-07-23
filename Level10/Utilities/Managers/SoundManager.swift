//
//  SoundManager.swift
//  Level10
//
//  Created by Dennis Beatty on 7/19/22.
//

import AVFoundation

enum SoundEffect: String {
    case buttonTap = "button-tap"
    case failure = "failure"
    case notify = "notify"
    case success = "success"
}

enum Volume: Float {
    case extraLow = 0.01
    case low = 0.05
    case medium = 0.1
    case high = 0.25
}

class SoundManager {
    static let shared = SoundManager()
    
    var player: AVAudioPlayer?
    
    private init() {}
    
    func playButtonTap(volume: Volume = .medium) {
        playSound(.buttonTap, volume: volume.rawValue)
    }
    
    func playFailure(volume: Volume = .medium) {
        playSound(.failure, volume: volume.rawValue)
    }
    
    func playNotify(volume: Volume = .medium) {
        playSound(.notify, volume: volume.rawValue, type: .wav)
    }
    
    func playSuccess(volume: Volume = .medium) {
        playSound(.success, volume: volume.rawValue)
    }
    
    private func playSound(_ sound: SoundEffect, volume: Float = 1.0, type: AVFileType = .mp3) {
        let fileExt = type == .wav ? "wav" : "mp3"
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: fileExt) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: type.rawValue)
            guard let player = player else { return }

            player.volume = volume
            player.play()

        } catch let error {
            print("Error playing sound effect: ", error.localizedDescription)
        }
    }
}

