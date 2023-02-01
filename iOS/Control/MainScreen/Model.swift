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
	@Published private(set) var controllerBattery: Float?

	private var lifetime: Any?

	init(transmitter: Transmitter, controller: Controller) {
		self.transmitter = transmitter
		self.controller = controller

		self.state = modify(_store.value) { $0.transport = .stopped }

		lifetime = [
			transmitter.$service.observe(.main, handleService),
			published,
			controlsMap,
			dPadMap,
			combos
		]

		UIApplication.shared.isIdleTimerDisabled = true
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

	private var published: Any {
		[
			transmitter.$isConnected.observe(.main) { self.isBLEConnected = $0 },
			controller.$batteryLevel.observe(.main) { self.controllerBattery = $0 },
			controller.$controls.observe(.main) { self.controls = $0 },
		]
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
			sequence([.l1, .r1], { self.state.flipFlop.toggle() }),
			sequence([.r1, .l1], { self.state.flipFlop.toggle() }),
			sequence([.up, .up, .up, .down, .down, .down], { set(.techno) }),
			sequence([.up, .up, .up, .down, .down, .right], { set(.lazerpresent) }),
			sequence([.left, .left, .up, .down, .right, .right], { set(.trance) }),
			sequence([.left, .left, .left, .left, .left, .left], { set(.claps) }),
			sequence([.right, .right, .right, .right, .right, .right], { set(.hats) }),
			sequence([.up, .up, .up, .up, .up, .up], { set(.all) }),
			sequence([.down, .down, .down, .down, .down, .down], { set(.empty) }),
			sequence([.down, .up, .down, .up, .down, .up], { mod { $0.inverse() } }),
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

	private func handleDPad(_ direction: Direction) {
		guard let patterns = state.pending else { return }

		switch controls.buttons.modifiers {
		case []: moveCursor(direction: direction)
		case [.l1, .r1]: state.pending = modify(patterns) { $0[state.patternIndex].pattern.shift(direction: direction) }
		case .l1: state.pending = modify(patterns) { $0[state.patternIndex].pattern.modifySize(subtract: true, direction: direction) }
		case .r1: state.pending = modify(patterns) { $0[state.patternIndex].pattern.modifySize(subtract: false, direction: direction) }
		default: break
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
		case []:
			if let pending = state.pending {
				if let idx = state.cursor {
					state.pending = modify(pending) { $0[state.patternIndex].pattern[idx].toggle() }
				}
			} else {
				switch controls.buttons.dPadDirection {
				case .none:
					if state.flipFlop {
						state.patterns[0].isMuted.toggle()
					} else {
						state.shapes.insert(.cross)
					}
				case .down: state.patternState.decEuclidean()
				case .up: state.patternState.incEuclidean()
				case .left: state.pattern.double()
				case .right: state.pattern.genRule90()
				}
			}
		case [.l1, .r1]: writeToPattern(0)
		case .l1: state.patternIndex = 0
		case .l2: state.bankIndex = 0
		case .r2: state.transport == .playing ? state.stop() : state.play()
		default: break
		}
	}

	private func handleCircle(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.circle); return }

		switch controls.buttons.modifiers {
		case []:
			if state.pending != nil {
				state.pending = nil
				state.cursor = nil
			} else {
				switch controls.buttons.dPadDirection {
				case .none:
					if state.flipFlop {
						state.patterns[1].isMuted.toggle()
					} else {
						state.shapes.insert(.circle)
					}
				case .down: state.patternState.options.dutyCycle = .trig
				case .left: state.patternState.options.dutyCycle = .sixth
				case .right: state.patternState.options.dutyCycle = .half
				case .up: state.patternState.options.dutyCycle = .full
				}
			}
		case [.l1, .r1]: writeToPattern(1)
		case .l1: state.patternIndex = 1
		case .l2: state.bankIndex = 1
		case .r2: state.transport = .stopped
		default: break
		}
	}

	private func handleSquare(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.square); return }

		switch controls.buttons.modifiers {
		case []:
			if state.pending == nil {
				if let direction = controls.buttons.dPadDirection {
					switch direction {
					case .down: state.bpm = \.bpm § round((state.bpm - 10) / 10) * 10
					case .up: state.bpm = \.bpm § round((state.bpm + 10) / 10) * 10
					case .left: state.bpm = \.bpm § state.bpm / 4 * 3
					case .right: state.bpm = \.bpm § state.bpm / 3 * 4
					}
				} else if state.flipFlop {
					state.patterns[2].isMuted.toggle()
				} else {
					state.shapes.insert(.square)
				}
			}
		case [.l1, .r1]: writeToPattern(2)
		case .l1: state.patternIndex = 2
		case .l2: state.bankIndex = 2
		case .r2: store = state
		default: break
		}
	}

	private func handleTriangle(_ pressed: Bool) {
		guard pressed else { state.shapes.remove(.triangle); return }

		switch controls.buttons.modifiers {
		case []:
			switch controls.buttons.dPadDirection {
			case .none:
				if state.pending == nil {
					if state.flipFlop {
						state.patterns[3].isMuted.toggle()
					} else {
						state.shapes.insert(.triangle)
					}
				} else {
					state.toggleCursor()
				}
			case .down: state.toggleCursor()
			case .left: state.sendMIDI.toggle()
			case .right: state.changePattern.toggle()
			case .up: transmitter.reconnect()
			}
		case [.l1, .r1]: writeToPattern(3)
		case .l1: state.patternIndex = 3
		case .l2: state.bankIndex = 3
		case .r2: state = store
		default: break
		}
	}

	private func writeToPattern(_ idx: Int) {
		if let pending = state.pending {
			state.pending = modify(pending) { $0[idx] = $0[state.patternIndex] }
		} else {
			state.patterns[idx].pattern = state.pattern
		}
	}
}
