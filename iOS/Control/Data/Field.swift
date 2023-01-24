import Foundation

struct Field: Codable {
	var a = PatternState()
	var b = PatternState()
	var c = PatternState()
	var d = PatternState()
}

enum DutyCycle: Int, Codable { case trig, quarter, half, full }

extension DutyCycle {
	func fold<A>(trig: @autoclosure () -> A, quarter: @autoclosure () -> A, half: @autoclosure () -> A, full: @autoclosure () -> A) -> A {
		switch self {
		case .trig: return trig()
		case .quarter: return quarter()
		case .half: return half()
		case .full: return full()
		}
	}
}

struct PatternOptions: Codable {
	var dutyCycle: DutyCycle = .trig
}

extension Field {

	subscript(_ idx: Int) -> PatternState {
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

	var all: [PatternState] { [a, b, c, d] }
}
