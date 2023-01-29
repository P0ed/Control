import Foundation

struct Quad<Element>: MutableCollection, RandomAccessCollection {
	var first: Element
	var second: Element
	var third: Element
	var fourth: Element

	var startIndex: Int { 0 }
	var endIndex: Int { 4 }
	func index(after i: Int) -> Int { (i + 1) % 4 }

	subscript(_ idx: Int) -> Element {
		get {
			switch idx % 4 {
			case 0: return first
			case 1: return second
			case 2: return third
			case 3: return fourth
			default: fatalError()
			}
		}
		set {
			switch idx % 4 {
			case 0: first = newValue
			case 1: second = newValue
			case 2: third = newValue
			case 3: fourth = newValue
			default: fatalError()
			}
		}
	}
}

extension Quad {

	init(same: Element) { self = Quad(first: same, second: same, third: same, fourth: same) }

	func map<Transformed>(_ transform: (Element) -> Transformed) -> Quad<Transformed> {
		Quad<Transformed>(first: transform(first), second: transform(second), third: transform(third), fourth: transform(fourth))
	}
}

extension Quad: Codable where Element: Codable {}
extension Quad: Equatable where Element: Equatable {}
extension Quad: Hashable where Element: Hashable {}
