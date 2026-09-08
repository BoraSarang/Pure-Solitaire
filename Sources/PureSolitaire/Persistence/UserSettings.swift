import SwiftUI
import AppKit
import GameCore

/// 사용자 설정 (UserDefaults 영구 저장)
final class UserSettings: ObservableObject {
    enum BackgroundStyle: String, CaseIterable, Identifiable {
        case green = "그린"
        case blue = "블루"
        case dark = "다크"
        case white = "화이트"
        case custom = "커스텀"
        var id: String { rawValue }
    }

    enum CardStyle: String, CaseIterable, Identifiable {
        case classic = "클래식"
        case simple = "심플"
        case retro = "레트로"
        case deep = "딥"
        var id: String { rawValue }
    }

    enum CardBack: String, CaseIterable, Identifiable {
        case classic = "클래식"
        case blue = "블루"
        case gold = "골드"
        case ocean = "오션"
        case forest = "숲"
        var id: String { rawValue }

        /// 뒷면 패턴 색
        var tint: Color {
            switch self {
            case .classic: return Color(red: 0.15, green: 0.10, blue: 0.25)
            case .blue: return Color(red: 0.10, green: 0.25, blue: 0.45)
            case .gold: return Color(red: 0.55, green: 0.40, blue: 0.10)
            case .ocean: return Color(red: 0.05, green: 0.35, blue: 0.45)
            case .forest: return Color(red: 0.10, green: 0.35, blue: 0.20)
            }
        }

        /// 뒷면 패턴 대비색
        var accent: Color {
            switch self {
            case .classic: return Color(red: 0.80, green: 0.75, blue: 0.95)
            case .blue: return Color(red: 0.60, green: 0.75, blue: 0.95)
            case .gold: return Color(red: 0.95, green: 0.85, blue: 0.55)
            case .ocean: return Color(red: 0.65, green: 0.90, blue: 0.95)
            case .forest: return Color(red: 0.70, green: 0.92, blue: 0.60)
            }
        }
    }

    @AppStorage("settings.cardStyle") var cardStyleRaw = CardStyle.classic.rawValue
    @AppStorage("settings.background") var backgroundRaw = BackgroundStyle.green.rawValue
    @AppStorage("settings.autoPlayEnabled") var autoPlayEnabled = true
    @AppStorage("settings.autoFinishEnabled") var autoFinishEnabled = true
    @AppStorage("settings.animationSpeed") var animationSpeed = 0.6
    @AppStorage("settings.soundEnabled") var soundEnabled = true
    @AppStorage("settings.bgmEnabled") var bgmEnabled = false
    @AppStorage("settings.boardScale") var boardScale = 1.0
    @AppStorage("settings.soundVolume") var soundVolume = 1.0
    @AppStorage("settings.bgmVolume") var bgmVolume = 0.5
    @AppStorage("settings.cardBackRaw") var cardBackRaw = CardBack.classic.rawValue
    /// 게임 모드 (일반/확장) — 기본 일반 (T-245)
    @AppStorage("settings.gameMode") var gameModeRaw = GameMode.standard.rawValue
    /// 커스텀 배경 이미지 파일 경로 (선택 시 Application Support에 복사)
    @AppStorage("settings.customBackgroundPath") var customBackgroundPath = ""

    var cardStyle: CardStyle {
        get { CardStyle(rawValue: cardStyleRaw) ?? .classic }
        set { cardStyleRaw = newValue.rawValue }
    }

    var background: BackgroundStyle {
        get { BackgroundStyle(rawValue: backgroundRaw) ?? .green }
        set { backgroundRaw = newValue.rawValue }
    }

    var cardBack: CardBack {
        get { CardBack(rawValue: cardBackRaw) ?? .classic }
        set { cardBackRaw = newValue.rawValue }
    }

    /// 게임 모드 — UserSettings는 앱 타깃이라 GameCore의 GameMode 직접 참조 (T-245)
    var gameMode: GameMode {
        get { GameMode(rawValue: gameModeRaw) ?? .standard }
        set { gameModeRaw = newValue.rawValue }
    }

    func backgroundColor(for style: BackgroundStyle) -> Color {
        Self.color(for: style)
    }

    /// 배경 스타일 색 토큰 — 설정 미리보기/보드 렌더 공용 (static, 인스턴스 불필요)
    static func color(for style: BackgroundStyle) -> Color {
        switch style {
        case .green: Color(red: 0.02, green: 0.38, blue: 0.20)
        case .blue: Color(red: 0.08, green: 0.35, blue: 0.55)
        case .dark: Color(red: 0.13, green: 0.14, blue: 0.17)
        case .white: Color(red: 0.93, green: 0.93, blue: 0.90)
        case .custom: Color(red: 0.08, green: 0.08, blue: 0.10)
        }
    }

    /// 펠트(보드 배경) 위 텍스트/아이콘 기본색 — 화이트 배경이면 검정(가시성), 그 외 흰색
    var feltTextBase: Color {
        background == .white ? Color.black : Color.white
    }

    /// 커스텀 배경 이미지 (경로에서 로드, 없으면 nil) — 렌더/미리보기 공용
    var customBackgroundImage: NSImage? {
        guard background == .custom, !customBackgroundPath.isEmpty else { return nil }
        guard FileManager.default.fileExists(atPath: customBackgroundPath) else { return nil }
        return NSImage(contentsOfFile: customBackgroundPath)
    }

    /// Application Support의 커스텀 배경 이미지 파일 경로 (없으면 생성)
    static func customBackgroundFileURL() -> URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = appSupport.appendingPathComponent("Pure Solitaire", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom-background.png")
    }

    /// 선택한 이미지를 커스텀 배경으로 저장 + 경로 반영
    @discardableResult
    func setCustomBackground(from url: URL) -> Bool {
        guard let target = Self.customBackgroundFileURL() else { return false }
        guard let image = NSImage(contentsOf: url) else { return false }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: target, options: .atomic)
            customBackgroundPath = target.path
            background = .custom
            return true
        } catch {
            return false
        }
    }

    /// 커스텀 배경 제거 (파일 삭제 + 경로 초기화)
    func removeCustomBackground() {
        if !customBackgroundPath.isEmpty {
            try? FileManager.default.removeItem(atPath: customBackgroundPath)
        }
        customBackgroundPath = ""
        if background == .custom {
            background = .green
        }
    }
}
