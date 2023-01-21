import Foundation

struct Field: Codable {
	var a: Pattern = .empty
	var b: Pattern = .empty
	var c: Pattern = .empty
	var d: Pattern = .empty
}

struct PatternOptions: Codable {
	var dutyCycle: DutyCycle = .trig
}

extension Field {

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
			d: d.bleRepresentation,
			options: bleOptions
		)
	}

	private var bleOptions: UInt8 {
		UInt8(a.options.dutyCycle.rawValue) << 0
		| UInt8(b.options.dutyCycle.rawValue) << 2
		| UInt8(c.options.dutyCycle.rawValue) << 4
		| UInt8(d.options.dutyCycle.rawValue) << 6
	}
}

struct BLEField: Equatable {
	var a: BLEPattern
	var b: BLEPattern
	var c: BLEPattern
	var d: BLEPattern
	var options: UInt8
}
