//
//  TestCompletionSound.swift
//  Aura
//
//  Created by wamhrm on 18.11.2026.
//

import AVFoundation

enum TestCompletionSound {
    private static var player: AVAudioPlayer?

    static func play() {
        guard let url = Bundle.main.url(forResource: "TestCompletion", withExtension: "wav") else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)

        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = 0.45
        player.prepareToPlay()
        self.player = player
        player.play()
    }
}
