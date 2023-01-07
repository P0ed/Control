import Foundation

struct Field: Codable {
	var a: Pattern
	var b: Pattern
	var c: Pattern
	var d: Pattern
}

extension Field {

	static let empty = Field(a: .empty, b: .empty, c: .empty, d: .empty)

	subscript(_ idx: Int) -> Pattern {
		get {
			switch idx % 4 {
			case 0: return a
			case 1: return b
			case 2: return c
			case 3: return d
			default: fatalError()
			}
		}
		set {
			switch idx % 4 {
			case 0: a = newValue
			case 1: b = newValue
			case 2: c = newValue
			case 3: d = newValue
			default: fatalError()
			}
		}
	}

	var all: [Pattern] { [a, b, c, d] }

	var bleRepresentation: BLEField {
		BLEField(
			a: a.bleRepresentation,
			b: b.bleRepresentation,
			c: c.bleRepresentation,
			d: d.bleRepresentation
		)
	}
}

struct Pattern: MutableCollection, RandomAccessCollection, Codable {
	var rows: Int
	var cols: Int
	var bits: UInt64

	var startIndex: Int { 0 }
	var endIndex: Int { Int(rows * cols) }
	func index(after i: Int) -> Int { (i + 1) % (rows * cols) }

	subscript(position: Int) -> Bool {
		get { bits & 1 << position != 0 }
		set { bits = newValue ? bits | 1 << position : bits & ~(1 << position) }
	}
}

extension Pattern {

	init(bits: UInt16) {
		self = Pattern(
			rows: 4,
			cols: 4,
			bits: (0..<4)
				.map { $0 * 4 }
				.map { offset in (Self.mask(range: offset..<(offset + 4)) & UInt64(bits)) << offset }
				.reduce(0 as UInt64, |)
		)
	}
	init(bits: UInt64) { self = Pattern(rows: 8, cols: 8, bits: bits) }

	mutating func shift(_ steps: Int, range: Range<Int>) {
		let rangeMask = Self.mask(range: range)
		let shiftedMask = (rangeMask << steps) & rangeMask
		let sign = (steps > 0 ? 1 as Int : -1 as Int)

		let lhs = (bits << steps) & shiftedMask
		let rhs = (bits >> (sign * (range.count - abs(steps)))) & ~shiftedMask
		let rotatedBits = lhs | rhs
		bits = (rotatedBits & rangeMask) | (bits & ~rangeMask)
	}

	mutating func shiftRows(_ steps: Int) {
		shift(8 * steps, range: 0..<(rows * 8))
	}
	mutating func shiftCols(_ steps: Int) {
		bits = (0..<rows)
			.map { $0 * 8 }
			.map { offset in
				modify(self) { $0.shift(steps, range: offset..<(offset + cols)) }.bits & Self.mask(range: offset..<(offset + cols))
			}
			.reduce(0 as UInt64, |)
	}

	mutating func shift(_ shift: Int = 1, direction: Direction) {
		switch direction {
		case .up: shiftRows(-shift)
		case .right: shiftCols(shift)
		case .down: shiftRows(shift)
		case .left: shiftCols(-shift)
		}
	}

	mutating func modifySize(subtract: Bool, direction: Direction) {
		if direction == .left || direction == .right {
			guard cols > 1 && subtract || cols < 8 && !subtract else { return }
			if direction == .left { shift(direction: subtract ? .left : .right) }
			cols += subtract ? -1 : 1
		} else {
			guard rows > 1 && subtract || rows < 8 && !subtract else { return }
			if direction == .up { shift(direction: subtract ? .up : .down) }
			rows += subtract ? -1 : 1
		}
	}

	var bleRepresentation: BLEPattern { BLEPattern(count: UInt8(rows * cols), bits: bits) }
}

private extension Pattern {

	var mask: UInt64 {
		(0..<rows)
			.map { row in Self.mask(range: (row * 8)..<(row * 8 + cols)) }
			.reduce(0, |)
	}
	static func mask(range: Range<Int>) -> UInt64 {
		range.count == 64 ? .max : UInt64((1 << range.count) - 1) << range.lowerBound
	}
}

extension Pattern {
	static let techno = Pattern(bits: 0b0001_0001_0001_0001 as UInt16)
	static let trance = Pattern(bits: 0b0111_0111_0111_0111 as UInt16)
	static let empty = Pattern(bits: 0 as UInt16)
}

struct BLEPattern: Equatable {
	var count: UInt8
	var bits: UInt64
}

struct BLEField: Equatable {
	var a: BLEPattern
	var b: BLEPattern
	var c: BLEPattern
	var d: BLEPattern
}

enum Direction {
	case up, right, down, left
}
