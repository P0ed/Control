import SwiftUI
import Combine
import Fx

struct MainView: View {
	@ObservedObject var model: Model

	var state: State { model.state }
	var controls: Controls { model.controls }

	var body: some View {
		ZStack {
			model.color
				.ignoresSafeArea()
			VStack {
				Spacer()
				Spacer()
				globalStatus
				Spacer()
				pattern
				Spacer()
				patternStatus
				Spacer()
				Spacer()
			}
		}
	}

	var globalStatus: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(alignment: .top) {
				Text("bpm: \(String(format: "%.1f", state.bpm))")
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(state.transport.fold(
						stoped: const § .text.opacity(0.2),
						paused: const § .text.opacity(0.4),
						playing: const § .text
					))
					.frame(maxWidth: .infinity, alignment: .leading)
				Text("⚡︎\(String(format: "%.0f", model.battery * 100))%")
					.font(.system(.body, design: .monospaced))
					.foregroundColor(.text)
			}
			Text("bank: \(state.bankIndex)")
				.font(.system(.title2, design: .monospaced))
				.foregroundColor(.text)
			Text("transport: \(state.sendMIDI ? "midi" : "analog")")
				.font(.system(.body, design: .monospaced))
				.foregroundColor(.text)
			Text(state.statusString)
				.font(.system(.title, design: .monospaced))
				.foregroundColor(.text)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal)
	}

	@ViewBuilder var pattern: some View {
		let l = controls.buttons.contains(.shiftLeft)
		let r = controls.buttons.contains(.shiftRight)
		let bankIdx = controls.leftStick.shape?.rawValue ?? state.bankIndex
		let quad = l ? state.pending ?? state.patterns : r ? state.banks[bankIdx] : nil
		let sp = 12 as Double
		let side = (360 - sp) / 2 as Double

		if let quad = quad {
			quad.map { PatternView(state: $0, spacing: 12, side: side) }
		} else {
			PatternView(
				state: state.pendingPatternState,
				idx: state.cursor,
				spacing: 12,
				side: 360
			)
		}
	}

	var patternStatus: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack {
				let ls = controls.leftStick.shape
				let rs = controls.rightStick.shape

				Text("pattern: \(state.patternIndex)")
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(.text)
					.frame(maxWidth: .infinity, alignment: .leading)
				Text((ls ?? .cross).altSymbol)
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(ls == nil ? .clear : .text)
				Text((rs ?? .cross).altSymbol)
					.font(.system(.largeTitle, design: .monospaced))
					.foregroundColor(rs == nil ? .clear : .text)
			}


			Text(state.patternState.options.dutyCycle.string)
				.font(.system(.headline, design: .monospaced))
				.foregroundColor(.text)

			Text("euclidean: \(state.patternState.euclidean)")
				.font(.system(.headline, design: .monospaced))
				.foregroundColor(state.patternState.euclidean == 0 ? .clear : .text)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal)
	}
}

private extension State {
	var statusString: String {
		shapes.isEmpty ? changePattern ? "*" : "•" : shapes.map(\.symbol).reduce("", +)
	}
}

extension Model {
	var color: Color {
		isControllerConnected ? isBLEConnected ? .base : .bleDisconnected : .controllerDisconnected
	}
}
