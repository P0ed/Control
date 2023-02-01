import Foundation
import Fx

struct State: Codable {
	var bpm: Float
	var swing: Float
	var banks: Quad<Quad<PatternState>>

	var shapes: Set<Shape>
	var transport: Transport
	var reset: Bool
	var changePattern: Bool
	var sendMIDI: Bool
	var patternIndex: Int
	var bankIndex: Int
	var flipFlop: Bool
	var pending: Quad<PatternState>?
	var cursor: Int?
}

extension State {

	static let empty = State(
		bpm: 120,
		swing: 0,
		banks: .init(same: .init(same: .init())),
		shapes: [],
		transport: .stopped,
		reset: false,
		changePattern: false,
		sendMIDI: false,
		patternIndex: 0,
		bankIndex: 0,
		flipFlop: false
	)

	var patterns: Quad<PatternState> {
		get { banks[bankIndex] }
		set { banks[bankIndex] = newValue }
	}
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

	mutating func play() { transport = .playing }
	mutating func stop() { transport = transport == .playing ? .paused : .stopped }
}

enum Transport: Codable { case stopped, paused, playing }

extension Transport {
	func fold<A>(stoped: () -> A, paused: () -> A, playing: () -> A) -> A {
		switch self {
		case .stopped: return stoped()
		case .paused: return paused()
		case .playing: return playing()
		}
	}
}
