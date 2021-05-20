import CoreBluetooth
import Combine

final class BLETransmitter {

	struct Service {
		var peripheral: CBPeripheral
		var clockBPM: CBCharacteristic
		var pattern: CBCharacteristic
		var valueA: CBCharacteristic
		var valueB: CBCharacteristic
		var controls: CBCharacteristic
	}

	private let lifetime: Cancellable
	@MutableProperty
	private var service: Service?

	@Property
	var isConnected: Bool

	init() {
		_isConnected = _service.map { $0 != nil }

		let cmd = CentralManagerDelegate()
		let pd = PeripheralDelegate()
		let cm = CBCentralManager(delegate: cmd, queue: .main)

		lifetime = AnyCancellable { capture([cm, cmd, pd]) }

		cmd.didUpdateState = { cm in
			if cm.state != .poweredOn {
				print("Central is not powered on")
			} else {
				cm.scanForPeripherals(
					withServices: [.service],
					options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
				)
			}
		}
		cmd.didDiscover = { cm, p, data, rssi in
			print("didDiscover \(p)")
			cm.stopScan()
			p.delegate = pd
			cm.connect(p, options: nil)
		}
		cmd.didConnect = { cm, p in
			print("Connected")
			p.discoverServices([.service])
		}

		pd.didDiscoverServices = { p, e in
			print("didDiscoverServices \(p.services ?? [])")
			try? p.discoverCharacteristics([.clockBPM, .pattern, .valueA, .valueB], for: unwrap(p.services?.first))
		}
		pd.didDiscoverCharacteristicsFor = { [_service] p, s, e in
			print("didDiscoverCharacteristics \(s.characteristics ?? [])")
			_service.value = try? BLETransmitter.Service(
				peripheral: p,
				characteristics: s.characteristics ?? []
			)
		}
	}

	func setClock(_ clock: Float) {
		service?.write(value: clock, for: \.clockBPM)
	}
	func setPattern(_ pattern: Int16) {
		service?.write(value: pattern, for: \.pattern)
	}
	func setValueA(_ value: Float) {
		service?.write(value: value, for: \.valueA)
	}
	func setValueB(_ value: Float) {
		service?.write(value: value, for: \.valueB)
	}
	func setControls(_ value: Int16) {
		service?.write(value: value, for: \.controls)
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
			valueA: find(.valueA),
			valueB: find(.valueB),
			controls: find(.controls)
		)
	}

	func write<A>(value: A, for characteristic: KeyPath<Self, CBCharacteristic>) {
		let data = withUnsafeBytes(of: value) { Data($0) }
		peripheral.writeValue(data, for: self[keyPath: characteristic], type: .withoutResponse)
	}
}
