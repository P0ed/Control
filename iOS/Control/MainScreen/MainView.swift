import SwiftUI
import Combine
import Fx

struct MainView: View {
	@ObservedObject var model: Model

	var body: some View {
		ZStack {
			Color(model.color).ignoresSafeArea()
			VStack {
				Spacer()
				Spacer()
				global
				Spacer()
				pattern
				Spacer()
				patternStatus
				Spacer()
				Spacer()
			}
		}
	}

	var pattern: PatternView {
		PatternView(
			state: model.state.pendingPatternState,
			idx: model.state.cursor
		)
	}

	var patternStatus: some View {
		VStack {
			Text("\(model.state.patternIndex)")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(.text)

			let dutyCycle = model.state.patternState.options.dutyCycle.fold(
				trig: "trig", sixth: "sixth", half: "half", full: "full"
			)
			Text(dutyCycle)
				.font(.system(.body, design: .monospaced))
				.foregroundColor(.text)

			Text("\(model.state.patternState.euclidean)")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(model.state.patternState.euclidean == 0 ? .clear : .text)
		}
	}

	var global: some View {
		VStack {
			storedField
			Text("\(String(format: "%.1f", model.state.bpm))")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(model.state.transport.fold(
					stoped: const § .text.opacity(0.2),
					paused: const § .text.opacity(0.4),
					playing: const § .text
				))
			Text(model.state.sendMIDI ? "midi" : "analog")
				.font(.system(.body, design: .monospaced))
				.foregroundColor(.text)
			Text(shapesString)
				.font(.system(.body, design: .monospaced))
				.foregroundColor(.text)
		}
	}

	private var shapesString: String {
		let chPattern = model.state.changePattern ? "*" : "•"
		return model.state.shapes.isEmpty ? chPattern : model.state.shapes.reduce("") {
			switch $1 {
			case .cross: return $0 + "♥︎"
			case .circle: return $0 + "♠︎"
			case .square: return $0 + "♦︎"
			case .triangle: return $0 + "♣︎"
			}
		}
	}

	var storedField: some View {
		let l = model.controls.buttons.contains(.shiftLeft)
		let r = model.controls.buttons.contains(.shiftRight)
		let quad = model.state.pending ?? (l ? model.state.patterns : r ? model.stored : nil)
		let side = (320 - 12 * 3) / 4 as Double

		return HStack(spacing: 12) {
			if let quad = quad {
				PatternView(state: quad[0], side: side)
				PatternView(state: quad[1], side: side)
				PatternView(state: quad[2], side: side)
				PatternView(state: quad[3], side: side)
			}
		}
		.frame(height: side)
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
