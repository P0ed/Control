import SwiftUI
import Combine

struct PatternView: View {
	var state: PatternState
	var idx = nil as Int?
	var side = 320 as Double

	var body: some View {
		VStack(spacing: spacing) {
			ForEach(0..<state.pattern.rows, id: \.self) { row in
				HStack(spacing: spacing) {
					ForEach(0..<state.pattern.cols, id: \.self) { col in
						let isSelected = idx == row * 8 + col
						let isOn = state.pattern[row * 8 + col]
						let isMuted = state.isMuted

						Color(isSelected ? .cellSelected : isOn ? (isMuted ? .cellMuted : .cellOn) : .cellOff)
							.frame(width: cellDimension(state.pattern.cols), height: cellDimension(state.pattern.rows))
							.cornerRadius(cellRadius)
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

	private var spacing: Double { side / 320 * 12 }

	private var cellRadius: Double { side / 10 / Double(max(state.pattern.cols, state.pattern.rows, 4)) }

	private func cellDimension(_ numberOfItems: Int) -> Double {
		(side - spacing * Double(numberOfItems - 1)) / Double(max(4, numberOfItems))
	}
}
