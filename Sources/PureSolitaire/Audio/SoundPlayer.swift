import AVFoundation
#if os(macOS)
import AppKit
#endif

/// 효과음 재생 (시스템 사운드, VoiceOver 방해 없음)
@MainActor
final class SoundPlayer {
    /// 사운드 종류
    enum Effect {
        case move
        case home
        case win
    }

    static let shared = SoundPlayer()

    private var moveSound: NSSound?
    private var homeSound: NSSound?
    private var winSound: NSSound?

    /// 사운드 장치 초기화 (지연 로드)
    private func prepare() {
        if moveSound == nil { moveSound = NSSound(named: "Glass") }
        if homeSound == nil { homeSound = NSSound(named: "Tink") }
        if winSound == nil { winSound = NSSound(named: "Hero") }
    }

    /// 효과음 재생 (enabled가 false면 무음, volume 0~1)
    func play(_ effect: Effect, enabled: Bool, volume: Double = 1.0) {
        guard enabled else { return }
        prepare()
        guard let sound: NSSound = {
            switch effect {
            case .move: return moveSound
            case .home: return homeSound
            case .win: return winSound
            }
        }() else { return }
        sound.volume = Float(max(0, min(1, volume)))
        if !sound.isPlaying { sound.play() }
    }

    /// 승리 팡파레 — Hero + 짧은 Tink/Glass 시퀀스
    func playWinSequence(volume: Double = 1.0) {
        guard volume > 0 else { return }
        prepare()
        let v = Float(max(0, min(1, volume)))
        if let hero = winSound {
            hero.volume = v
            hero.play()
        }
        // Hero 재생 후 짧게 Tink → Glass 연주 (메인 스레드 지연)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [homeSound] in
            homeSound?.volume = v * 0.8
            homeSound?.play()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [moveSound] in
            moveSound?.volume = v * 0.7
            moveSound?.play()
        }
    }
}