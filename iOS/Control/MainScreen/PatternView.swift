import SwiftUI
import Combine

struct PatternView: View {
	var pattern: Pattern
	var idx = nil as Int?

	var body: some View {
		VStack(spacing: Self.spacing) {
			ForEach(0..<pattern.rows, id: \.self) { row in
				HStack(spacing: Self.spacing) {
					ForEach(0..<pattern.cols, id: \.self) { col in
						let isSelected = idx == row * 8 + col
						let isOn = pattern[row * 8 + col]
						let isMuted = pattern.isMuted

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
		32 / Double(max(pattern.cols, pattern.rows))
	}
	private var cellWidth: Double {
		(300 - Self.spacing * Double(pattern.cols - 1)) / Double(pattern.cols)
	}
	private var cellHeight: Double {
		(300 - Self.spacing * Double(pattern.rows - 1)) / Double(pattern.rows)
	}
}
