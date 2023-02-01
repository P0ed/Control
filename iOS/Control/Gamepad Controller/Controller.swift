import GameController
import Combine
import Fx

final class Controller {
	@MutableProperty
	private var current: GCController? = GCController.controllers().first
	private let lifetime: Cancellable

	@MutableProperty
	private(set) var controls = Controls()

	@Property var isConnected: Bool
	@Property var batteryLevel: Float?

	init() {
		_isConnected = _current.map { $0 != nil }

		_batteryLevel = _current.flatMap { ctrl in
			ctrl.flatMap(\.battery).map { battery in
				Property(value: battery.batteryLevel, signal: Signal { sink in
					Timer.repeat(20, sink • { battery.batteryLevel })
				})
			} ?? .const(nil)
		}

		let observers = [
			NotificationCenter.default.addObserver(name: .GCControllerDidBecomeCurrent) { [_current] n in
				_current.value = n.object as? GCController
			},
			NotificationCenter.default.addObserver(name: .GCControllerDidStopBeingCurrent) { [_current] n in
				_current.value = nil
			}
		]
		let handlers = _current.observe { [_controls] controller in
			guard let gamepad = controller?.extendedGamepad else { return }
			_controls.value = Controls()

			gamepad.leftThumbstick.valueChangedHandler = { _, x, y in
				_controls.value.leftStick = Thumbstick(x: x, y: y)
			}
			gamepad.rightThumbstick.valueChangedHandler = { _, x, y in
				_controls.value.rightStick = Thumbstick(x: x, y: y)
			}
			gamepad.leftTrigger.valueChangedHandler = { _, value, _ in
				_controls.value.leftTrigger = value
			}
			gamepad.rightTrigger.valueChangedHandler = { _, value, _ in
				_controls.value.rightTrigger = value
			}

			let mapControl: (GCControllerButtonInput?, Buttons) -> Void = { button, control in
				button?.pressedChangedHandler = { _, _, pressed in
					_controls.modify {
						if pressed {
							$0.buttons.insert(control)
							$0.addToSequence(control)
						} else {
							$0.buttons.remove(control)
						}
					}
				}
			}

			mapControl(gamepad.dpad.up, .up)
			mapControl(gamepad.dpad.down, .down)
			mapControl(gamepad.dpad.left, .left)
			mapControl(gamepad.dpad.right, .right)
			mapControl(gamepad.buttonA, .cross)
			mapControl(gamepad.buttonB, .circle)
			mapControl(gamepad.buttonX, .square)
			mapControl(gamepad.buttonY, .triangle)
			mapControl(gamepad.leftShoulder, .l1)
			mapControl(gamepad.rightShoulder, .r1)
			mapControl(gamepad.leftTrigger, .l2)
			mapControl(gamepad.rightTrigger, .r2)
		}

		lifetime = AnyCancellable { capture([observers, handlers]) }
	}
}

