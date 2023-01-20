import Combine
import Foundation
import SwiftUI
import Fx

final class Model: ObservableObject {

	struct State {
		var bpm: Float
		var swing: Float = 0
		var bleControls: BLEControls = [.changePattern]
		var field: Field
		var patternIndex: Int = 0

		var pending: Field?
		var cursor: Int?
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

		lifetime = [
			$controls.sink(receiveValue: handleControls),
			transmitter.$isConnected.observe { self.isBLEConnected = $0 },
			controller.$isConnected.observe { self.isControllerConnected = $0 },
			transmitter.$service.observe(handleService),
			controller.$controls.observe { self.controls = $0 },
			controls(controller: controller, transmitter: transmitter),
			combos(controller: controller),
			Timer.repeat(1 / 16, handleTimer)
		]

		UIApplication.shared.isIdleTimerDisabled = true
	}

	private func combos(controller: Controller) -> Any {
		let sequence = { (pattern: [Controls.Buttons], sink: @escaping () -> Void) -> Disposable in
			controller.$controls.signal.filter { $0.matchesSequence(pattern) }.observe { _ in
				if self.state.pending == nil { sink() }
			}
		}
		let mod = { mod in _ = try? modify(&self.state.pattern, mod) }
		let set = { self.state.pattern = $0 }

		return [
			sequence([.up, .up, .up, .down, .down, .down], { set(.techno) }),
			sequence([.up, .up, .up, .down, .down, .right], { set(.lazerpresent) }),
			sequence([.left, .left, .up, .down, .right, .right], { set(.trance) }),
			sequence([.left, .left, .left, .left, .left, .left], { set(.claps) }),
			sequence([.right, .right, .right, .right, .right, .right], { set(.hats) }),
			sequence([.up, .up, .up, .up, .up, .up], { set(.all) }),
			sequence([.down, .down, .down, .down, .down, .down], { set(.empty) }),
			sequence([.down, .up, .down, .up, .down, .up], { mod { $0.inverse() } }),
			sequence([.cross, .cross, .cross, .cross], { self.state.swing = 0; self.swing = 0 })
		]
	}

	private func controls(controller: Controller, transmitter: BLETransmitter) -> Any {
		let mapControl = { controller.$controls.map($0).distinctUntilChanged() as Property<Bool> }
		let control = { ctrl, pressed in mapControl { $0.buttons.contains(ctrl) }.observe(pressed) }
		let controlPressed = { ctrl, pressed in control(ctrl, Fn.fold(pressed, {})) }
		let anyPressed = { controls, pressed in mapControl { !$0.buttons.intersection(controls).isEmpty }.observe(Fn.fold(pressed, {})) }
		let setBPM: ((Float) -> Float) -> Void = { [self] f in modify(&state.bpm) { $0 = f($0).bpm } }

		return [
			anyPressed(.dPad) { [self] in isModified = true },
			anyPressed(.dPad, handleDPad),
			controlPressed([.up, .square]) { setBPM { round($0 / 10) * 10 + 10 } },
			controlPressed([.down, .square]) { setBPM { round($0 / 10) * 10 - 10 } },
			controlPressed([.left, .square]) { setBPM { $0 * 3 / 4 } },
			controlPressed([.right, .square]) { setBPM { $0 * 4 / 3 } },
			control(.cross, handleCross),
			control(.circle, handleCircle),
			control(.square, handleSquare),
			control(.triangle, handleTriangle),
			controlPressed(.scan, transmitter.scan)
		]
	}

	private var handleService: (BLETransmitter.Service?) -> Void {
		{ [unowned self, subscription = SerialDisposable()] service in
			subscription.innerDisposable = service.map { service in
				let pattern = $state.map(\.field.bleRepresentation).removeDuplicates().sink(receiveValue: service.setPattern)
				let controls = $state.map(\.bleControls).removeDuplicates().sink(receiveValue: service.setControls)
				let bpm = $state.map(\.bleClock).removeDuplicates().sink(receiveValue: service.setClock)

				return ActionDisposable(
					action: [pattern, controls, bpm].map { $0.cancel }.reduce({}, •)
				)
			}
		}
	}

	private func handleDPad() {
		guard let direction = controls.buttons.dPadDirection, let field = state.pending else { return }

		switch controls.buttons.modifiers {
		case .none: moveCursor(direction: direction)
		case .l: state.pending = modify(field) { $0[state.patternIndex].modifySize(subtract: true, direction: direction) }
		case .r: state.pending = modify(field) { $0[state.patternIndex].modifySize(subtract: false, direction: direction) }
		case .lr: state.pending = modify(field) { $0[state.patternIndex].shift(direction: direction) }
		}
	}

	private func moveCursor(direction: Direction) {
		guard let idx = state.cursor, let pattern = state.pending?[state.patternIndex] else { return }
		switch direction {
		case .up: state.cursor = ((8 * pattern.rows) + idx - 8) % (8 * pattern.rows)
		case .right: state.cursor = (idx % 8 + 1) % pattern.cols + (idx / 8) * 8
		case .down: state.cursor = (idx + 8) % (8 * pattern.rows)
		case .left: state.cursor = ((pattern.cols + idx % 8 - 1) % pattern.cols) + (idx / 8) * 8
		}
	}

