import SwiftUI
import GameCore

/// 데일리 챌린지 시트 — 3개월 달력 + 날짜별 9판 목록 + 월 통계/배지 (T-218)
struct ChallengeView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var focusedMonth = CalendarMonth.current()

    private var calendar: Calendar { .current }

    /// 오늘 날짜 (달력 강조용)
    private var today: Date { Date() }

    /// 선택 날짜의 9판
    private var deals: [DailyChallenge.Deal] {
        DailyChallenge.deals(for: selectedDate, calendar: calendar)
    }

    /// 선택 날짜의 완료 기록
    private var selectedDay: ChallengeStore.DayResult? {
        vm.challengeStore.dayResult(for: ChallengeStore.dateKey(for: selectedDate, calendar: calendar))
    }

    /// 선택 날짜가 미래인지 — 시각 비교가 아닌 날짜 키 문자열 비교 (T-232: 오전 오늘 비활성화 버그 수정)
    private var isFutureSelected: Bool {
        ChallengeStore.dateKey(for: selectedDate, calendar: calendar)
            > ChallengeStore.dateKey(for: today, calendar: calendar)
    }

    /// 3개월 목록 (이전/현재/다음)
    private var months: [CalendarMonth] {
        CalendarMonth.rangeAround(focusedMonth)
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            Divider()
            monthNavigation
            calendarGrid
            Divider()
            dealList
            summaryFooter
        }
        .padding(18)
        .frame(width: 460, height: 620)
        .onAppear {
            // 선택 날짜의 판별 난이도 백그라운드 측정 시작
            vm.ensureDealDifficulties(for: deals)
        }
        .onChange(of: selectedDate) { _ in
            vm.ensureDealDifficulties(for: deals)
        }
        .onDisappear {
            vm.cancelDealDifficultyMeasurement()
        }
    }

    // MARK: - 상단 헤더

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("데일리 챌린지")
                    .font(.title2.bold())
                Text("하루 9판 · 별점으로 완료율 집계")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // 월 배지 (D) — 완료율 기반
            if summary(for: focusedMonth).badge != .none {
                Label(summary(for: focusedMonth).badge.displayName, systemImage: badgeSymbol(summary(for: focusedMonth).badge))
                    .font(.caption.bold())
                    .foregroundStyle(badgeColor(summary(for: focusedMonth).badge))
            }
        }
    }

    private func badgeSymbol(_ badge: MonthBadge) -> String {
        switch badge {
        case .bronze: "medal"
        case .silver: "medal.fill"
        case .gold: "trophy.fill"
        case .diamond: "crown.fill"
        case .none: "circle"
        }
    }

    private func badgeColor(_ badge: MonthBadge) -> Color {
        switch badge {
        case .bronze: .brown
        case .silver: .gray
        case .gold: .yellow
        case .diamond: .cyan
        case .none: .secondary
        }
    }

    // MARK: - 월 네비게이션 (◀ ▶)

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation { focusedMonth = focusedMonth.previousMonth }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            Spacer()
            Text("\(focusedMonth.year)년 \(focusedMonth.month)월")
                .font(.headline)
                .monospacedDigit()
            Spacer()
            Button {
                withAnimation { focusedMonth = focusedMonth.nextMonth }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 달력 그리드

    private var calendarGrid: some View {
        VStack(spacing: 6) {
            // 요일 헤더 (일~토)
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            // 날짜 셀 (첫 주 앞부분 빈 셀)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(0..<focusedMonth.firstWeekday(), id: \.self) { _ in
                    Color.clear.frame(height: 34)
                }
                ForEach(1...focusedMonth.dayCount(), id: \.self) { day in
                    dayCell(day)
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.shortWeekdaySymbols.map { $0.prefix(1).uppercased() }
    }

    private func dayCell(_ day: Int) -> some View {
        let date = focusedMonth.date(day: day)
        let key = ChallengeStore.dateKey(for: date, calendar: calendar)
        let dayResult = vm.challengeStore.dayResult(for: key)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        return Button {
            selectedDate = date
            if !focusedMonth.contains(selectedDate) {
                focusedMonth = CalendarMonth.current(date: selectedDate)
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(isToday ? .primary : .secondary)
                // 완료 별 (최대 3개 축약)
                Text(starSummary(dayResult))
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundFor(isToday: isToday, isSelected: isSelected, hasResult: dayResult != nil))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(focusedMonth.month)월 \(day)일, \(starSummary(dayResult))")
    }

    private func starSummary(_ dayResult: ChallengeStore.DayResult?) -> String {
        guard let dayResult else { return "" }
        return String(repeating: "★", count: min(dayResult.totalStars, 3))
    }

    private func backgroundFor(isToday: Bool, isSelected: Bool, hasResult: Bool) -> Color {
        if isSelected { return Color.accentColor.opacity(0.18) }
        if hasResult { return Color.green.opacity(0.14) }
        if isToday { return Color.secondary.opacity(0.12) }
        return Color.clear
    }

    // MARK: - 9판 목록

    private var dealList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(selectedDateLabel)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(selectedDay?.completedCount ?? 0)/\(deals.count) 판 · ★ \(selectedDay?.totalStars ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(deals.indices, id: \.self) { idx in
                        dealRow(idx)
                    }
                }
            }
        }
    }

    private var selectedDateLabel: String {
        DateFormatter.localizedString(from: selectedDate, dateStyle: .medium, timeStyle: .none)
    }

    private func dealRow(_ index: Int) -> some View {
        let deal = deals[index]
        let recorded = selectedDay?.deals.first(where: { $0.variantRaw == deal.variant.rawValue && $0.number == deal.number })
        let difficulty = vm.cachedDifficulty(for: deal)
        return Button {
            vm.startChallenge(deal: deal)
            // T-236: 확인 필요 시 시트 유지 (다이얼로그에서 확정/취소), 즉시 시작만 닫기
            if !vm.needsNewGameConfirmation {
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Label(deal.variant.displayName, systemImage: variantIcon(deal.variant))
                    .font(.callout)
                Spacer()
                // 난이도 태그 (T-219)
                if let difficulty {
                    difficultyTag(difficulty)
                }
                Text("게임 \(deal.number)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                stars(recorded?.stars ?? 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(recorded != nil ? Color.green.opacity(0.12) : Color.secondary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .disabled(isFutureSelected)  // 미래 날짜는 비활성
        .opacity(isFutureSelected ? 0.45 : 1)
    }

    /// 난이도 태그 (쉬움/보통/어려움/미측정)
    private func difficultyTag(_ difficulty: Difficulty) -> some View {
        let (text, color) = difficultyTagContent(difficulty)
        return Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundStyle(color)
            .accessibilityLabel("난이도 \(text)")
    }

    private func difficultyTagContent(_ difficulty: Difficulty) -> (String, Color) {
        switch difficulty {
        case .easy: ("쉬움", .green)
        case .medium: ("보통", .orange)
        case .hard: ("어려움", .red)
        case .unmeasured: ("미측정", .gray)
        }
    }

    private func variantIcon(_ variant: GameVariant) -> String {
        switch variant {
        case .freecell, .bakersGame, .seaTower, .superFreeCell: "square.grid.3x3.fill"
        case .klondike, .yukon: "square.stack.fill"
        case .spider, .fortyThieves: "square.stack.3d.up.fill"
        case .scorpion: "scissors"
        case .golf, .pyramid, .triPeaks: "triangle.fill"
        }
    }

    private func stars(_ count: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...3, id: \.self) { s in
                Image(systemName: s <= count ? "star.fill" : "star")
                    .font(.system(size: 9))
                    .foregroundStyle(s <= count ? Color.yellow : Color.secondary)
            }
        }
    }

    // MARK: - 월 통계 하단

    private var summaryFooter: some View {
        let summary = summary(for: focusedMonth)
        return HStack(spacing: 14) {
            statCell(title: "완료", value: "\(summary.completedCount)/\(summary.totalCount)")
            statCell(title: "별", value: "\(summary.totalStars)/\(summary.maxStars)")
            statCell(title: "완료율", value: String(format: "%d%%", Int(summary.completionRate * 100)))
            Spacer()
            Button("오늘") {
                selectedDate = today
                focusedMonth = CalendarMonth.current()
            }
            .buttonStyle(.bordered)
        }
        .font(.caption)
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func summary(for month: CalendarMonth) -> MonthSummary {
        let keys = (1...month.dayCount()).map { ChallengeStore.dateKey(for: month.date(day: $0), calendar: calendar) }
        let results = keys.map { vm.challengeStore.dayResult(for: $0) }
        return MonthSummary(month: month, results: results)
    }
}