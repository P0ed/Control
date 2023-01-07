#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .idx = 0,
  .pattern = Pattern::empty,
  .nextPattern = Pattern::empty,
  .controls = {0}
};

void setup() {
  Serial.begin(9600);

  initBLE();

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);

  Serial.println("did setup");
}

void loop() {
  const unsigned long clock = millis();
  runClockIfNeeded(clock);
  loopBLE();
}

void runClockIfNeeded(const unsigned long clock) {
  
  if (state.clockBPM && (state.controls & Controls::run)) {
  
    const unsigned long nextTick = state.lastTick + 60 * 1000 / state.clockBPM / 8;

    if (clock > nextTick) {
      state.lastTick = clock;
      if (state.idx == 0 || (state.controls & Controls::changePattern)) {
        state.pattern = state.nextPattern;
      }

      const bool isMuted = state.controls & Controls::mute;
      const bool patternValue = state.pattern.isHighAtIndex(state.idx / 2);

      digitalWrite(LED_BUILTIN, state.idx % 2 ? HIGH : LOW);
      // // clock
      // digitalWrite(A1, state.idx % 2 ? HIGH : LOW);
      // digitalWrite(A2, patternValue && !isMuted ? HIGH : LOW);

      state.idx = (state.idx + 1) % (state.pattern.count * 2);

      digitalWrite(A0, HIGH);
      digitalWrite(A1, HIGH);
      digitalWrite(A2, HIGH);
      digitalWrite(A3, HIGH);
      digitalWrite(A4, HIGH);
      digitalWrite(A5, HIGH);
    }
  } else {
    state.lastTick = 0;
    state.idx = 0;
    digitalWrite(LED_BUILTIN, LOW);
    digitalWrite(A0, LOW);
    digitalWrite(A1, LOW);
    digitalWrite(A2, LOW);
    digitalWrite(A3, LOW);
    digitalWrite(A4, LOW);
    digitalWrite(A5, LOW);
  }
}

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.clockBPM, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.nextPattern, (unsigned char*)characteristic.value(), characteristic.valueSize());
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char*)characteristic.value(), characteristic.valueSize());
}
