import SwiftUI

@main
struct ControlApp: App {
	let transmitter = BLETransmitter()
	let controller = Controller()

	var body: some Scene {
		WindowGroup {
			MainView(model: Model(
				transmitter: transmitter,
				controller: controller
			))
		}
	}
}
