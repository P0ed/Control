import Foundation

struct Controls: Hashable {
	var leftStick = Thumbstick.zero
	var rightStick = Thumbstick.zero
	var leftTrigger = 0 as Float
	var rightTrigger = 0 as Float
	var buttons = [] as Buttons
	var sequence = [] as [Buttons]
	var lastPress: Date = .distantPast

	var isValidSequence: Bool { -lastPress.timeIntervalSinceNow < 0.5 }

	mutating func addToSequence(_ button: Buttons) {
		if !isValidSequence { sequence = [] }
		sequence.append(button)
		lastPress = .now
	}

	func matchesSequence(_ combo: [Buttons]) -> Bool {
		isValidSequence && buttons.isEmpty && sequence
			.dropFirst(max(0, sequence.count - combo.count))
			.contains(combo)
	}
}

struct Buttons: OptionSet, Hashable {
	var rawValue: Int = 0

	static let up = Buttons(rawValue: 1 << 0)
	static let down = Buttons(rawValue: 1 << 1)
	static let left = Buttons(rawValue: 1 << 2)
	static let right = Buttons(rawValue: 1 << 3)

	static let cross = Buttons(rawValue: 1 << 4)
	static let circle = Buttons(rawValue: 1 << 5)
	static let square = Buttons(rawValue: 1 << 6)
	static let triangle = Buttons(rawValue: 1 << 7)

	static let l1 = Buttons(rawValue: 1 << 8)
	static let r1 = Buttons(rawValue: 1 << 9)
	static let l2 = Buttons(rawValue: 1 << 10)
	static let r2 = Buttons(rawValue: 1 << 11)

	static let dPad = Buttons([up, down, left, right])
	static let shapes = Buttons([cross, circle, square, triangle])
	static let modifiers = Buttons([l1, r1, l2, r2])
}

struct Thumbstick: Hashable {
	var x: Float
	var y: Float

	static let zero = Thumbstick(x: 0, y: 0)
}

extension Buttons {

	var dPadDirection: Direction? {
		if contains(.up) { return .up }
		if contains(.right) { return .right }
		if contains(.down) { return .down }
		if contains(.left) { return .left }
		return .none
	}

	var modifiers: Modifiers {
		Modifiers(rawValue: (rawValue >> 8) & 0xF)
	}
}

enum Direction: Hashable { case up, right, down, left }
enum Shape: Int, Hashable, Codable { case cross, circle, square, triangle }
enum Modifier: Int, Hashable { case l1, r1, l2, r2 }

struct Modifiers: OptionSet {
	var rawValue: Int
}

extension Shape {

	init(_ idx: Int) { self = Shape(rawValue: idx % 4) ?? .cross }

	var symbol: String {
		switch self {
		case .cross: return "♥︎"
		case .circle: return "♠︎"
		case .square: return "♦︎"
		case .triangle: return "♣︎"
		}
	}
	var altSymbol: String {
		switch self {
		case .cross: return "♡"
		case .circle: return "♤"
		case .square: return "♢"
		case .triangle: return "♧"
		}
	}
}

extension Thumbstick {
	var shape: Shape? {
		let c = sqrt(x * x + y * y)
		if c > 0.6 {
			let sin = y / c
			let cos = x / c
			let s = sqrt(2) / 2 as Float

			if sin < -s {
				return .cross
			} else if cos > s {
				return .circle
			} else if cos < -s {
				return .square
			} else if sin > s {
				return .triangle
			} else {
				return nil
			}
		} else {
			return nil
		}
	}
}

extension Modifiers {
	static let l1 = Modifiers(.l1)
	static let r1 = Modifiers(.r1)
	static let l2 = Modifiers(.l2)
	static let r2 = Modifiers(.r2)

	init(_ modifier: Modifier) { self = Modifiers(rawValue: 1 << modifier.rawValue) }
}
