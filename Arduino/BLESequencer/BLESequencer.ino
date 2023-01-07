#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .controls = {0},
  .idx = 0,
  .field = Field::empty,
  .pending = Field::empty
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
  
  if (state.clockBPM && state.controls.isRunning()) {
    const unsigned long oneTick = 1000 * 60 / state.clockBPM / 8;   // Why 8 not 2?
    if (clock > state.lastTick + oneTick) {
      tick(clock);
    }
  } else {
    stop();
  }
}

void tick(unsigned long time) {
  
  if (state.isAtStartOf(0) || state.controls.isChangePattern()) {
    state.field = state.pending;
  }
  if (state.controls.isReset()) {
    state.idx = 0;
  }

  const bool isMuted = state.controls & Controls::mute;

  digitalWrite(LED_BUILTIN, state.idx % 2);
  digitalWrite(A0, HIGH);
  digitalWrite(A1, state.idx % 2);
  digitalWrite(A2, state.field.patterns[0].isHighAtIndex(state.idx / 2) && !isMuted);
  digitalWrite(A3, state.field.patterns[1].isHighAtIndex(state.idx / 2) && !isMuted);
  digitalWrite(A4, state.field.patterns[2].isHighAtIndex(state.idx / 2) && !isMuted);
  digitalWrite(A5, state.field.patterns[3].isHighAtIndex(state.idx / 2) && !isMuted);

  state.nextStep(time);
}

void stop() {
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

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.clockBPM, (unsigned char *)characteristic.value(), characteristic.valueSize());
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.pending, (unsigned char *)characteristic.value(), characteristic.valueSize());
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char *)characteristic.value(), characteristic.valueSize());
}
