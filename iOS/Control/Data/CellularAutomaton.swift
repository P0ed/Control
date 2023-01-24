import Foundation
import Foundation

extension Pattern {

	mutating func genRule90() {
		(0..<count).forEach { [ptn = self] idx in
			self[linear: idx] = ptn[linear: idx - 1] != ptn[linear: idx + 1]
		}
	}
}
