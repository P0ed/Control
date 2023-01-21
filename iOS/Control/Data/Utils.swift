import Foundation

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

import SwiftUI

extension Color {
	static let base = Color.black
	static let bleDisconnected = Color(.sRGB, red: 0.1, green: 0.11, blue: 0.19, opacity: 1)
	static let controllerDisconnected = Color(.sRGB, red: 0.2, green: 0.11, blue: 0.13, opacity: 1)

	static let cellOff = Color(.sRGB, red: 0.28, green: 0.33, blue: 0.34, opacity: 0.8)
	static let cellOn = Color(.sRGB, red: 0.5, green: 0.66, blue: 0.83, opacity: 0.8)
	static let cellMuted = Color(.sRGB, red: 0.39, green: 0.52, blue: 0.62, opacity: 0.8)
	static let cellSelected = Color(.sRGB, red: 0.81, green: 0.76, blue: 0.68, opacity: 0.8)

	static let text = Color(.sRGB, red: 0.94, green: 0.96, blue: 0.99, opacity: 1)

	init(_ color: Color) { self = color }
}

extension Float {
	var bpm: Float { min(max(self, 0), 420) }
}

import Fx

extension Fn {

	static func fold<A>(_ true: @escaping @autoclosure () -> A, _ false: @escaping @autoclosure () -> A) -> (Bool) -> A {
		{ $0 ? `true`() : `false`() }
	}

	static func fold<A>(_ true: @escaping () -> A, _ false: @escaping () -> A) -> (Bool) -> A {
		{ $0 ? `true`() : `false`() }
	}
}
