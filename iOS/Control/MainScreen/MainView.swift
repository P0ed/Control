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
			pattern: model.state.pending?[model.state.patternIndex] ?? model.state.field[model.state.patternIndex],
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
				.foregroundColor(model.state.bleControls.contains(.changePattern) ? .clear : .text)

			let dutyCycle = model.state.pattern.options.dutyCycle.fold(
				trig: "t", quarter: "q", half: "h", full: "f"
			)
			Text(dutyCycle)
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(.text)

			Text("\(model.state.pattern.euclidean)")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(model.state.pattern.euclidean == 0 ? .clear : .text)
		}
	}

	var global: some View {
		VStack {
			let bpmHidden = model.state.bpm == 0 || !model.state.bleControls.contains(.run)
			let swingHidden = bpmHidden || model.state.swing == 0

			Text("\(String(format: "%.1f", model.state.bpm))")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(bpmHidden ? .clear : .text)
			Text("\(String(format: "%.0f%", model.state.swing * 50))")
				.font(.system(.largeTitle, design: .monospaced))
				.foregroundColor(swingHidden ? .clear : .text)
		}
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
