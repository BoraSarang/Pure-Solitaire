import Foundation
import GameCore

/// 변형별 옵션 선택값 저장 (UserDefaults 영구 저장)
/// 키 형식: `gameOptions.{variant.rawValue}.{optionID}` → 선택된 choice.id
final class GameOptionsStore {
    private let defaults = UserDefaults.standard

    private static func key(variant: GameVariant, optionID: String) -> String {
        "gameOptions.\(variant.rawValue).\(optionID)"
    }

    /// 저장된 선택지 id (없으면 첫 번째 선택지 기본)
    func selectedID(for variant: GameVariant, option: GameOption) -> String {
        defaults.string(forKey: Self.key(variant: variant, optionID: option.id))
            ?? option.choices.first?.id ?? ""
    }

    func setSelectedID(_ id: String, for variant: GameVariant, optionID: String) {
        defaults.set(id, forKey: Self.key(variant: variant, optionID: optionID))
    }

    func clearAll() {
        for variant in GameVariant.allCases {
            for option in variant.optionDefinitions {
                defaults.removeObject(forKey: Self.key(variant: variant, optionID: option.id))
            }
        }
    }
}
