import Foundation

struct BLEField: Equatable {
	var a: BLEPattern
	var b: BLEPattern
	var c: BLEPattern
	var d: BLEPattern
}

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

extension Field {
	var bleRepresentation: BLEField {
		BLEField(
			a: a.bleRepresentation,
			b: b.bleRepresentation,
			c: c.bleRepresentation,
			d: d.bleRepresentation
		)
	}
}

extension Pattern {
	var bleRepresentation: BLEPattern {
		BLEPattern(
			bits: isMuted ? 0 : (0..<rows)
				.map { row in rowBits(row) << (cols * row) }
				.reduce(0, |),
			count: UInt8(rows * cols),
			options: UInt8(options.dutyCycle.rawValue)
		)
	}
}