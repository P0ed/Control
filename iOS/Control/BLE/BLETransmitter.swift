import CoreBluetooth
import Combine
import Fx

final class Transmitter {

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
	let reconnect: () -> Void

	init() {
		_isConnected = _service.map { $0 != nil }

		let cmd = CentralManagerDelegate()
		let pd = PeripheralDelegate()

		var cm = CBCentralManager(delegate: cmd, queue: .main)
		var peripheral: CBPeripheral?

		reconnect = { [_service] in
			cm = CBCentralManager(delegate: cmd, queue: .main)
			peripheral = nil
			_service.value = nil
		}

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
		cmd.didDisconnect = { [_service] cm, p, e in
			_service.value = nil
			print(e as Any)
		}

		pd.didDiscoverServices = { p, e in
			try? p.discoverCharacteristics(nil, for: unwrap(p.services?.first))
		}
		pd.didDiscoverCharacteristicsFor = { [_service] p, s, e in
			_service.value = try? Transmitter.Service(
				peripheral: p,
				characteristics: s.characteristics ?? []
			)
		}
		pd.didWriteValue = { p, c, e in }
	}
}

extension Transmitter.Service {

	init(peripheral: CBPeripheral, characteristics: [CBCharacteristic]) throws {
		let find: (CBUUID) throws -> CBCharacteristic = { uuid in
			try unwrap(characteristics.first(where: { $0.uuid == uuid }))
		}
		self = try Transmitter.Service(
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

	func setPattern(_ pattern: Quad<BLEPattern>) {
		write(value: pattern, for: \.pattern)
	}
	func setControls(_ value: BLEControls) {
		write(value: value, for: \.controls)
	}
}
