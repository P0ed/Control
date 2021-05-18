import Foundation
import Combine

struct OSStatusError: Error {
	var code: Int
}

extension OSStatusError {

	static func run(_ f: () -> OSStatus) throws {
		let val = f()
		if val != 0 { throw OSStatusError(code: Int(val)) }
	}

	static func run<A>(_ f: (UnsafeMutablePointer<A>) -> OSStatus) throws -> A {
		let ptr = UnsafeMutablePointer<A>.allocate(capacity: MemoryLayout<A>.size)
		defer { ptr.deallocate() }
		try run { f(ptr) }
		return ptr.pointee
	}
}
