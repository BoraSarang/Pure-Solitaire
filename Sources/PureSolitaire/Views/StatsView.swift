import SwiftUI
import GameCore

/// 통계 시트 — 상단 요약(전체/선택 게임 토글) + 게임별 요약 목록 (선택 시 상세 펼침)
/// `GameVariant.allCases`를 순회하므로 게임이 늘어나도 자동 확장.
struct StatsView: View {
    enum StatsMode {
        case all
        case selected
    }

    @EnvironmentObject private var vm: FreeCellViewModel
    @State private var selected: GameVariant?
    @State private var mode: StatsMode = .selected

    var body: some View {
        VStack(spacing: 12) {
            Text("통계")
                .font(.title2.bold())

            modePicker

            summaryCard

            Divider()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(GameVariant.allCases, id: \.self) { variant in
                        gameRow(variant)
                    }
                    if let sel = selected {
                        detailSection(for: sel)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 420, height: 560)
        .onAppear {
            selected = vm.variant
        }
    }

    /// 상단 요약 대상을 전체/선택 게임으로 전환
    private var modePicker: some View {
        Picker("요약 대상", selection: $mode) {
            Text("전체").tag(StatsMode.all)
            Text("선택").tag(StatsMode.selected)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 220)
        .accessibilityLabel("요약 대상")
    }

    /// 선택 모드면 해당 게임 요약, 아니면 전체 합계
    @ViewBuilder
    private var summaryCard: some View {
        if mode == .selected, let v = selected {
            variantSummary(v)
        } else {
            overallSummary
        }
    }

    /// 전체 합계 요약
    private var overallSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전체")
                .font(.headline)
            statRow(label: "총 게임", value: "\(vm.allTotalGames)")
            statRow(label: "승리", value: "\(vm.allWins)")
            statRow(label: "승률", value: String(format: "%.1f%%", vm.allWinRate))
            statRow(label: "현재 연승", value: "\(vm.allCurrentStreak)")
            statRow(label: "최고 연승", value: "\(vm.allBestStreak)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
    }

    /// 선택된 게임의 요약 (최단 승리 포함)
    private func variantSummary(_ variant: GameVariant) -> some View {
        let e = vm.stats(for: variant)
        return VStack(alignment: .leading, spacing: 8) {
            Text(variant.displayName)
                .font(.headline)
            statRow(label: "총 게임", value: "\(e.totalGames)")
            statRow(label: "승리", value: "\(e.wins)")
            statRow(label: "승률", value: String(format: "%.1f%%", e.winRate))
            statRow(label: "현재 연승", value: "\(e.currentStreak)")
            statRow(label: "최고 연승", value: "\(e.bestStreak)")
            if let t = e.bestTime {
                statRow(label: "최단 승리", value: formatTime(t))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
    }

    /// 게임별 요약 행 — 탭하면 선택/해제 (상세 펼침)
    private func gameRow(_ variant: GameVariant) -> some View {
        let e = vm.stats(for: variant)
        let isSelected = selected == variant
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selected = isSelected ? nil : variant
            }
        } label: {
            HStack {
                Text(variant.displayName)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(e.totalGames)판")
                    .foregroundStyle(.secondary)
                Text("승률 \(String(format: "%.0f%%", e.winRate))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(variant.displayName), 총 \(e.totalGames)판, 승률 \(Int(e.winRate))%")
    }

    /// 선택된 게임의 상세 (최단 승리 + 최근 승리 10건)
    private func detailSection(for variant: GameVariant) -> some View {
        let e = vm.stats(for: variant)
        let records = vm.winRecords(for: variant)
        return VStack(alignment: .leading, spacing: 8) {
            if let t = e.bestTime {
                statRow(label: "최단 승리", value: formatTime(t))
            }
            if !records.isEmpty {
                Text("최근 승리")
                    .font(.subheadline.bold())
                    .padding(.top, 4)
                ForEach(records.prefix(10)) { record in
                    HStack {
                        Text("게임 \(record.gameNumber)")
                            .monospacedDigit()
                        Spacer()
                        Text(formatTime(record.seconds))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return m > 0 ? "\(m)분 \(s)초" : "\(s)초"
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}
