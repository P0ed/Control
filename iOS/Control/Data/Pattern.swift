import Foundation
import Fx

struct PatternState: Codable {
	var pattern: Pattern = .empty
	var isMuted: Bool = false
	var options: PatternOptions = .init()
	var euclidean: Int = 0
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
	subscript(linear index: Int) -> Bool {
		get { self[mapIndex(index)] }
		set { self[mapIndex(index)] = newValue }
	}
	private func mapIndex(_ index: Int) -> Int {
		let index = (index + count) % count
		return index / cols * 8 + index % cols
	}
}

extension Pattern: CustomDebugStringConvertible {
	var debugDescription: String {
		(0..<8).map { row in
			(0..<8).map { col in
				row < rows && col < cols ? "\(self[row * 8 + col] ? "x" : "o")" : "-"
			}
			.joined()
		}
		.joined(separator: "\n")
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

	mutating func inverse() {
		bits = ~bits & mask
	}

	func rowBits(_ row: Int) -> UInt64 {
		(mask(row: row) & bits) >> (row * 8)
	}
}

extension Pattern {

	static func mask(range: Range<Int>) -> UInt64 {
		range.count == 64 ? .max : UInt64((1 << range.count) - 1) << range.lowerBound
	}
	func mask(row: Int) -> UInt64 {
		Self.mask(range: (row * 8)..<(row * 8 + cols))
	}
	var mask: UInt64 {
		(0..<rows).map(mask(row:)).reduce(0, |)
	}
}

extension Pattern {
	static let techno = Pattern(bits: 0b0001_0001_0001_0001 as UInt16)
	static let trance = Pattern(bits: 0b0111_0111_0111_0111 as UInt16)
	static let claps = Pattern(bits: 0b0001_0000_0001_0000 as UInt16)
	static let hats = Pattern(bits: 0b0100_0100_0100_0100 as UInt16)
	static let all = Pattern(bits: 0b1111_1111_1111_1111 as UInt16)
	static let empty = Pattern(bits: 0 as UInt16)
	static let lazerpresent = Pattern(rows: 4, cols: 8, bits: 0b0001_0001_0001_0001 | (0b0000_0100_1001_0001 << 16))
}
