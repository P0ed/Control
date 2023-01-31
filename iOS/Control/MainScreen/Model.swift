import Combine
import Foundation
import SwiftUI
import Fx

final class Model: ObservableObject {
	private let transmitter: Transmitter
	private let controller: Controller

	@IO(.store(key: "state", fallback: .empty))
	private var store: State

	@Published private(set) var state: State
	@Published private(set) var controls = Controls()

	@Published private(set) var isBLEConnected = false
	@Published private(set) var isControllerConnected = false
	@Published private(set) var battery = 0 as Float

	private var lifetime: Any?

	init(transmitter: Transmitter, controller: Controller) {
		self.transmitter = transmitter
		self.controller = controller

		self.state = _store.value

		lifetime = [
			$controls.sink(receiveValue: handleControls),
			transmitter.$isConnected.observe(.main) { self.isBLEConnected = $0 },
			controller.$isConnected.observe(.main) { self.isControllerConnected = $0 },
			controller.$batteryLevel.observe(.main) { self.battery = $0 },
			transmitter.$service.observe(.main, handleService),
			controller.$controls.observe(.main) { self.controls = $0 },
			controlsMap,
			dPadMap,
			combos
		]

		UIApplication.shared.isIdleTimerDisabled = true
	}

	private var combos: Any {
		let sequence = { [controller] (pattern: [Buttons], sink: @escaping () -> Void) -> Disposable in
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

	private var controlsMap: Any {
		let control = { [controller] ctrl, pressed in
			controller.$controls
				.map { $0.buttons.contains(ctrl) }
				.distinctUntilChanged()
				.observe(pressed)
		}
		return [
			control(.cross, handleCross),
			control(.circle, handleCircle),
			control(.square, handleSquare),
			control(.triangle, handleTriangle)
		]
	}

	private var dPadMap: Any {
		controller.$controls
			.map(\.buttons.dPadDirection)
			.distinctUntilChanged()
			.observe(sink • Fn.map(handleDPad))
	}

	private var handleService: (Transmitter.Service?) -> Void {
		{ [self, subscription = SerialDisposable()] service in
			subscription.innerDisposable = service.map { service in
				ActionDisposable(
					action: $state.map(\.blePattern).removeDuplicates().sink(receiveValue: service.setPattern).cancel
						• $state.map(\.bleControls).removeDuplicates().sink(receiveValue: service.setControls).cancel
				)
			}
		}
	}

	private func handleDPad(_ direction: Direction) {
		guard let patterns = state.pending else { return }

		switch controls.buttons.modifiers {
		case .none: moveCursor(direction: direction)
		case .l: state.pending = modify(patterns) { $0[state.patternIndex].pattern.modifySize(subtract: true, direction: direction) }
		case .r: state.pending = modify(patterns) { $0[state.patternIndex].pattern.modifySize(subtract: false, direction: direction) }
		case .lr: state.pending = modify(patterns) { $0[state.patternIndex].pattern.shift(direction: direction) }
		}
	}

	private func moveCursor(direction: Direction) {
		guard let idx = state.cursor, let pattern = state.pending?[state.patternIndex].pattern else { return }
		switch direction {
		case .up: state.cursor = ((8 * pattern.rows) + idx - 8) % (8 * pattern.rows)
		case .right: state.cursor = (idx % 8 + 1) % pattern.cols + (idx / 8) * 8
		case .down: state.cursor = (idx + 8) % (8 * pattern.rows)
		case .left: state.cursor = ((pattern.cols + idx % 8 - 1) % pattern.cols) + (idx / 8) * 8
		}
	}

	private func handleCross(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.cross); return }

		switch controls.buttons.modifiers {
		case .none:
			if let pending = state.pending {
				if let idx = state.cursor {
					state.pending = modify(pending) { $0[state.patternIndex].pattern[idx].toggle() }
				}
			} else {
				switch controls.buttons.dPadDirection {
				case .none: state.shapes.insert(.cross)
				case .down: state.patternState.decEuclidean()
				case .up: state.patternState.incEuclidean()
				case .left: state.pattern.double()
				case .right: state.pattern.genRule90()
				}
			}
		case .l: state.patternIndex = 0
		case .r: controls.leftStick.shape.map { state.bankIndex = $0.rawValue }
		case .lr: writeToPattern(0)
		}
	}

	private func handleCircle(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.circle); return }

		switch controls.buttons.modifiers {
		case .none:
			if state.pending != nil {
				state.pending = nil
				state.cursor = nil
			} else {
				switch controls.buttons.dPadDirection {
				case .none: state.shapes.insert(.circle)
				case .down: state.patternState.options.dutyCycle = .trig
				case .left: state.patternState.options.dutyCycle = .sixth
				case .right: state.patternState.options.dutyCycle = .half
				case .up: state.patternState.options.dutyCycle = .full
				}
			}
		case .l: state.patternIndex = 1
		case .r: state.patternState.isMuted.toggle()
		case .lr: writeToPattern(1)
		}
	}

	private func handleSquare(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.square); return }

		switch controls.buttons.modifiers {
		case .none:
			if state.pending == nil {
				if let direction = controls.buttons.dPadDirection {
					switch direction {
					case .down: state.bpm = \.bpm § round((state.bpm - 10) / 10) * 10
					case .up: state.bpm = \.bpm § round((state.bpm + 10) / 10) * 10
					case .left: state.stop()
					case .right: state.play()
					}
				} else {
					state.shapes.insert(.square)
				}
			}
		case .l: state.patternIndex = 2
		case .r: save()
		case .lr: writeToPattern(2)
		}
	}

	private func handleTriangle(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.triangle); return }

		switch controls.buttons.modifiers {
		case .none:
			switch controls.buttons.dPadDirection {
			case .none: if state.pending == nil { state.shapes.insert(.triangle) } else { state.toggleCursor() }
			case .down: state.toggleCursor()
			case .left: state.sendMIDI.toggle()
			case .right: state.changePattern.toggle()
			case .up: transmitter.reconnect()
			}
		case .l: state.patternIndex = 3
		case .r: recall()
		case .lr: writeToPattern(3)
		}
	}

	private func writeToPattern(_ idx: Int) {
		if let pending = state.pending {
			state.pending = modify(pending) { $0[idx] = $0[state.patternIndex] }
		} else {
			state.patterns[idx].pattern = state.pattern
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
					let ddx = dx - offset.x
					let ddy = dy - offset.y

					if ddx != 0 || ddy != 0 {
						if ddx != 0 { ptn.shift(ddx, direction: .right) }
						if ddy != 0 { ptn.shift(ddy, direction: .up) }
						offset = (dx, dy)
					}
				}
			} else if offset.x != 0 || offset.y != 0 {
				modify(&state.pendingPattern) { ptn in
					if offset.x != 0 { ptn.shift(offset.x, direction: .left) }
					if offset.y != 0 { ptn.shift(offset.y, direction: .down) }
				}
			}
			if controls.leftTrigger > 1 / 255 || controls.rightTrigger > 1 / 255 {
				state.swing = (swing + controls.rightTrigger - controls.leftTrigger).clamped(to: -1...1)
			} else {
				state.swing = swing
			}
		} else {
			offset = (0, 0)
			swing = state.swing
		}
	}

	private func save() {
		store = state
	}

	private func recall() {
		state = store
	}
}
