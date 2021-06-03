import Foundation

struct Controls {
	var leftStick = Thumbstick.zero
	var rightStick = Thumbstick.zero
	var leftTrigger = 0 as Float
	var rightTrigger = 0 as Float
	var buttons = Button()

	struct Button: OptionSet {
		var rawValue: Int16 = 0

		static let up = Button(rawValue: 1 << 0)
		static let down = Button(rawValue: 1 << 1)
		static let left = Button(rawValue: 1 << 2)
		static let right = Button(rawValue: 1 << 3)
		static let shiftLeft = Button(rawValue: 1 << 4)
		static let shiftRight = Button(rawValue: 1 << 5)
		static let cross = Button(rawValue: 1 << 6)
		static let circle = Button(rawValue: 1 << 7)
		static let square = Button(rawValue: 1 << 8)
		static let triangle = Button(rawValue: 1 << 9)
		static let scan = Button(rawValue: 1 << 10)

		static let dPad = Button([.up, .down, .left, .right])
	}

	struct Thumbstick {
		var x: Float
		var y: Float

		static let zero = Thumbstick(x: 0, y: 0)
	}
}

struct BLEControls: OptionSet {
	var rawValue: Int16 = 0

	static let run = BLEControls(rawValue: 1 << 0)
	static let reset = BLEControls(rawValue: 1 << 1)
	static let mute = BLEControls(rawValue: 1 << 2)
	static let changePattern = BLEControls(rawValue: 1 << 3)

	mutating func set(_ control: BLEControls, pressed: Bool) {
		if pressed { insert(control) } else { remove(control) }
	}
}

extension Controls.Button {
	var dPadDirection: Direction? {
		if contains(.up) { return .up }
		if contains(.right) { return .right }
		if contains(.down) { return .down }
		if contains(.left) { return .left }
		return .none
	}
}
