import Combine
import Foundation
import SwiftUI

final class Model: ObservableObject {

	struct State {
		var bpm: Float
		var pattern: Pattern
		var valueA: Float = 0
		var valueB: Float = 0
	}

	@IO(.store(key: "state", fallback: .initial))
	private var store: StoredState

	@Published private(set) var state: State

	@Published private(set) var pendingPattern: Pattern?
	@Published private(set) var pendingIndex: Int?

	@Published private(set) var controls = Controls()
	@Published private(set) var bleControls = BLEControls()

	@Published private(set) var isBLEConnected: Bool = false
	@Published private(set) var isControllerConnected: Bool = false

	private var lifetime: Any?

	init(transmitter: BLETransmitter, controller: Controller) {
		state = _store.value.state

		let mapControl = { (controller.$controls.map($0) as Property<Bool>).distinctUntilChanged() }
		let controlPressed = { control, pressed in mapControl { $0.buttons.contains(control) }.observe(pressed) }
		let anyPressed = { controls, pressed in mapControl { !$0.buttons.intersection(controls).isEmpty }.observe(pressed) }

		var isModified = true

		let runStop = { [unowned self] in bleControls.formSymmetricDifference(.run) }
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

		lifetime = [
			$state.sink { [unowned self] state in modify(&store) { $0.state = state } },
			transmitter.$isConnected.observe { [unowned self] in isBLEConnected = $0 },
			controller.$isConnected.observe { [unowned self] in isControllerConnected = $0 },
			transmitter.$service.observe(handleService),
			controller.$controls.observe { [unowned self] in controls = $0 },
			anyPressed(.dPad) { if $0 { isModified = true } },
			anyPressed(.dPad) { [unowned self] pressed in if pressed { handleDPad() } },
			controlPressed([.up, .square]) { if $0 { setBPM { round($0 / 10) * 10 + 10 } } },
			controlPressed([.down, .square]) { if $0 { setBPM { round($0 / 10) * 10 - 10 } } },
			controlPressed([.left, .square]) { if $0 { setBPM { $0 * 3 / 4 } } },
			controlPressed([.right, .square]) { if $0 { setBPM { $0 * 4 / 3 } } },
			controlPressed(.cross) { [unowned self] pressed in handleCross(pressed) },
			controlPressed(.circle) { [unowned self] pressed in handleCircle(pressed) },
			controlPressed(.square) { if $0 { isModified = false } else if !isModified { runStop() } },
			controlPressed(.triangle) { if $0 { isModified = false } else if !isModified { enterPattern() } },
			controlPressed(.scan) { if $0 { transmitter.scan() } },
			Timer.repeat(1 / 16) { [unowned self] in if handleTimer() { isModified = true } }
		]

		UIApplication.shared.isIdleTimerDisabled = true
	}

	private var handleService: (BLETransmitter.Service?) -> Void {
		{ [unowned self, subscription = SerialDisposable()] service in
			let sendFloatValue: (KeyPath<State, Float>, @escaping (Float) -> Void) -> Cancellable = { keyPath, send in
				$state.map(keyPath).removeDuplicates().sink(receiveValue: send)
			}

			subscription.innerDisposable = service.map { service in
				let pattern = $state.map(\.pattern.bleRepresentation)
						.sink(receiveValue: service.setPattern)
				let controls = $bleControls.sink(receiveValue: service.setControls)
				let bpm = sendFloatValue(\.bpm, service.setClock)
				let a = sendFloatValue(\.valueA, service.setValueA)
				let b = sendFloatValue(\.valueB, service.setValueB)

				return ActionDisposable(
					action: [pattern, controls, bpm, a, b].map { $0.cancel }.reduce({}, •)
				)
			}
		}
	}

	private func handleDPad() {
		guard let pattern = pendingPattern, let direction = controls.buttons.dPadDirection else { return }

		if controls.buttons.contains([.shiftLeft, .shiftRight]) {
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
		guard let idx = pendingIndex, let pattern = pendingPattern else { return }
		switch direction {
		case .up: pendingIndex = ((8 * pattern.rows) + idx - 8) % (8 * pattern.rows)
		case .right: pendingIndex = (idx % 8 + 1) % pattern.cols + (idx / 8) * 8
		case .down: pendingIndex = (idx + 8) % (8 * pattern.rows)
		case .left: pendingIndex = ((pattern.cols + idx % 8 - 1) % pattern.cols) + (idx / 8) * 8
		}
	}

	private func handleCross(_ pressed: Bool) {
		if let pattern = pendingPattern, let idx = pendingIndex {
			if pressed { pendingPattern = modify(pattern) { $0[idx].toggle() } }
		} else if !controls.buttons.contains(.shiftRight) {
			bleControls.set(.mute, pressed: pressed)
		}
	}

	private func handleCircle(_ pressed: Bool) {
		if pendingPattern != nil {
			pendingPattern = nil
			pendingIndex = nil
		} else if !controls.buttons.contains(.shiftRight) {
			bleControls.set(.changePattern, pressed: pressed)
		}
	}

	private func handleTimer() -> Bool {
		if controls.rightTrigger > 1 / 255 || controls.leftTrigger > 1 / 255 {
			if controls.buttons.contains(.square) {
				let f = { $0 * $0 as Float }
				let diff = f(controls.rightTrigger) - f(controls.leftTrigger)
				let newValue = Float.bpm(state.bpm + diff * 4)
				if newValue != state.bpm { state.bpm = newValue }
			}
			return true
		}
		return false
	}
}

private extension Float {
	static func bpm(_ bpm: Float) -> Float { min(max(bpm, 0), 420) }
}
