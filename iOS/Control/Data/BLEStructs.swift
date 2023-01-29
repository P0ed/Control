import Foundation
import Fx

struct BLEPattern: Equatable {
	var bits: UInt64
	var count: UInt8
	var options: UInt8
}

extension BLEPattern: CustomDebugStringConvertible {
	var debugDescription: String {
		(0..<64).map { $0 < count ? (bits & 1 << $0 != 0 ? "x" : "o") : "-" }.joined()
	}
}

extension PatternState {
	var bleRepresentation: BLEPattern {
		BLEPattern(
			bits: isMuted ? 0 : (0..<pattern.rows)
				.map { row in pattern.rowBits(row) << pattern.count }
				.reduce(0, |),
			count: UInt8(pattern.count),
			options: UInt8(options.dutyCycle.rawValue)
		)
	}
}

struct BLEControls: OptionSet {
	var rawValue: Int16

	static let run = BLEControls(rawValue: 1 << 0)
	static let reset = BLEControls(rawValue: 1 << 1)
	static let changePattern = BLEControls(rawValue: 1 << 2)

	mutating func set(_ control: BLEControls, pressed: Bool) {
		if pressed { insert(control) } else { remove(control) }
	}
}

extension State {
	var bleControls: BLEControls {
		modify([]) {
			if isPlaying { $0.insert(.run) }
			if changePattern { $0.insert(.changePattern) }
		}
	}
}

struct BLEClock: Hashable {
	var bpm: Float
	var swing: Float
}

extension State {
	var bleClock: BLEClock { BLEClock(bpm: bpm, swing: swing) }
}
