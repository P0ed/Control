import SwiftUI
import Combine

struct PatternView: View {
	var state: PatternState
	var idx = nil as Int?

	var body: some View {
		VStack(spacing: Self.spacing) {
			ForEach(0..<state.pattern.rows, id: \.self) { row in
				HStack(spacing: Self.spacing) {
					ForEach(0..<state.pattern.cols, id: \.self) { col in
						let isSelected = idx == row * 8 + col
						let isOn = state.pattern[row * 8 + col]
						let isMuted = state.isMuted

						Color(isSelected ? .cellSelected : isOn ? (isMuted ? .cellMuted : .cellOn) : .cellOff)
							.frame(width: cellWidth, height: cellHeight)
							.cornerRadius(cellRadius)
					}
				}
			}
		}
		.frame(
			width: Self.side,
			height: Self.side,
			alignment: .center
		)
	}

	private static let spacing = 12 as Double
	private static let side = 320 as Double

	private var cellRadius: Double {
		32 / Double(max(state.pattern.cols, state.pattern.rows, 4))
	}
	private static func cellDimension(_ numberOfItems: Int) -> Double {
		(side - spacing * Double(numberOfItems - 1)) / Double(max(4, numberOfItems))
	}
	private var cellWidth: Double { Self.cellDimension(state.pattern.cols) }
	private var cellHeight: Double { Self.cellDimension(state.pattern.rows) }
}
