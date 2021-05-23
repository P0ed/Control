import Combine
import Foundation
import UIKit

final class Model: ObservableObject {

	struct State {
		var bpm: Float = 0
		var valueA: Float = 0
		var valueB: Float = 0
		var pattern: Pattern = .empty
	}

	@Published private(set) var state = State()

	@Published private(set) var pendingPattern: Pattern?
	@Published private(set) var pendingIndex: Int?

	@Published private(set) var controls = Controls()
	@Published private(set) var bleControls = BLEControls()

	@Published private(set) var isBLEConnected: Bool = false
	@Published private(set) var isControllerConnected: Bool = false

	private var lifetime: Any?

	init(transmitter: BLETransmitter, controller: Controller) {
		UIApplication.shared.isIdleTimerDisabled = true

		let mapControl = { (controller.$controls.map($0) as Property<Bool>).distinctUntilChanged() }
		let controlPressed = { control, pressed in mapControl { $0.buttons.contains(control) }.observe(pressed) }
		let anyPressed = { controls, pressed in mapControl { !$0.buttons.intersection(controls).isEmpty }.observe(pressed) }

		var isModified = true

		let runStop = { [unowned self] in state.bpm = state.bpm == 0 ? 120 : 0 }
		let setBPM: ((Float) -> Float) -> Void = { [unowned self] f in modify(&state.bpm) { $0 = .bpm(f($0)) } }
		let enterPattern = { [unowned self] in
			if let pending = pendingPattern {
				state.pattern = pending
				pendingPattern = nil
				pendingIndex = nil
			} else {
				pendingPattern = state.pattern
				pendingIndex = 0
			}
		}

		let sendFloatValue: (KeyPath<State, Float>, @escaping (Float) -> Void) -> Cancellable = { keyPath, send in
			self.$state.map(keyPath).removeDuplicates().sink(receiveValue: send)
		}

		lifetime = [
			transmitter.$isConnected.observe { [unowned self] in isBLEConnected = $0 },
			controller.$isConnected.observe { [unowned self] in isControllerConnected = $0 },
			sendFloatValue(\.bpm) { transmitter.service?.setClock($0) },
			sendFloatValue(\.valueA) { transmitter.service?.setValueA($0) },
			sendFloatValue(\.valueB) { transmitter.service?.setValueB($0) },
			$state.map(\.pattern).sink { transmitter.service?.setPattern($0.bleRepresentation) },
			$bleControls.sink { transmitter.service?.setControls($0) },
			controller.$controls.observe { [unowned self] in controls = $0 },
			anyPressed(.dPad) { if $0 { isModified = true } },
			anyPressed(.dPad) { [unowned self] pressed in if pressed { handleDPad() } },
			controlPressed([.up, .runStop]) { if $0 { setBPM { round($0 / 10) * 10 + 10 } } },
			controlPressed([.down, .runStop]) { if $0 { setBPM { round($0 / 10) * 10 - 10 } } },
			controlPressed([.left, .runStop]) { if $0 { setBPM { $0 * 3 / 4 } } },
			controlPressed([.right, .runStop]) { if $0 { setBPM { $0 * 4 / 3 } } },
			controlPressed(.cross) { [unowned self] pressed in
				if let pattern = pendingPattern, let idx = pendingIndex {
					if pressed { pendingPattern = modify(pattern) { $0[idx].toggle() } }
				} else if !controls.buttons.contains(.shiftRight) {
					bleControls.set(.mute, pressed: pressed)
				}
			},
			controlPressed(.circle) { [unowned self] pressed in
				if pendingPattern != nil {
					pendingPattern = nil
					pendingIndex = nil
				} else if !controls.buttons.contains(.shiftRight) {
					bleControls.set(.changePattern, pressed: pressed)
				}
			},
			controlPressed(.runStop) { if $0 { isModified = false } else if !isModified { runStop() } },
			controlPressed(.pattern) { if $0 { isModified = false } else if !isModified { enterPattern() } },
			controlPressed(.scan) { if $0 { transmitter.scan() } },
			Timer.repeat(1 / 16) { [unowned self] in
				if controls.rightTrigger > 1 / 255 || controls.leftTrigger > 1 / 255 {
					isModified = true
					if controls.buttons.contains(.runStop) {
						let f = { $0 * $0 as Float }
						let diff = f(controls.rightTrigger) - f(controls.leftTrigger)
						let newValue = Float.bpm(state.bpm + diff * 4)
						if newValue != state.bpm { state.bpm = newValue }
					}
				}
			}
		]
	}

	private func handleDPad() {
		guard let pattern = pendingPattern, let direction = controls.buttons.dPadDirection else { return }

		if controls.buttons.contains(.shiftLeft), controls.buttons.contains(.shiftRight) {
			pendingPattern = modify(pattern) { $0.shift(direction: direction) }
		} else if controls.buttons.contains(.shiftLeft) {
			pendingPattern = modify(pattern) { $0.modifySize(subtract: true, direction: direction) }
		} else if controls.buttons.contains(.shiftRight) {
			pendingPattern = modify(pattern) { $0.modifySize(subtract: false, direction: direction) }
		} else {
			movePendingIndex(direction: direction)
		}
	}

	private func movePendingIndex(direction: Direction) {
		guard let idx = pendingIndex else { return }
		switch direction {
		case .up: pendingIndex = (64 + idx - 8) % 64
		case .right: pendingIndex = (idx + 1) % 64
		case .down: pendingIndex = (idx + 8) % 64
		case .left: pendingIndex = (64 + idx - 1) % 64
		}
	}
}

private extension Float {
	static func bpm(_ bpm: Float) -> Float { min(max(bpm, 0), 420) }
}
