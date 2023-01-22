import Foundation

struct Controls {
	var leftStick = Thumbstick.zero
	var rightStick = Thumbstick.zero
	var leftTrigger = 0 as Float
	var rightTrigger = 0 as Float
	var buttons = [] as Buttons
	var sequence = [] as [Buttons]
	var lastPress: Date = .distantPast

	struct Buttons: OptionSet {
		var rawValue: Int16 = 0

		static let up = Buttons(rawValue: 1 << 0)
		static let down = Buttons(rawValue: 1 << 1)
		static let left = Buttons(rawValue: 1 << 2)
		static let right = Buttons(rawValue: 1 << 3)
		static let shiftLeft = Buttons(rawValue: 1 << 4)
		static let shiftRight = Buttons(rawValue: 1 << 5)
		static let cross = Buttons(rawValue: 1 << 6)
		static let circle = Buttons(rawValue: 1 << 7)
		static let square = Buttons(rawValue: 1 << 8)
		static let triangle = Buttons(rawValue: 1 << 9)

		static let dPad = Buttons([.up, .down, .left, .right])
	}

	struct Thumbstick {
		var x: Float
		var y: Float

		static let zero = Thumbstick(x: 0, y: 0)
	}

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

struct BLEControls: OptionSet {
	var rawValue: Int16

	static let run = BLEControls(rawValue: 1 << 0)
	static let reset = BLEControls(rawValue: 1 << 1)
	static let changePattern = BLEControls(rawValue: 1 << 2)

	mutating func set(_ control: BLEControls, pressed: Bool) {
		if pressed { insert(control) } else { remove(control) }
	}
}

extension Controls.Buttons {

	var dPadDirection: Direction? {
		if contains(.up) { return .up }
		if contains(.right) { return .right }
		if contains(.down) { return .down }
		if contains(.left) { return .left }
		return .none
	}

	var modifiers: Modifiers {
		switch (contains(.shiftLeft), contains(.shiftRight)) {
		case (false, false): return .none
		case (true, false): return .l
		case (false, true): return .r
		case (true, true): return .lr
		}
	}
}

enum Shape {
	case cross, circle, square, triangle
}

enum Direction {
	case up, right, down, left
}

enum Modifiers {
	case none, l, r, lr
}
