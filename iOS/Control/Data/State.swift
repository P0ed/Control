import Foundation
import Fx

struct State {
	var bpm: Float
	var swing: Float = 0
	var patterns: Quad<PatternState>

	var isPlaying = false
	var changePattern = true
	var patternIndex: Int = 0
	var pending: Quad<PatternState>?
	var cursor: Int?
}

extension State {

	var pendingPatternState: PatternState {
		get { pending?[patternIndex] ?? patternState }
		set { (pending?[patternIndex] = newValue) ?? (patternState = newValue) }
	}
	var patternState: PatternState {
		get { patterns[patternIndex] }
		set { patterns[patternIndex] = newValue }
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
			patterns = next
			pending = nil
			cursor = nil
		} else {
			pending = patterns
			cursor = 0
		}
	}
}
