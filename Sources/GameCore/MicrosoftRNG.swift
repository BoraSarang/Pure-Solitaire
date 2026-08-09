/// 마이크로소프트 FreeCell 셔플용 선형 합동 생성기 (LCG)
///
/// - state_{n+1} = (state_n * 214013 + 2531011) mod 2^31
/// - rand_n = state_n >> 16 (0..32767)
public struct MicrosoftRNG: Sendable {
    private var state: UInt64

    public init(seed: Int) {
        state = UInt64(seed & 0x7FFFFFFF)
    }

    public mutating func next() -> Int {
        state = (state &* 214013 &+ 2531011) & 0x7FFFFFFF
        return Int((state >> 16) & 0x7FFF)
    }
}
