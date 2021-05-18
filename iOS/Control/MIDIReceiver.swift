import CoreMIDI
import Combine

final class MIDIReceiver {
	private let client: MIDIClientRef
	private let lifetime: Cancellable

	init() throws {
		client = try OSStatusError.run {
			MIDIClientCreateWithBlock("Control App" as CFString, $0, { n in
				print(n)
			})
		}
		lifetime = AnyCancellable { [client] in MIDIClientDispose(client) }
	}
}
