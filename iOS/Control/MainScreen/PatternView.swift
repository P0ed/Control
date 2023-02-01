import SwiftUI
import Combine

struct PatternView: View {
	var state: PatternState
	var idx = nil as Int?

	var spacing: Double
	var side: Double

	var body: some View {
		VStack(spacing: spacing) {
			ForEach(0..<state.pattern.rows, id: \.self) { row in
				HStack(spacing: spacing) {
					ForEach(0..<state.pattern.cols, id: \.self) { col in
						let isSelected = idx == row * 8 + col
						let isOn = state.pattern[row * 8 + col]
						let isMuted = state.isMuted
						let side = cellSide

						Color(isOn ? isMuted ? .cellMuted : .cellOn : .cellOff)
							.brightness(isSelected ? 0.3 : 0)
							.frame(width: side, height: side)
							.cornerRadius(radius)
					}
				}
			}
		}
		.frame(
			width: side,
			height: side,
			alignment: .center
		)
	}

	private var maxDimension: Int { max(state.pattern.rows, state.pattern.cols) }
	private var radius: Double { side / 10 / Double(maxDimension) }
	private var cellSide: Double { (side - spacing * Double(maxDimension - 1)) / Double(maxDimension) }
}

extension Quad: View where Element: View {
	var body: some View {
		VStack(spacing: 12) {
			HStack(spacing: 12) {
				self[2]
				self[3]
			}
			HStack(spacing: 12) {
				self[0]
				self[1]
			}
		}
	}
}

extension Color {
	static let cellOff = Color(white: 0.11, opacity: 0.9)
	static let cellOn = Color(white: 0.69, opacity: 0.9)
	static let cellMuted = Color(white: 0.43, opacity: 0.9)
}
