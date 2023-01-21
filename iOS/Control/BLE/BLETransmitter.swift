import CoreBluetooth
import Combine
import Fx

final class BLETransmitter {

	struct Service {
		var peripheral: CBPeripheral
		var clockBPM: CBCharacteristic
		var pattern: CBCharacteristic
		var controls: CBCharacteristic
	}

	private let lifetime: Cancellable
	@MutableProperty
	private(set) var service: Service?

	@Property
	var isConnected: Bool

	let scan: () -> Void

	init() {
		_isConnected = _service.map { $0 != nil }

		let cmd = CentralManagerDelegate()
		let pd = PeripheralDelegate()
		let cm = CBCentralManager(delegate: cmd, queue: .main)
		var peripheral: CBPeripheral?

		lifetime = AnyCancellable { capture([cm, cmd, pd, peripheral]) }

		scan = {
			cm.scanForPeripherals(
				withServices: [.service],
				options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
			)
		}

		cmd.didUpdateState = { [scan] cm in
			guard cm.state == .poweredOn else { return print("Central is not powered on") }
			scan()
		}
		cmd.didDiscover = { cm, p, data, rssi in
			cm.stopScan()
			p.delegate = pd
			cm.connect(p, options: nil)
			peripheral = p
		}
		cmd.didConnect = { cm, p in
			p.discoverServices(nil)
		}
		cmd.didDisconnect = { cm, p, e in
			print(e as Any)
		}

		pd.didDiscoverServices = { p, e in
			try? p.discoverCharacteristics(nil, for: unwrap(p.services?.first))
		}
		pd.didDiscoverCharacteristicsFor = { [_service] p, s, e in
			_service.value = try? BLETransmitter.Service(
				peripheral: p,
				characteristics: s.characteristics ?? []
			)
		}
		pd.didWriteValue = { p, c, e in }
	}
}

extension BLETransmitter.Service {

	init(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) throws {
		let find: (CBUUID) throws -> CBCharacteristic = { uuid in
			try unwrap(characteristics.first(where: { $0.uuid == uuid }))
		}
		self = try BLETransmitter.Service(
			peripheral: peripheral,
			clockBPM: find(.clockBPM),
			pattern: find(.pattern),
			controls: find(.controls)
		)
	}

	func write<A>(value: A, for characteristic: KeyPath<Self, CBCharacteristic>) {
		let data = withUnsafeBytes(of: value) { Data($0) }
		peripheral.writeValue(data, for: self[keyPath: characteristic], type: .withoutResponse)
	}

	func setClock(_ clock: BLEClock) {
		write(value: clock, for: \.clockBPM)
	}
	func setPattern(_ pattern: BLEField) {
		write(value: pattern, for: \.pattern)
	}
	func setControls(_ value: BLEControls) {
		write(value: value, for: \.controls)
	}
}

struct BLEClock: Hashable {
	var bpm: Float
	var swing: Float
}

extension State {
	var bleClock: BLEClock { BLEClock(bpm: bpm, swing: swing) }
}
