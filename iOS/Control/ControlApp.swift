import SwiftUI

@main
struct ControlApp: App {
	let transmitter = BLETransmitter()
	let midiReceiver = try! MIDIReceiver()
	let controller = Controller()

	var body: some Scene {
		WindowGroup {
			ContentView(
				transmitter: transmitter,
				controller: controller
			)
		}
	}
}