	private func handleCross(_ pressed: Bool) {
		switch controls.buttons.modifiers {
		case .none:
			if let field = state.pending {
				if pressed, let idx = state.cursor {
					state.pending = modify(field) { $0[state.patternIndex][idx].toggle() }
				}
			}
		case .l: if pressed { state.patternIndex = 0 }
		case .r: if pressed { writeToPattern(0) }
		case .lr: if pressed { save() }
		}
	}

	private func handleCircle(_ pressed: Bool) {
		switch controls.buttons.modifiers {
		case .none:
			if state.pending != nil {
				state.pending = nil
				state.cursor = nil
			} else {
				if pressed {
					switch controls.buttons.dPadDirection {
					case .none: state.pattern.isMuted.toggle()
					case .down: state.pattern.dutyCycle = .off
					case .left: state.pattern.dutyCycle = .quarter
					case .right: state.pattern.dutyCycle = .half
					case .up: state.pattern.dutyCycle = .full
					}
				}
			}
		case .l: if pressed { state.patternIndex = 1 }
		case .r: if pressed { writeToPattern(1) }
		case .lr: if pressed { recall() }
		}
	}

	private func handleSquare(_ pressed: Bool) {
		switch controls.buttons.modifiers {
		case .none:
			if state.pending == nil {
				if pressed {
					isModified = false
				} else if !isModified {
					runStop()
				}
			} else {
				if pressed { state.bleControls.formSymmetricDifference(.changePattern) }
			}
		case .l: if pressed { state.patternIndex = 2 }
		case .r: if pressed { writeToPattern(2) }
		case .lr: break
		}
	}

	private func handleTriangle(_ pressed: Bool) {
		switch controls.buttons.modifiers {
		case .none:
			if pressed {
				isModified = false
			} else if !isModified {
				state.toggleCursor()
			}
		case .l: if pressed { state.patternIndex = 3 }
		case .r: if pressed { writeToPattern(3) }
		case .lr: break
		}
	}

	private func writeToPattern(_ idx: Int) {

		if let pending = state.pending {
			state.pending = modify(pending) { $0[idx] = $0[state.patternIndex] }
		} else {
			state.field[idx] = state.pattern
		}
	}

	private var offset = (x: 0, y: 0)
	private var swing = 0 as Float

	private func handleControls(_ controls: Controls) {
		if controls.buttons.contains(.cross) {
			if abs(controls.leftStick.x) > 1 / 255 || abs(controls.leftStick.y) > 1 / 255 {
				modify(&state.pendingPattern) { ptn in
					let dx = Int(controls.leftStick.x * Float(ptn.cols - 1))
					let dy = Int(controls.leftStick.y * Float(ptn.rows - 1))
					if offset.x != dx || offset.y != dy {
						ptn.shift(dx - offset.x, direction: .right)
						ptn.shift(dy - offset.y, direction: .down)
						offset = (dx, dy)
					}
				}
			}
			if controls.leftTrigger > 1 / 255 || controls.rightTrigger > 1 / 255 {
				state.swing = (swing + controls.rightTrigger - controls.leftTrigger).clamped(to: -1...1)
			} else {
				state.swing = swing
			}
		} else {
			if offset.x != 0 || offset.y != 0 {
				modify(&state.pendingPattern) { ptn in
					ptn.shift(-offset.x, direction: .right)
					ptn.shift(-offset.y, direction: .down)
					offset = (0, 0)
				}
			}
			swing = state.swing
		}
	}

	private func handleTimer() {
		if controls.rightTrigger > 1 / 255 || controls.leftTrigger > 1 / 255 {
			if controls.buttons.contains(.square) {
				let f = { $0 * $0 as Float }
				let diff = f(controls.rightTrigger) - f(controls.leftTrigger)
				let newValue = (state.bpm + diff * 4).bpm
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

	private func save() {
		store.state = state
	}

	private func recall() {
		modify(&state) { [store] in
			$0.field = store.field
			$0.bpm = store.bpm
			$0.swing = store.swing
		}
	}
}

private extension Float {
	var bpm: Float { min(max(self, 0), 420) }
}

extension Model.State {

	var pendingPattern: Pattern {
		get { pending?[patternIndex] ?? pattern }
		set { (pending?[patternIndex] = newValue) ?? (pattern = newValue) }
	}

	var pattern: Pattern {
		get { field[patternIndex] }
		set { field[patternIndex] = newValue }
	}

	mutating func toggleCursor() {
		if let next = pending {
			field = next
			pending = nil
			cursor = nil
		} else {
			pending = field
			cursor = 0
		}
	}
}

extension Fn {

	static func fold<A>(_ true: @escaping @autoclosure () -> A, _ false: @escaping @autoclosure () -> A) -> (Bool) -> A {
		{ $0 ? `true`() : `false`() }
	}

	static func fold<A>(_ true: @escaping () -> A, _ false: @escaping () -> A) -> (Bool) -> A {
		{ $0 ? `true`() : `false`() }
	}
}
