import SwiftUI
import AppKit
import GameCore

/// 보드/창 공용 배경 — 커스텀 배경이면 이미지, 아니면 색상
struct BackgroundLayer: View {
    let settings: UserSettings

    var body: some View {
        if settings.background == .custom,
           let image = settings.customBackgroundImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            UserSettings.color(for: settings.background)
        }
    }
}

/// 카드 뒷면 패턴 아트워크 — `CardView.backView`와 설정 미리보기 공용 (tint/accent 토큰 재사용)
struct CardBackArtwork: View {
    let tint: Color
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.09)
                    .fill(tint)
                RoundedRectangle(cornerRadius: w * 0.09)
                    .stroke(accent.opacity(0.6), lineWidth: 1.5)
                    .padding(2)
                DiamondShape()
                    .stroke(accent.opacity(0.7), lineWidth: 1)
                    .frame(width: w * 0.45, height: h * 0.45)
                DiamondShape()
                    .stroke(accent.opacity(0.4), lineWidth: 1)
                    .frame(width: w * 0.65, height: h * 0.65)
                Circle()
                    .fill(accent.opacity(0.55))
                    .frame(width: w * 0.14, height: w * 0.14)
            }
        }
    }
}

/// 카드 스타일 미리보기용 미니 카드 앞면 — `CardView`와 동일 색/폰트(serif/rounded) 재현
struct MiniCardFaceView: View {
    let style: UserSettings.CardStyle

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.09)
                    .fill(background)
                RoundedRectangle(cornerRadius: w * 0.09)
                    .stroke(borderColor, lineWidth: 1.2)
                VStack(alignment: .leading, spacing: 1) {
                    Text("A")
                        .font(.system(size: w * 0.28, weight: .bold, design: fontDesign))
                        .foregroundStyle(faceColor)
                        .lineLimit(1)
                    SpadeShape()
                        .fill(faceColor)
                        .frame(width: w * 0.16, height: w * 0.16)
                }
                .frame(width: w * 0.26, alignment: .leading)
                .position(x: w * 0.22, y: w * 0.22)
            }
        }
        .aspectRatio(0.7, contentMode: .fit)
    }

    private var fontDesign: Font.Design {
        switch style {
        case .classic, .retro: return .serif
        case .simple, .deep: return .rounded
        }
    }

    private var background: Color {
        switch style {
        case .classic:
            Color.white
        case .simple:
            Color(red: 0.92, green: 0.93, blue: 0.90)
        case .retro:
            Color(red: 0.98, green: 0.94, blue: 0.86)
        case .deep:
            Color(red: 0.18, green: 0.20, blue: 0.28)
        }
    }

    private var borderColor: Color {
        switch style {
        case .classic:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .simple:
            return Color(red: 0.70, green: 0.72, blue: 0.68)
        case .retro:
            return Color(red: 0.55, green: 0.40, blue: 0.25)
        case .deep:
            return Color(red: 0.55, green: 0.60, blue: 0.75)
        }
    }

    private var faceColor: Color {
        switch style {
        case .deep:
            Color(red: 0.88, green: 0.90, blue: 0.95)
        default:
            Color(red: 0.12, green: 0.12, blue: 0.12)
        }
    }
}

/// 탭 가능한 미리보기 선택 셀 — 선택 시 파랑 테두리 + 파랑 라벨
private struct PreviewCell<Content: View>: View {
    let title: String
    let isSelected: Bool
    let content: Content
    let action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            content
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color.secondary.opacity(0.35),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                .lineLimit(1)
        }
        .padding(4)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { action() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 카드 스타일 선택 — 미니 카드 앞면 미리보기
struct CardStylePicker: View {
    @Binding var selection: UserSettings.CardStyle

    var body: some View {
        HStack(spacing: 14) {
            ForEach(UserSettings.CardStyle.allCases) { style in
                PreviewCell(
                    title: style.rawValue,
                    isSelected: selection == style,
                    content: MiniCardFaceView(style: style)
                        .frame(width: 50, height: 72)
                ) {
                    selection = style
                }
            }
        }
    }
}

/// 배경 선택 — 실제 색 스와치(또는 커스텀 이미지) 미리보기
struct BackgroundStylePicker: View {
    @Binding var selection: UserSettings.BackgroundStyle
    let settings: UserSettings

    var body: some View {
        HStack(spacing: 14) {
            ForEach(UserSettings.BackgroundStyle.allCases) { style in
                PreviewCell(
                    title: style.rawValue,
                    isSelected: selection == style,
                    content: RoundedRectangle(cornerRadius: 8)
                        .fill(UserSettings.color(for: style))
                        .frame(width: 72, height: 56)
                        .overlay(
                            Group {
                                if style == .custom {
                                    if let image = settings.customBackgroundImage {
                                        Image(nsImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.white.opacity(0.9))
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                }
                            }
                        )
                ) {
                    selection = style
                }
            }
        }
    }
}

/// 카드 뒷면 선택 — 미니 뒷면 패턴 미리보기
struct CardBackPicker: View {
    @Binding var selection: UserSettings.CardBack

    var body: some View {
        HStack(spacing: 14) {
            ForEach(UserSettings.CardBack.allCases) { back in
                PreviewCell(
                    title: back.rawValue,
                    isSelected: selection == back,
                    content: CardBackArtwork(tint: back.tint, accent: back.accent)
                        .frame(width: 50, height: 72)
                ) {
                    selection = back
                }
            }
        }
    }
}
