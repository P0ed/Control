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
						let side = cellDimension(max(state.pattern.rows, state.pattern.cols))

						Color(!isSelected ? isOn ? isMuted ? .cellMuted : .cellOn : .cellOff : .cellSelected)
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

	private var radius: Double { side / 10 / Double(max(state.pattern.cols, state.pattern.rows)) }
	private func cellDimension(_ numberOfItems: Int) -> Double {
		(side - spacing * Double(numberOfItems - 1)) / Double(numberOfItems)
	}
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
