import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings
    @State private var windowTitle = "Pure Solitaire"

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if vm.showingHome {
                    HomeView(onStartGame: { vm.showingHome = false })
                        .transition(.opacity)
                } else {
                    gameScreen
                        .transition(.opacity)
                }
            }
            if let message = vm.message {
                MessageBanner(text: message)
                    .padding(.bottom, 14)
                    .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
            }
            if vm.currentIsWon {
                ConfettiView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                WinBanner(gameNumber: vm.currentGameNumber, score: vm.finalScore)
                    .padding(.bottom, 90)
                    .transition(.scale.combined(with: .opacity))
            }
            if vm.showNextGameButton {
                Button("다음 게임") { vm.nextGameAfterWin() }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 14)
                    .transition(AnyTransition.scale.combined(with: .opacity))
            }
            if vm.isSearchingWinnable {
                // 승리 보장 번호 탐색 중 로딩 표시 (T-239: 프리즈 대신 진행 표시)
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("풀리는 번호를 찾는 중…")
                        .font(.callout)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.68)))
                .foregroundStyle(.white)
                .padding(.bottom, 56)
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(BackgroundLayer(settings: settings))
        .background(WindowAccessor { window in
            window.setFrameAutosaveName("PureSolitaireMainWindow")
        })
        .animation(.easeInOut(duration: 0.3), value: vm.message)
        .animation(.easeInOut(duration: 0.3), value: vm.showNextGameButton)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: vm.currentIsWon)
        .animation(.easeInOut(duration: 0.2), value: vm.showingHome)
        .confirmationDialog(
            "새 게임을 시작할까요?",
            isPresented: $vm.showingNewGameConfirmation,
            titleVisibility: .visible
        ) {
            Button("새 게임 시작") { vm.confirmNewGame() }
            Button("취소", role: .cancel) { vm.cancelNewGame() }
        } message: {
            Text("현재 진행 중인 게임(이동 \(vm.currentMoveCount)회)이 사라집니다.")
        }
        .sheet(isPresented: $vm.showingGameNumber) {
            GameNumberSheet()
        }
        .sheet(isPresented: $vm.showingStats) {
            StatsView()
        }
        .sheet(isPresented: $vm.showingChallenge) {
            ChallengeView()
        }
        .sheet(isPresented: $vm.showingAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $vm.showingSettings) {
            SettingsView()
        }
        .navigationTitle(windowTitle)
        .focusable()
        .onAppear {
            updateWindowTitle()
        }
        .onChange(of: vm.currentGameNumber) { _ in
            updateWindowTitle()
        }
        .onChange(of: vm.variant) { _ in
            updateWindowTitle()
        }
        .onChange(of: vm.showingHome) { _ in
            updateWindowTitle()
        }
        .onChange(of: vm.gameSessionID) { _ in
            // 새 게임 확정 시 홈→게임 자동 전환 (T-234: 취소 시 홈 유지)
            vm.showingHome = false
        }
    }

    /// 게임 화면 — 사이드바 + 보드
    private var gameScreen: some View {
        HStack(spacing: 0) {
            SideBarView(side: .left)
                .frame(maxHeight: .infinity, alignment: .top)
            GameBoardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            SideBarView(side: .right)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func updateWindowTitle() {
        windowTitle = vm.showingHome ? "Pure Solitaire" : "Pure Solitaire — \(vm.variantDisplayName) \(vm.currentGameNumber)"
    }
}

struct MessageBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.black.opacity(0.68)))
            .shadow(radius: 4)
    }
}

/// 승리 배너 — 에모지와 글자를 분리해 타입체크 부하 분산
struct WinBanner: View {
    let gameNumber: Int
    let score: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("🎉 승리!")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 4)
            Text("게임 \(gameNumber) 클리어")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text("최종 점수 \(score)점")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.45)))
    }
}
