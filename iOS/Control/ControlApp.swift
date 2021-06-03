import SwiftUI
import Combine

@main
struct ControlApp: App {
	var transmitter = BLETransmitter()
	var controller = Controller()

	var body: some Scene {
		WindowGroup {
			MainView(model: Model(
				transmitter: transmitter,
				controller: controller
			))
		}
	}
}
