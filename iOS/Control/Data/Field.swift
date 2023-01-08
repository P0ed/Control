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

struct BLEField: Equatable {
	var a: BLEPattern
	var b: BLEPattern
	var c: BLEPattern
	var d: BLEPattern
}
