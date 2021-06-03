#include "pwm.h"
#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .idx = 0,
  .pattern = Pattern::empty,
  .nextPattern = Pattern::empty,
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
  const unsigned long clock = millis();
  runClockIfNeeded(clock);

  static const auto pi = acos(-1);
  static const float am = state.valueB;
  static const float fm = 1;
  static const float acA = sin(clock / oneTick() / pi / fm) * am;
  setPWM(state.valueA + acA, state.valueB);
  
  loopBLE();
}

float oneTick() {
  return 60 * 1000 / state.clockBPM / 8;
}

void runClockIfNeeded(const unsigned long clock) {
  if (state.clockBPM && state.controls & Controls::run) {
    const unsigned long nextTick = state.lastTick + oneTick();

    if (clock > nextTick) {
      state.lastTick = clock;
      if (state.idx == 0 || (state.controls & Controls::changePattern)) {
        state.pattern = state.nextPattern;
      }

      const bool isMuted = state.controls & Controls::mute;
      const bool patternValue = state.pattern.isHighAtIndex(state.idx / 2);

      digitalWrite(LED_BUILTIN, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D6, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D5, patternValue && !isMuted ? HIGH : LOW);

      state.idx = (state.idx + 1) % state.pattern.count * 2;
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
}
