import Foundation

extension Pattern {

	mutating func incEuclidean() {
		euclidean = (euclidean + 1) % (count + 1)
		bits = bjorklund(high: euclidean)
	}
	mutating func decEuclidean() {
		euclidean = euclidean == 0 ? count : (euclidean - 1) % (count + 1)
		bits = bjorklund(high: euclidean)
	}

	private func bjorklund(high: Int) -> UInt64 {
		guard high != 0 else { return 0 }

		var ptn = self
		ptn[0] = true
		(1..<count).forEach { i in
			ptn[i / cols * 8 + i % cols] = (high * i) / count != (high * (i - 1)) / count
		}
		return ptn.mask & ptn.bits
	}
}
