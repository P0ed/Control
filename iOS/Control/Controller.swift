import GameController
import Combine

final class Controller {
	@MutableProperty
	private var current: GCController? = GCController.controllers().first
	private let lifetime: Cancellable

	@MutableProperty
	private(set) var leftStick = Thumbstick.zero
	@MutableProperty
	private(set) var rightStick = Thumbstick.zero
	@MutableProperty
	private(set) var leftTrigger = 0 as Float
	@MutableProperty
	private(set) var rightTrigger = 0 as Float
	@MutableProperty
	private(set) var bleControls = BLEControls()
	@MutableProperty
	private(set) var appControls = AppControls()

	init() {
		let observers = [
			NotificationCenter.default.addObserver(name: .GCControllerDidBecomeCurrent) { [_current] n in
				_current.value = n.object as? GCController
			},
			NotificationCenter.default.addObserver(name: .GCControllerDidStopBeingCurrent) { [_current] n in
				_current.value = nil
			}
		]
		let handlers = _current.observe { [_leftTrigger, _rightTrigger, _leftStick, _rightStick, _bleControls, _appControls] controller in
			let gamepad = controller?.extendedGamepad
			_leftStick.value = (gamepad?.leftThumbstick).map { Thumbstick(x: $0.xAxis.value, y: $0.yAxis.value) } ?? .zero
			_rightStick.value = (gamepad?.rightThumbstick).map { Thumbstick(x: $0.xAxis.value, y: $0.yAxis.value) } ?? .zero
			_leftTrigger.value = gamepad?.leftTrigger.value ?? 0
			_rightTrigger.value = gamepad?.rightTrigger.value ?? 0

			gamepad?.leftThumbstick.valueChangedHandler = { _, x, y in
				_leftStick.value = Thumbstick(x: x, y: y)
			}
			gamepad?.rightThumbstick.valueChangedHandler = { _, x, y in
				_rightStick.value = Thumbstick(x: x, y: y)
			}
			gamepad?.leftTrigger.valueChangedHandler = { _, value, _ in
				_leftTrigger.value = value
			}
			gamepad?.rightTrigger.valueChangedHandler = { _, value, _ in
				_rightTrigger.value = value
			}

			let mapBLEControl: (KeyPath<GCExtendedGamepad, GCControllerButtonInput>, BLEControls) -> Void = { button, control in
				gamepad?[keyPath: button].valueChangedHandler = { _, _, pressed in
					if pressed {
						_bleControls.value.insert(control)
					} else {
						_bleControls.value.remove(control)
					}
				}
			}
			let mapAppControl: (KeyPath<GCExtendedGamepad, GCControllerButtonInput>, AppControls) -> Void = { button, control in
				gamepad?[keyPath: button].valueChangedHandler = { _, _, pressed in
					if pressed {
						_appControls.value.insert(control)
					} else {
						_appControls.value.remove(control)
					}
				}
			}
			mapBLEControl(\.buttonA, .mute)
			mapBLEControl(\.buttonB, .nextPattern)
			mapAppControl(\.buttonX, .runStop)
			mapAppControl(\.buttonY, .scan)
		}

		lifetime = AnyCancellable { capture([observers, handlers]) }
	}
}

struct BLEControls: OptionSet {
	var rawValue: Int16 = 0

	static let mute = BLEControls(rawValue: 1 << 0)
	static let nextPattern = BLEControls(rawValue: 1 << 1)
}

struct AppControls: OptionSet {
	var rawValue: Int16 = 0

	static let runStop = AppControls(rawValue: 1 << 0)
	static let scan = AppControls(rawValue: 1 << 1)
}

struct Thumbstick {
	var x: Float
	var y: Float

	static let zero = Thumbstick(x: 0, y: 0)
}
