import SwiftUI

struct ContentView: View {
	var transmitter: BLETransmitter
	var controller: Controller

    var body: some View {
		Spacer()
		Button("Scan", action: transmitter.scan)
		Spacer()
		Button("Connect") { [d = IO(copy: nil as Any?)] in
			var a = 0 as Float
			var b = 0 as Float
			var clock = 0 as Float

			d.value = [
				transmitter.$service.observe { service in
					print("service:", service.map(String.init(describing:)) ?? "nil")
				},
				controller.$rightStick.observe {
					if abs($0.x - a) > 0.01 {
						a = $0.x
						transmitter.service?.setValueA(a)
					}
					if abs($0.y - b) > 0.01 {
						b = $0.y
						transmitter.service?.setValueB(b)
					}
				},
				Timer.repeat(1 / 16) {
					if clock == 0, abs(controller.leftStick.y) < 0.4 { return }
					var newClock = min(max(clock + controller.leftStick.y * 4, -420), 420)
					if abs(newClock) < 0.5 { newClock = 0 }

					if abs(newClock - clock) > 0.33 {
						clock = newClock
						transmitter.service?.setClock(newClock)
					}
				}
			]
		}
		Spacer()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(
			transmitter: BLETransmitter(),
			controller: Controller()
		)
	}
}
