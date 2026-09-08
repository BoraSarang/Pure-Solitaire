/// 실행 취소/다시 실행 스택 공용 저장소.
///
/// 각 게임은 자체 `Snapshot` 타입(전체 상태 복사)으로 인스턴스화한다.
/// 저장(Codable) 키 호환 때문에 게임 쪽 커스텀 Codable에서 `undoStack`/`redoStack` 배열을
/// 직접 직렬화하므로(`history.undoStack`/`history.redoStack` 접근), 이 타입 자체는 Codable이 아니다.
public struct UndoHistory<Snapshot: Equatable & Sendable>: Equatable, Sendable {
    public private(set) var undoStack: [Snapshot] = []
    public private(set) var redoStack: [Snapshot] = []

    public init() {}

    public init(undoStack: [Snapshot], redoStack: [Snapshot]) {
        self.undoStack = undoStack
        self.redoStack = redoStack
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// 이동 적용 전 상태를 undo 스택에 밀어넣고 redo 스택을 비운다.
    public mutating func record(_ snapshot: Snapshot) {
        undoStack.append(snapshot)
        redoStack.removeAll()
    }

    /// 실행 취소: 현재 상태를 redo 스택에 밀어놓고 이전 상태를 반환한다.
    /// 이전 상태가 없으면 nil.
    public mutating func popUndo(current: Snapshot) -> Snapshot? {
        guard let prev = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return prev
    }

    /// 다시 실행: 현재 상태를 undo 스택에 밀어놓고 다음 상태를 반환한다.
    /// 다음 상태가 없으면 nil.
    public mutating func popRedo(current: Snapshot) -> Snapshot? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }
}