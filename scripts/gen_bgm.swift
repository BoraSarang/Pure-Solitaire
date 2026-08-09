import AVFoundation
import Foundation

// BGM 톤 생성 스크립트
// 사용: swift scripts/gen_bgm.swift → resources/bgm.wav (잔잔한 아르페지오 루프)
// 간단한 사인 합성으로 16bit PCM WAV를 만든다 (번들 리소스로 내장)

let sampleRate: Double = 44100
let duration: Double = 12.0          // 12초 루프
let totalSamples = Int(sampleRate * duration)

// 아르페지오 패턴: C5 E5 G5 E5 (부드러운 어택/릴리즈)
let notes: [Double] = [523.25, 659.25, 783.99, 659.25]
let noteDuration: Double = 3.0
let baseAmplitude: Double = 0.12    // 낮은 볼륨 (배경음)

var samples = [Int16](repeating: 0, count: totalSamples)

func envelope(_ t: Double) -> Double {
    // 0.4s 페이드인/아웃으로 클릭 제거
    let fade: Double = 0.4
    if t < fade { return t / fade }
    let remain = noteDuration - t
    if remain < fade { return remain / fade }
    return 1
}

for i in 0..<totalSamples {
    let t = Double(i) / sampleRate
    let noteIndex = Int(t / noteDuration) % notes.count
    let noteT = t.truncatingRemainder(dividingBy: noteDuration)
    let freq = notes[noteIndex]
    // 기본 사인 + 배음(2nd harmonic)으로 따뜻한 톤
    let value = sin(2 * .pi * freq * t)
        + 0.25 * sin(4 * .pi * freq * t)
    let amp = baseAmplitude * envelope(noteT)
    let v = value * amp * 0.6
    let clamped = max(-1, min(1, v))
    samples[i] = Int16(clamped * Double(Int16.max))
}

// WAV 헤더 + PCM 데이터
let dataSize = totalSamples * 2
var wav = Data()
// RIFF 헤더
wav.append(contentsOf: Array("RIFF".utf8))
wav.append(withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Data($0) })
wav.append(contentsOf: Array("WAVE".utf8))
// fmt 서브청크
wav.append(contentsOf: Array("fmt ".utf8))
wav.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
wav.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })          // PCM
wav.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) })          // 모노
wav.append(withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) })
wav.append(withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) }) // byte rate
wav.append(withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) })          // block align
wav.append(withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) })         // bits
// data 서브청크
wav.append(contentsOf: Array("data".utf8))
wav.append(withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Data($0) })
for s in samples {
    wav.append(withUnsafeBytes(of: s.littleEndian) { Data($0) })
}

let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("resources", isDirectory: true)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let url = dir.appendingPathComponent("bgm.wav")
do {
    try wav.write(to: url)
    print("resources/bgm.wav 생성됨 (\(wav.count) bytes)")
} catch {
    fputs("BGM 저장 실패: \(error)\n", stderr)
    exit(1)
}
