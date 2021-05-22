#include "pwm.h"
#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .idx = 0,
  .pattern = Pattern::straight,
  .nextPattern = Pattern::straight,
  .valueA = 0,
  .valueB = 0,
  .controls = {0}
};

void setup() {
  Serial.begin(9600);

  initBLE();
  initPWM();

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
  valueACharacteristic.setEventHandler(BLEWritten, didChangeValueA);
  valueBCharacteristic.setEventHandler(BLEWritten, didChangeValueB);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
}

void loop() {
  runClockIfNeeded();
  setPWM(state.valueA, state.valueB);
  loopBLE();
}

void runClockIfNeeded() {
  if (state.clockBPM) {
    const unsigned long nextTick = state.lastTick + 60 * 1000 / state.clockBPM / 8;
    const unsigned long clock = millis();

    if (clock > nextTick) {
      state.lastTick = clock;
      if (state.idx == 0) {
        state.pattern = state.nextPattern;
      }

      const bool isMuted = state.controls & Controls::mute;
      const bool patternValue = state.pattern.isHighAtIndex(state.idx / 2);
      
      digitalWrite(LED_BUILTIN, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D6, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D5, patternValue && !isMuted ? HIGH : LOW);

      state.idx = (state.idx + 1) % 32;
    }
  } else {
    state.lastTick = 0;
    state.idx = 0;
    digitalWrite(LED_BUILTIN, LOW);
    digitalWrite(D6, LOW);
    digitalWrite(D5, LOW);
  }
}

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.clockBPM, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.nextPattern, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangeValueA(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueA, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangeValueB(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueB, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char*)characteristic.value(), characteristic.valueSize());

  if (state.controls & Controls::nextPattern) {
    state.pattern = state.nextPattern;
  }
}
