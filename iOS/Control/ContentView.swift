import SwiftUI

struct ContentView: View {
	var clock: Float?
	var transmitter: BLETransmitter
	var controller: Controller

    var body: some View {
		Text(clock.map { "\($0)" } ?? "||")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(
			clock: nil,
			transmitter: BLETransmitter(),
			controller: Controller()
		)
	}
}
