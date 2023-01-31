import Foundation
import Fx

struct BLEControls: Equatable {
	var bpm: Float
	var bits: Int16
}

struct BLEPattern: Equatable {
	var bits: UInt64
	var count: UInt8
	var options: UInt8
}

extension State {
	var blePattern: Quad<BLEPattern> { patterns.map(\.blePattern) }
}

extension PatternState {
	var blePattern: BLEPattern {
		BLEPattern(
			bits: isMuted ? 0 : (0..<pattern.rows)
				.map { row in pattern.rowBits(row) << (pattern.cols * row) }
				.reduce(0, |),
			count: UInt8(pattern.count),
			options: UInt8(options.dutyCycle.rawValue)
		)
	}
}

extension State {
	var bleControls: BLEControls {
		BLEControls(
			bpm: transport == .stopped ? 0 : bpm,
			bits: modify(shapes.map { 1 << $0.rawValue }.reduce(0, |)) {
				if transport == .playing { $0 |= 1 << 4 }
				if reset { $0 |= 1 << 5 }
				if changePattern { $0 |= 1 << 6 }
				if sendMIDI { $0 |= 1 << 7 }
			}
		)
	}
}

extension BLEPattern: CustomDebugStringConvertible {
	var debugDescription: String {
		(0..<64).map { $0 < count ? (bits & 1 << $0 != 0 ? "x" : "o") : "-" }.joined()
	}
}
