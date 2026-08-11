import SwiftUI
import GameCore

/// 업적 시트 — 배지 그리드 (잠금 해제 풀컬러 + 해제 날짜, 미해제 회색 + 조건)
struct AchievementsView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @Environment(\.dismiss) private var dismiss

    private var unlocked: Set<String> {
        vm.achievementStore.unlockedSet()
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("업적")
                .font(.title2.bold())
            Text("\(unlocked.count) / \(Achievement.all.count) 잠금 해제")
                .font(.callout)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(Achievement.all) { achievement in
                        achievementCell(achievement)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(24)
        .frame(width: 420, height: 480)
    }

    private func achievementCell(_ a: Achievement) -> some View {
        let isOpen = unlocked.contains(a.kind.rawValue)
        return VStack(spacing: 8) {
            Image(systemName: isOpen ? a.symbol : "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(isOpen ? .yellow : Color.secondary)
            Text(a.title)
                .font(.callout.bold())
                .multilineTextAlignment(.center)
            Text(a.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOpen ? Color.yellow.opacity(0.12) : Color.secondary.opacity(0.07))
        )
        .opacity(isOpen ? 1 : 0.55)
        .accessibilityLabel(isOpen ? "\(a.title) 잠금 해제" : "\(a.title), 잠김 — \(a.subtitle)")
    }
}