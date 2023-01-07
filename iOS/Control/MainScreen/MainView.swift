import SwiftUI
import Combine

struct MainView: View {
	@ObservedObject var model: Model

	var body: some View {
		ZStack {
			Color(model.color).ignoresSafeArea()
			VStack {
				Spacer()
				Spacer()
				Text("\(model.state.patternIndex)")
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(.text)
				Spacer()
				PatternView(
					pattern: model.state.pending?[model.state.patternIndex] ?? model.state.field[model.state.patternIndex],
					idx: model.state.cursor
				)
				Spacer()
				Text("\(String(format: "%.1f", model.state.bpm))")
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(model.state.bpm == 0 || !model.state.bleControls.contains(.run) ? .clear : .text)
				Spacer()
				Spacer()
			}
		}
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
