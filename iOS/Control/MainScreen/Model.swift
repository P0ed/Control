import Combine
import Foundation
import SwiftUI

final class Model: ObservableObject {

	struct State {
		var bpm: Float
		var pattern: Pattern

		var bleControls = BLEControls()

		var pendingPattern: Pattern?
		var pendingIndex: Int?
	}

	@IO(.store(key: "state", fallback: .initial))
	private var store: StoredState

	@Published private(set) var state: State
	@Published private(set) var controls = Controls()

	@Published private(set) var isBLEConnected: Bool = false
	@Published private(set) var isControllerConnected: Bool = false

	private var lifetime: Any?

	@IO private var isModified = true

	init(transmitter: BLETransmitter, controller: Controller) {
		state = _store.value.state

		let mapControl = { controller.$controls.map($0).distinctUntilChanged() as Property<Bool> }
		let control = { ctrl, pressed in mapControl { $0.buttons.contains(ctrl) }.observe(pressed) }
		let controlPressed = { ctrl, pressed in control(ctrl, Fn.if(pressed, {})) }
		let anyPressed = { controls, pressed in mapControl { !$0.buttons.intersection(controls).isEmpty }.observe(Fn.if(pressed, {})) }
		let setBPM: ((Float) -> Float) -> Void = { [self] f in modify(&state.bpm) { $0 = .bpm(f($0)) } }

		lifetime = [
			$state.sink { [self] state in modify(&store) { $0.state = state } },
			$controls.sink { [self] in handleControls($0) },
			transmitter.$isConnected.observe { [self] in isBLEConnected = $0 },
			controller.$isConnected.observe { [self] in isControllerConnected = $0 },
			transmitter.$service.observe(handleService),
			controller.$controls.observe { [self] in controls = $0 },
			anyPressed(.dPad) { [self] in isModified = true },
			anyPressed(.dPad, handleDPad),
			controlPressed([.up, .square]) { setBPM { round($0 / 10) * 10 + 10 } },
			controlPressed([.down, .square]) { setBPM { round($0 / 10) * 10 - 10 } },
			controlPressed([.left, .square]) { setBPM { $0 * 3 / 4 } },
			controlPressed([.right, .square]) { setBPM { $0 * 4 / 3 } },
			control(.cross, handleCross),
			control(.circle, handleCircle),
			control(.square, handleSquare),
			control(.triangle, handleEditPattern),
			controlPressed(.scan, transmitter.scan),
			Timer.repeat(1 / 16, handleTimer)
		]

		UIApplication.shared.isIdleTimerDisabled = true
	}

	private func handleControls(_ controls: Controls) {

	}

	private var handleService: (BLETransmitter.Service?) -> Void {
		{ [unowned self, subscription = SerialDisposable()] service in
			subscription.innerDisposable = service.map { service in
				let pattern = $state.map(\.pattern.bleRepresentation).removeDuplicates().sink(receiveValue: service.setPattern)
				let controls = $state.map(\.bleControls).removeDuplicates().sink(receiveValue: service.setControls)
				let bpm = $state.map(\.bpm).removeDuplicates().sink(receiveValue: service.setClock)

				return ActionDisposable(
					action: [pattern, controls, bpm].map { $0.cancel }.reduce({}, •)
				)
			}
		}
	}

	private func handleDPad() {
		guard let pattern = state.pendingPattern, let direction = controls.buttons.dPadDirection else { return }

		if controls.buttons.contains([.shiftLeft, .shiftRight]) {
			state.pendingPattern = modify(pattern) { $0.shift(direction: direction) }
		} else if controls.buttons.contains(.shiftLeft) {
			state.pendingPattern = modify(pattern) { $0.modifySize(subtract: true, direction: direction) }
		} else if controls.buttons.contains(.shiftRight) {
			state.pendingPattern = modify(pattern) { $0.modifySize(subtract: false, direction: direction) }
		} else {
			movePendingIndex(direction: direction)
		}
	}

	private func movePendingIndex(direction: Direction) {
		guard let idx = state.pendingIndex, let pattern = state.pendingPattern else { return }
		switch direction {
		case .up: state.pendingIndex = ((8 * pattern.rows) + idx - 8) % (8 * pattern.rows)
		case .right: state.pendingIndex = (idx % 8 + 1) % pattern.cols + (idx / 8) * 8
		case .down: state.pendingIndex = (idx + 8) % (8 * pattern.rows)
		case .left: state.pendingIndex = ((pattern.cols + idx % 8 - 1) % pattern.cols) + (idx / 8) * 8
		}
	}

	private func handleCross(_ pressed: Bool) {
		if let pattern = state.pendingPattern, let idx = state.pendingIndex {
			if pressed { state.pendingPattern = modify(pattern) { $0[idx].toggle() } }
		} else if !controls.buttons.contains(.shiftRight) {
			state.bleControls.set(.mute, pressed: pressed)
		}
	}

	private func handleCircle(_ pressed: Bool) {
		if state.pendingPattern != nil {
			state.pendingPattern = nil
			state.pendingIndex = nil
		} else if !controls.buttons.contains(.shiftRight) {
			state.bleControls.set(.changePattern, pressed: pressed)
		}
	}

	private func handleSquare(_ pressed: Bool) {
		if pressed {
			isModified = false
		} else if !isModified {
			runStop()
		}
	}

	private func handleEditPattern(_ pressed: Bool) {
		if pressed { isModified = false } else if !isModified {
			modify(&state) {
				if let pending = state.pendingPattern {
					$0.pattern = pending
					$0.pendingPattern = nil
					$0.pendingIndex = nil
				} else {
					$0.pendingPattern = $0.pattern
					$0.pendingIndex = 0
				}
			}
		}
	}

	private func handleTimer() {
		if controls.rightTrigger > 1 / 255 || controls.leftTrigger > 1 / 255 {
			if controls.buttons.contains(.square) {
				let f = { $0 * $0 as Float }
				let diff = f(controls.rightTrigger) - f(controls.leftTrigger)
				let newValue = Float.bpm(state.bpm + diff * 4)
				if newValue != state.bpm {
					state.bpm = newValue
					isModified = true
				}
			}
		}
	}

	private func runStop() {
		state.bleControls.formSymmetricDifference(.run)
	}
}

private extension Float {
	static func bpm(_ bpm: Float) -> Float { min(max(bpm, 0), 420) }
}
