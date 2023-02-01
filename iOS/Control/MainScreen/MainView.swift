import SwiftUI
import Combine
import Fx

struct MainView: View {
	@ObservedObject var model: Model

	var state: State { model.state }
	var controls: Controls { model.controls }

	var body: some View {
		ZStack {
			Color.base.ignoresSafeArea()
			VStack {
				Spacer(minLength: 40)
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
		HStack(alignment: .top) {
			VStack(alignment: .leading, spacing: 6) {
				bpmLine
				line(model.patternString, style: .title)
				line("transport: \(state.sendMIDI ? "midi" : "analog")", style: .body)
				line(model.statusString, style: .largeTitle)
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			HStack {
				if model.isBLEConnected {
					line("☮︎", style: .title2)
				}
				if let battery = model.controllerBattery {
					HStack(spacing: 1) {
						line("⚡︎", style: .title2)
						line("\(String(format: "%.0f", battery * 100))", style: .body)
					}
				}
			}
			.padding(.top, 4)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal)
	}

	@ViewBuilder var pattern: some View {
		let bnkIdx = controls.leftStick.shape?.rawValue ?? state.bankIndex
		let ptnIdx = controls.rightStick.shape?.rawValue ?? state.patternIndex

		let sp = 12 as Double
		let side = 360 as Double
		let halfSide = (side - sp) / 2

		if controls.buttons.contains([.l2, .r2]) {
			state.banks[bnkIdx].map { PatternView(state: $0, spacing: sp, side: halfSide) }
		} else {
			PatternView(
				state: (state.pending ?? state.banks[bnkIdx])[ptnIdx],
				idx: state.cursor,
				spacing: sp,
				side: 360
			)
		}
	}

	var patternStatus: some View {
		VStack(alignment: .leading, spacing: 6) {
			line(model.optionsString, style: .body)
			line(model.functionString, style: .body)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.horizontal)
	}

	private var bpmLine: Text {
		Text("bpm: \(String(format: "%.1f", state.bpm))")
			.font(.system(.largeTitle, design: .monospaced))
			.foregroundColor(state.transport.fold(
				stoped: const § .text.opacity(0.2),
				paused: const § .text.opacity(0.4),
				playing: const § .text
			))
	}

	private func line(_ text: String, style: Font.TextStyle) -> Text {
		Text(text)
			.font(.system(style, design: .monospaced))
			.foregroundColor(.text)
	}
}

extension Model {

	var patternString: String {
		let x = controls.leftStick.shape?.altSymbol ?? Shape(state.bankIndex).symbol
		let y = controls.rightStick.shape?.altSymbol ?? Shape(state.patternIndex).symbol
		return "pattern: \(x)\(y)"
	}
	var statusString: String {
		if state.shapes.isEmpty {
			return state.flipFlop ? "•" : state.changePattern ? "⚛" : "*"
		} else {
			return state.shapes.map(\.symbol).reduce("", +)
		}
	}
	var optionsString: String {
		"duty cycle: \(state.patternState.options.dutyCycle.string)"
	}
	var functionString: String {
		if state.patternState.euclidean != 0 {
			return "euclidean: \(state.patternState.euclidean)"
		} else {
			return ""
		}
	}
}
