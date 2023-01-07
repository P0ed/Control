import SwiftUI
import Combine

struct MainView: View {
	@ObservedObject var model: Model

	var body: some View {
		ZStack {
			Color(model.color).ignoresSafeArea()
			VStack {
				PatternView(
					pattern: model.state.pendingPattern ?? model.state.pattern,
					idx: model.state.pendingIndex
				)
				Text("\(String(format: "%.1f", model.state.bpm))")
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(model.state.bpm == 0 || !model.state.bleControls.contains(.run) ? .clear : .text)
			}
		}
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
