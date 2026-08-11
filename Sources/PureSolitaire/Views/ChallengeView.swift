import SwiftUI
import GameCore

/// 데일리 챌린지 시트 — 오늘 변형/시드/별점 목표 + 완료 상태 표시
struct ChallengeView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @Environment(\.dismiss) private var dismiss

    private let today = Date()

    private var variant: GameVariant {
        DailyChallenge.challengeVariant(for: today)
    }

    private var gameNumber: Int {
        DailyChallenge.gameNumber(for: today)
    }

    private var result: ChallengeStore.Result? {
        vm.challengeStore.todayResult(date: today)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("데일리 챌린지")
                .font(.title2.bold())
            Text(DateFormatter.localizedString(from: today, dateStyle: .medium, timeStyle: .none))
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Label(variant.displayName, systemImage: "rectangle.stack.fill")
                    .font(.title3.bold())
                Text("게임 \(gameNumber)")
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))

            // 별점 목표
            VStack(alignment: .leading, spacing: 8) {
                Text("별점 목표")
                    .font(.subheadline.bold())
                goalRow(index: 1, title: "승리", hint: "게임 클리어")
                goalRow(index: 2, title: "시간", hint: "\(Int(DailyChallenge.timeTarget(for: variant) / 60))분 이내")
                goalRow(index: 3, title: "이동 수", hint: "\(DailyChallenge.moveTarget(for: variant))회 이내")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))

            if let result {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { s in
                            Image(systemName: s <= result.stars ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(s <= result.stars ? Color.yellow : Color.secondary)
                        }
                    }
                    Text("오늘 챌린지 완료")
                        .font(.callout.bold())
                    Text("\(result.moves) 이동 · \(Int(result.seconds) / 60)분 \(Int(result.seconds) % 60)초")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.12)))
            }

            Button(vm.challengeStore.todayResult(date: today) == nil ? "챌린지 시작" : "다시 시도") {
                vm.startChallenge()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 380, height: 440)
    }

    private func goalRow(index: Int, title: String, hint: String) -> some View {
        let achieved = result?.stars ?? 0 >= index
        return HStack(spacing: 10) {
            Image(systemName: achieved ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(achieved ? Color.green : Color.secondary)
            Text("\(index)")
                .font(.caption.bold())
                .monospacedDigit()
                .frame(width: 16)
            Text(title)
            Spacer()
            Text(hint)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .font(.callout)
        .accessibilityLabel("\(index)번째 목표 \(title) \(hint)")
    }
}