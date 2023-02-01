import Foundation

import SwiftUI

extension Color {
	static let base = Color(white: 0)
	static let text = Color(white: 0.96)

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
