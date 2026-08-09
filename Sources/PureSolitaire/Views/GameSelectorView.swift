import SwiftUI
import GameCore

/// 게임 선택 그리드 — `GameVariant.allCases`를 미니 보드 미리보기 카드로 3열 배치 (게임 추가 시 자동 확장)
struct GameSelectorView: View {
    @Binding var selection: GameVariant
    let boardColor: Color

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(GameVariant.allCases, id: \.self) { variant in
                    GameTile(
                        variant: variant,
                        isSelected: selection == variant,
                        boardColor: boardColor
                    ) {
                        selection = variant
                    }
                }
            }
            .padding(6)
        }
        .accessibilityLabel("게임 선택")
    }
}

/// 개별 게임 타일 — 미리보기 카드 + 게임명
private struct GameTile: View {
    let variant: GameVariant
    let isSelected: Bool
    let boardColor: Color
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        VStack(spacing: 6) {
            GamePreviewCard(variant: variant, isSelected: isSelected, boardColor: boardColor)
            Text(variant.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                .lineLimit(1)
        }
        .padding(6)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { action() }
        .onHover { hovered = $0 }
        .scaleEffect(hovered && !isSelected ? 1.04 : 1)
        .animation(.easeOut(duration: 0.15), value: hovered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(variant.displayName) 게임")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
