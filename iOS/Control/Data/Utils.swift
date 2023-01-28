import Foundation

import SwiftUI

extension Color {
	static let base = Color.black
	static let bleDisconnected = Color(.sRGB, red: 0.1, green: 0.11, blue: 0.19, opacity: 1)
	static let controllerDisconnected = Color(.sRGB, red: 0.2, green: 0.11, blue: 0.13, opacity: 1)

	static let cellOff = Color(.sRGB, red: 0.26, green: 0.29, blue: 0.31, opacity: 0.8)
	static let cellOn = Color(.sRGB, red: 0.59, green: 0.69, blue: 0.86, opacity: 0.9)
	static let cellMuted = Color(.sRGB, red: 0.53, green: 0.42, blue: 0.58, opacity: 0.9)
	static let cellSelected = Color(.sRGB, red: 0.81, green: 0.79, blue: 0.68, opacity: 0.9)

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

extension Property {
	func observe(_ ctx: ExecutionContext, _ f: @escaping (A) -> Void) -> Disposable {
		observe { x in ctx.run { f(x) } }
	}
}
