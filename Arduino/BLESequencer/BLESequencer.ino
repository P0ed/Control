#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .controls = {0},
  .tick = 0,
  .idx = 0,
  .field = Field::empty,
  .pending = Field::empty
};

void setup() {
  initBLE();

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
}

void loop() {
  const unsigned long clock = millis();
  runClockIfNeeded(clock);
  loopBLE();
}

void runClockIfNeeded(const unsigned long clock) {

  if (state.clockBPM && state.controls.isRunning()) {
    const unsigned long oneTick = 1000 * 60 / state.clockBPM / State::ticksPerClock;
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
    state.reset();
  }

  bool clock = state.tick / (State::ticksPerClock / 2) == 0;
  digitalWrite(LED_BUILTIN, clock);
  digitalWrite(A0, HIGH);
  digitalWrite(A1, clock);
  for (int i = 0; i < 4; i++) digitalWrite(
    A2 + i,
    state.field.patterns[i].isHighAtIndex(state.idx) && state.tick == 0
  );

  state.nextStep(time);
}

void stop() {
  digitalWrite(LED_BUILTIN, LOW);
  for (int i = 0; i < 6; i++) digitalWrite(A0 + i, LOW);
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
