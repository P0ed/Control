#include <ArduinoBLE.h>

const char deviceName[] = "Nano 33 Ctrl";
BLEService ctrlService("E20A39F4-73F5-4BC4-A12F-17D1AD07A962");

BLETypedCharacteristic<Clock> clockCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D5", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<Controls> controlsCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D9", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<Field> patternCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D6", BLERead | BLEWrite | BLEWriteWithoutResponse);

BLEDevice central;

static void initBLE() {
  if (BLE.begin()) {
    BLE.setLocalName(deviceName);
    BLE.setDeviceName(deviceName);

    BLE.setAdvertisedService(ctrlService);

    ctrlService.addCharacteristic(clockCharacteristic);
    ctrlService.addCharacteristic(controlsCharacteristic);
    ctrlService.addCharacteristic(patternCharacteristic);

    BLE.addService(ctrlService);
    BLE.advertise();

    central = BLE.central();
    central.connect();
  } else {
    Serial.println("starting BLE failed.");
    while (true);
  }
}

static void loopBLE() {
  central.connected();
}
