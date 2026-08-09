import SwiftUI

/// 사용자 설정 (UserDefaults 영구 저장)
final class UserSettings: ObservableObject {
    enum CardStyle: String, CaseIterable, Identifiable {
        case classic = "클래식"
        case simple = "심플"
        var id: String { rawValue }
    }

    enum BackgroundStyle: String, CaseIterable, Identifiable {
        case green = "그린"
        case blue = "블루"
        case dark = "다크"
        case white = "화이트"
        var id: String { rawValue }
    }

    enum CardBack: String, CaseIterable, Identifiable {
        case classic = "클래식"
        case blue = "블루"
        case gold = "골드"
        var id: String { rawValue }

        /// 뒷면 패턴 색
        var tint: Color {
            switch self {
            case .classic: return Color(red: 0.15, green: 0.10, blue: 0.25)
            case .blue: return Color(red: 0.10, green: 0.25, blue: 0.45)
            case .gold: return Color(red: 0.55, green: 0.40, blue: 0.10)
            }
        }

        /// 뒷면 패턴 대비색
        var accent: Color {
            switch self {
            case .classic: return Color(red: 0.80, green: 0.75, blue: 0.95)
            case .blue: return Color(red: 0.60, green: 0.75, blue: 0.95)
            case .gold: return Color(red: 0.95, green: 0.85, blue: 0.55)
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
        }
    }

    /// 펠트(보드 배경) 위 텍스트/아이콘 기본색 — 화이트 배경이면 검정(가시성), 그 외 흰색
    var feltTextBase: Color {
        background == .white ? Color.black : Color.white
    }
}
