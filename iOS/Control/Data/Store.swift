import Foundation

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
	var field: Field
}

extension StoredState {
	static let initial = StoredState(bpm: 120, field: .empty)

	var state: Model.State {
		get { Model.State(bpm: bpm, field: field) }
		set { bpm = newValue.bpm; field = newValue.field }
	}
}
