import Foundation
import Fx

struct PatternState: Codable {
	var pattern: Pattern = .empty
	var isMuted: Bool = false
	var options: PatternOptions = .init()
	var euclidean: Int = 0
}

struct PatternOptions: Codable {
	var dutyCycle: DutyCycle = .trig
}

enum DutyCycle: Int, Codable { case trig, sixth, half, full }

extension DutyCycle {
	func fold<A>(trig: @autoclosure () -> A, sixth: @autoclosure () -> A, half: @autoclosure () -> A, full: @autoclosure () -> A) -> A {
		switch self {
		case .trig: return trig()
		case .sixth: return sixth()
		case .half: return half()
		case .full: return full()
		}
	}
	var string: String {
		fold(trig: "trig", sixth: "sixth", half: "half", full: "full")
	}
}
