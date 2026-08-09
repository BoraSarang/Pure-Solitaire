import SwiftUI
import GameCore

/// 카드 소스 식별
enum CardSource: Equatable {
    case column(Int)
    case freeCell(Int)
    case home(Int)
    case waste
    case pyramid(Int)
    case triPeaks(Int)
}

/// 카드 목적지 식별
enum Destination: Equatable {
    case column(Int)
    case freeCell(Int)
    case home(Int)
    case waste
}
