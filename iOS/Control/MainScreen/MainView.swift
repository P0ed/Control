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
				VStack {
					HStack {
						signedByteText(model.controls.leftTrigger, .trailing)
						signedByteText(model.controls.rightTrigger, .leading)
					}
					HStack {
						signedByteText(model.controls.leftStick.x, .trailing)
						signedByteText(model.controls.rightStick.x, .leading)
					}
					HStack {
						signedByteText(model.controls.leftStick.y, .trailing)
						signedByteText(model.controls.rightStick.y, .leading)
					}
				}
			}
		}
	}

	private func signedByteText(_ value: Float, _ alignment: Alignment) -> some View {
		Text("\(Int(min(max(value * 255, -255), 255)))")
			.font(.system(.headline, design: .monospaced))
			.foregroundColor(abs(value) < 1 / 255 ? .clear : .text)
			.frame(width: 64, alignment: alignment)
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
