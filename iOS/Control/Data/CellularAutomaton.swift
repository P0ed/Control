import Foundation
import Foundation

extension Pattern {

	mutating func genRule90() {
		(0..<count).forEach { [ptn = self] idx in
			self[idx] = ptn[idx == 0 ? count - 1 : idx - 1] != ptn[idx == count - 1 ? 0 : idx + 1]
		}
	}
}
