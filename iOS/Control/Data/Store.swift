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
