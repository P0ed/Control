import GameController
import Combine

final class Controller {
	@MutableProperty
	private var current: GCController? = GCController.controllers().first
	private let lifetime: Cancellable

	@MutableProperty
	private(set) var leftStick: (x: Float, y: Float) = (0, 0)
	@MutableProperty
	private(set) var rightStick: (x: Float, y: Float) = (0, 0)

	init() {
		let observers = [
			NotificationCenter.default.addObserver(name: .GCControllerDidBecomeCurrent) { [_current] n in
				_current.value = n.object as? GCController
			},
			NotificationCenter.default.addObserver(name: .GCControllerDidStopBeingCurrent) { [_current] n in
				_current.value = nil
			}
		]
		let handlers = _current.observe { [_leftStick, _rightStick] controller in
			let gamepad = controller?.extendedGamepad
			_leftStick.value = (gamepad?.leftThumbstick).map { ($0.xAxis.value, $0.yAxis.value) } ?? (0, 0)
			_rightStick.value = (gamepad?.rightThumbstick).map { ($0.xAxis.value, $0.yAxis.value) } ?? (0, 0)

			gamepad?.leftThumbstick.valueChangedHandler = { _, x, y in
				_leftStick.value = (x, y)
			}
			gamepad?.rightThumbstick.valueChangedHandler = { _, x, y in
				_rightStick.value = (x, y)
			}
		}

		lifetime = AnyCancellable { capture([observers, handlers]) }
	}
}
