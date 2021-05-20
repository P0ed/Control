#include <ArduinoBLE.h>

const char deviceName[] = "Nano 33 Ctrl";
BLEService ctrlService("E20A39F4-73F5-4BC4-A12F-17D1AD07A962");

BLEFloatCharacteristic clockBPMCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D5", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEShortCharacteristic patternCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D6", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueACharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D7", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueBCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D8", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEShortCharacteristic controlsCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D9", BLERead | BLEWrite | BLEWriteWithoutResponse);

BLEDevice central = BLE.central();

struct Pattern {
  short bits;

  const static struct Pattern straight;
};

const struct Pattern Pattern::straight = {
  .bits = 1 << 0 | 1 << 4 | 1 << 8 | 1 << 12 
};

struct State {
  unsigned long lastTick;
  float clockBPM;
  char idx;
  Pattern pattern;
  Pattern nextPattern;
  float valueA;
  float valueB;
};

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .idx = 0,
  .pattern = Pattern::straight,
  .nextPattern = Pattern::straight,
  .valueA = 0, 
  .valueB = 0 
};

void setup() {
  Serial.begin(9600);
  // begin BLE:
  if (BLE.begin()) {
    BLE.setLocalName(deviceName);
    BLE.setDeviceName(deviceName);

    BLE.setAdvertisedService(ctrlService);

    ctrlService.addCharacteristic(clockBPMCharacteristic);
    ctrlService.addCharacteristic(patternCharacteristic);
    ctrlService.addCharacteristic(valueACharacteristic);
    ctrlService.addCharacteristic(valueBCharacteristic);
    ctrlService.addCharacteristic(controlsCharacteristic);

    BLE.addService(ctrlService);
    BLE.advertise();
  } else {
    Serial.println("starting BLE failed.");
    while (true);
  }

  pinMode(D2, OUTPUT);
  pinMode(D3, OUTPUT);
  pinMode(D4, OUTPUT);
  pinMode(D5, OUTPUT);

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
  valueACharacteristic.setEventHandler(BLEWritten, didChangeValueA);
  valueBCharacteristic.setEventHandler(BLEWritten, didChangeValueB);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
}

void loop() {
//  BLEDevice central = BLE.central();
//
//  if (central) {
//    Serial.print("Connected to central: ");
//    Serial.println(central.address());
//
//    while (central.connected()) {}
//
//    Serial.print("Disconnected from central: ");
//    Serial.println(central.address());
//  }

  runClockIfNeeded();
}

void runClockIfNeeded() {
  if (!state.clockBPM) return;

  const auto nextTick = state.lastTick + state.clockBPM / 60 / 1000 / 2;
  const auto clock = millis();
  if (clock > nextTick) {
    state.idx = state.idx + 1 % 32;
    state.lastTick = clock;
    if (state.idx == 0) {
      state.pattern = state.nextPattern;
    }
    digitalWrite(D2, state.idx % 2 ? HIGH : LOW);
    digitalWrite(D3, state.pattern.bits & 1 << state.idx / 2 ? HIGH : LOW);
  }
}

void start() {
  state.lastTick = millis();
  state.idx = 0;
}

void stop() {
  digitalWrite(D2, LOW);
  digitalWrite(D3, LOW);
}

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  const float oldValue = state.clockBPM;
  memcpy(&state.clockBPM, (unsigned char*)characteristic.value(), characteristic.valueSize());

  if (!state.clockBPM != !oldValue) {
    state.clockBPM ? start() : stop();
  }
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.nextPattern, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangeValueA(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueA, (unsigned char*)characteristic.value(), characteristic.valueSize());
  analogWrite(D4, short(state.valueA * 1023));
}

void didChangeValueB(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueB, (unsigned char*)characteristic.value(), characteristic.valueSize());
  analogWrite(D5, short(state.valueB * 1023));
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char*)characteristic.value(), characteristic.valueSize());
}
