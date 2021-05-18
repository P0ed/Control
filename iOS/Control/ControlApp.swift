import SwiftUI

@main
struct ControlApp: App {
	let transmitter = BLETransmitter()
	let midiReceiver = try! MIDIReceiver()
	let controller = Controller()

	var body: some Scene {
		WindowGroup {
			ContentView(
				clock: nil,
				transmitter: transmitter,
				controller: controller
			)
		}
	}
}
