import Foundation
import Fx

struct State {
	var bpm: Float
	var swing: Float = 0
	var controls: BLEControls = [.changePattern]
	var field: Field
	var patternIndex: Int = 0
	
	var pending: Field?
	var cursor: Int?
}

extension State {

	var pendingPatternState: PatternState {
		get { pending?[patternIndex] ?? patternState }
		set { (pending?[patternIndex] = newValue) ?? (patternState = newValue) }
	}
	var patternState: PatternState {
		get { field[patternIndex] }
		set { field[patternIndex] = newValue }
	}
	var pendingPattern: Pattern {
		get { pendingPatternState.pattern }
		set { pendingPatternState.pattern = newValue }
	}
	var pattern: Pattern {
		get { patternState.pattern }
		set { patternState.pattern = newValue }
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
