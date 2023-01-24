import Foundation
import Fx

extension PatternState {

	mutating func incEuclidean() {
		euclidean = (euclidean + 1) % (pattern.count + 1)
		pattern = bjorklund(high: euclidean)
	}
	mutating func decEuclidean() {
		euclidean = (euclidean + pattern.count) % (pattern.count + 1)
		pattern = bjorklund(high: euclidean)
	}

	private func bjorklund(high: Int) -> Pattern {
		guard high != 0 else { return modify(pattern) { $0.bits = 0 } }

		return modify(pattern) { ptn in
			ptn[0] = true
			(1..<pattern.count).forEach { i in
				ptn[i / pattern.cols * 8 + i % pattern.cols] = (high * i) / pattern.count != (high * (i - 1)) / pattern.count
			}
		}
	}
}
