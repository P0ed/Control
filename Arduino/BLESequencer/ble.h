#include <ArduinoBLE.h>

const char deviceName[] = "Nano 33 Ctrl";
BLEService ctrlService("E20A39F4-73F5-4BC4-A12F-17D1AD07A962");

BLEFloatCharacteristic clockBPMCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D5", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<Controls> controlsCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D9", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<Pattern> patternCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D6", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<LFO> valueACharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D7", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLETypedCharacteristic<LFO> valueBCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D8", BLERead | BLEWrite | BLEWriteWithoutResponse);

BLEDevice central;

static void initBLE() {
  if (BLE.begin()) {
    BLE.setLocalName(deviceName);
    BLE.setDeviceName(deviceName);

    BLE.setAdvertisedService(ctrlService);

    ctrlService.addCharacteristic(clockBPMCharacteristic);
    ctrlService.addCharacteristic(controlsCharacteristic);
    ctrlService.addCharacteristic(patternCharacteristic);
    ctrlService.addCharacteristic(valueACharacteristic);
    ctrlService.addCharacteristic(valueBCharacteristic);

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
