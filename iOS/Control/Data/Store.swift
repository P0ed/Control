import Foundation
import Fx

extension IO where A: Codable {
	static func store(defaults: UserDefaults = .standard, key: String, fallback: @escaping @autoclosure () -> A) -> IO {
		IO(
			get: {
				defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(A.self, from: $0) } ?? fallback()
			},
			set: { newValue in
				defaults.setValue(try? JSONEncoder().encode(newValue), forKey: key)
			}
		)
	}
}

struct StoredState: Codable {
	var bpm: Float
	var swing: Float
	var patterns: Quad<PatternState>
}

extension StoredState {

	static var empty: StoredState {
		StoredState(bpm: 120, swing: 0, patterns: .init(same: .init()))
	}

	var state: State {
		get { State(bpm: bpm, swing: swing, patterns: patterns) }
		set { bpm = newValue.bpm; swing = newValue.swing; patterns = newValue.patterns }
	}
}

extension State {
	var stored: StoredState {
		get { StoredState(bpm: bpm, swing: swing, patterns: patterns) }
		set { bpm = newValue.bpm; swing = newValue.swing; patterns = newValue.patterns }
	}
}

extension Quad where Element == StoredState {
	static var empty: Quad { Quad(same: .empty) }
}
