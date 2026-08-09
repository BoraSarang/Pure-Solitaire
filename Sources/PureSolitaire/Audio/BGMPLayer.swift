import AVFoundation
import AppKit

/// 배경음악(BGM) 재생 — 번들 bgm.wav 루프
@MainActor
final class BGMPLayer {
    static let shared = BGMPLayer()

    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private var volume: Float = 0.5

    /// BGM 시작 (이미 재생 중이면 무시)
    func start(volume: Double = 0.5) {
        self.volume = Float(max(0, min(1, volume)))
        if player == nil {
            guard let url = Bundle.main.url(forResource: "bgm", withExtension: "wav") else { return }
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
        }
        player?.volume = self.volume
        if !isPlaying {
            player?.play()
            isPlaying = true
        }
    }

    /// BGM 볼륨 변경 (재생 중 실시간 반영)
    func setVolume(_ v: Double) {
        volume = Float(max(0, min(1, v)))
        player?.volume = volume
    }

    /// BGM 중지 (위치 유지)
    func stop() {
        guard isPlaying else { return }
        player?.stop()
        isPlaying = false
    }
}