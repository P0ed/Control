#include <ArduinoBLE.h>

BLEFloatCharacteristic clockCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D5", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEIntCharacteristic patternCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D6", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueACharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D7", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueBCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D8", BLERead | BLEWrite | BLEWriteWithoutResponse);

void setup() {
  pinMode(A7, OUTPUT);
  digitalWrite(A7, HIGH);

  BLEDevice central = BLE.central();
}

void loop() {

}
