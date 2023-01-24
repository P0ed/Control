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
	}

	private static let spacing = 12 as Double

	private var cellRadius: Double {
		32 / Double(max(state.pattern.cols, state.pattern.rows))
	}
	private var cellWidth: Double {
		(300 - Self.spacing * Double(state.pattern.cols - 1)) / Double(state.pattern.cols)
	}
	private var cellHeight: Double {
		(300 - Self.spacing * Double(state.pattern.rows - 1)) / Double(state.pattern.rows)
	}
}
