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

	var pattern: some View {
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
			Text("*")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(model.state.controls.contains(.changePattern) ? .clear : .text)

			let dutyCycle = model.state.patternState.options.dutyCycle.fold(
				trig: "t", quarter: "q", half: "h", full: "f"
			)
			Text(dutyCycle)
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(.text)

			Text("\(model.state.patternState.euclidean)")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(model.state.patternState.euclidean == 0 ? .clear : .text)
		}
	}

	var global: some View {
		VStack {
			let bpmHidden = model.state.bpm == 0 || !model.state.controls.contains(.run)
			let swingHidden = bpmHidden || model.state.swing == 0

			storedField

			Text("\(String(format: "%.1f", model.state.bpm))")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(bpmHidden ? .text.opacity(0.2) : .text)
			Text("\(String(format: "%.0f%", model.state.swing * 50))")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(swingHidden ? .text.opacity(0.2) : .text)
		}
	}

	var storedField: some View {
		let l = model.controls.buttons.contains(.shiftLeft)
		let r = model.controls.buttons.contains(.shiftRight)
		let field = model.state.pending ?? (l ? model.state.field : r ? model.storedField : nil)
		let side = (320 - 12 * 3) / 4 as Double

		return HStack(spacing: 12) {
			if let field = field {
				PatternView(state: field[0], side: side)
				PatternView(state: field[1], side: side)
				PatternView(state: field[2], side: side)
				PatternView(state: field[3], side: side)
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
