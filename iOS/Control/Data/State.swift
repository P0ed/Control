import Foundation
import Fx

struct State {
	var bpm: Float
	var swing: Float = 0
	var bleControls: BLEControls = [.changePattern]
	var field: Field
	var patternIndex: Int = 0
	
	var pending: Field?
	var cursor: Int?
}

extension State {

	var pendingPattern: Pattern {
		get { pending?[patternIndex] ?? pattern }
		set { (pending?[patternIndex] = newValue) ?? (pattern = newValue) }
	}

	var pattern: Pattern {
		get { field[patternIndex] }
		set { field[patternIndex] = newValue }
	}

	mutating func toggleCursor() {
		if let next = pending {
			field = next
			pending = nil
			cursor = nil
		} else {
			pending = field
			cursor = 0
		}
	}
}
