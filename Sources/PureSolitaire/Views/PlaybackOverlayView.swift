import SwiftUI
import GameCore

/// 자동 풀어 보기/내 이동 리플레이 재생 오버레이 — 진행률 + 일시정지/중단 + 속도 선택.
/// 재생 중 보드 조작을 잠그고 진행 상황을 표시한다. (T-214)
struct PlaybackOverlayView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings

    private var isActive: Bool {
        vm.isAutoSolving || vm.isReplaying
    }

    private var isPaused: Bool {
        vm.isAutoSolvePaused || vm.isReplayPaused
    }

    private var progress: Double {
        if vm.isAutoSolving { return vm.autoSolveProgress }
        return vm.replayProgress
    }

    private var title: String {
        if vm.isAutoSolving { return "자동 풀어 보기" }
        return "내 이동 리플레이"
    }

    private var fg: Color {
        settings.background == .white ? Color.black : Color.white
    }

    var body: some View {
        if isActive {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(title)
                        .font(.headline)
                    Spacer()
                    speedPicker
                    pauseResumeButton
                    cancelButton
                }
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 420)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(fg.opacity(0.25), lineWidth: 1)
            )
            .frame(maxWidth: 500)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var speedPicker: some View {
        Picker("속도", selection: $vm.autoSolveSpeed) {
            Text("빠름").tag(FreeCellViewModel.AutoSolveSpeed.fast)
            Text("보통").tag(FreeCellViewModel.AutoSolveSpeed.normal)
            Text("느림").tag(FreeCellViewModel.AutoSolveSpeed.slow)
        }
        .pickerStyle(.menu)
        .frame(width: 90)
        .onChange(of: vm.autoSolveSpeed) { _ in
            vm.updateAutoSolveSpeed(vm.autoSolveSpeed)
        }
    }

    private var pauseResumeButton: some View {
        Button {
            if vm.isAutoSolving {
                if vm.isAutoSolvePaused { vm.resumeAutoSolve() } else { vm.pauseAutoSolve() }
            } else if vm.isReplaying {
                if vm.isReplayPaused { vm.resumeReplay() } else { vm.pauseReplay() }
            }
        } label: {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help(isPaused ? "재개" : "일시정지")
        .keyboardShortcut(.space, modifiers: [])
    }

    private var cancelButton: some View {
        Button {
            if vm.isAutoSolving { vm.cancelAutoSolve() }
            if vm.isReplaying { vm.cancelReplay() }
        } label: {
            Image(systemName: "xmark")
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help("재생 중단")
        .keyboardShortcut(.escape, modifiers: [])
    }
}