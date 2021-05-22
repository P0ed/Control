import Combine
import Foundation
import UIKit

final class Model: ObservableObject {
	@Published private(set) var clockBPM: Float = 0
	@Published private(set) var valueA: Float = 0
	@Published private(set) var valueB: Float = 0

	private let transmitter: BLETransmitter
	private let controller: Controller
	private var lifetime: Any?

	init(transmitter: BLETransmitter, controller: Controller) {
		self.transmitter = transmitter
		self.controller = controller
		UIApplication.shared.isIdleTimerDisabled = true

		lifetime = [
			$clockBPM.sink { [sent = IO<Float?>(wrappedValue: nil)] clock in
				if (try? abs(clock - unwrap(sent.value)) > 0.33) ?? true {
					transmitter.service?.setClock(clock)
					sent.value = clock
				}
			},
			controller.$leftTrigger.observe { [unowned self] in
				if controller.appControls.contains(.runStop) { return }

				if abs($0 - valueA) > 0.01 {
					valueA = $0
					transmitter.service?.setValueA(valueA)
				}
			},
			controller.$rightTrigger.observe { [unowned self] in
				if controller.appControls.contains(.runStop) { return }

				if abs($0 - valueB) > 0.01 {
					valueB = $0
					transmitter.service?.setValueB(valueB)
				}
			},
			controller.$bleControls.observe { controls in
				transmitter.service?.setControls(controls)
			},
			controller.$appControls
				.map { $0.contains(.runStop) }
				.distinctUntilChanged()
				.observe { [unowned self, clock = IO(copy: nil as Float?)] pressed in
					if pressed {
						clock.value = clockBPM
					} else if clockBPM == clock.value {
						runStop()
					}
				}
			,
			controller.$appControls
				.map { $0.contains(.scan) }
				.distinctUntilChanged()
				.observe { [unowned self] pressed in if pressed { scan() } }
			,
			Timer.repeat(1 / 16) { [unowned self] in
				if controller.appControls.contains(.runStop) {
					var clock = min(max(clockBPM + (controller.rightTrigger - controller.leftTrigger) * 3, 0), 420)
					if clock < 4 { clock = 0 }
					if abs(clock - clockBPM) > 0.33 { clockBPM = clock }
				}
			}
		]
	}

	func scan() {
		transmitter.scan()
	}

	func runStop() {
		clockBPM = clockBPM == 0 ? 120 : 0
	}
}
