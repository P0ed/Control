#include "structs.h"
#include "ble.h"
#include "nrf.h"

State state = {
  .isRunning = false,
  .nextTick = 0,
  .clockBPM = 0,
  .controls = {0},
  .idx = 0,
  .field = Field::empty,
  .pending = Field::empty
};

int pins[6] = { 4, 5, 30, 29, 31, 2 };
int ledPin = 13;

void directWrite(int value) {
  int clr = !isHigh(value, 1) << ledPin;
  int set = isHigh(value, 1) << ledPin;
  for (int i = 0; i < 6; i++) clr |= !isHigh(value, i) << pins[i];
  for (int i = 0; i < 6; i++) set |= isHigh(value, i) << pins[i];
  if (clr) NRF_P0->OUTCLR = clr;
  if (set) NRF_P0->OUTSET = set;
}

void setup() {
  initBLE();
  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);

  int outputs = 1 << ledPin;
  for (int i = 0; i < 6; i++) outputs |= 1 << pins[i];
  NRF_P0->DIRSET = outputs;
}

void loop() {
  runClockIfNeeded(micros());
  loopBLE();
}

void runClockIfNeeded(unsigned long t) {
  if (state.controls.isRunning() && state.clockBPM) run(t);
  else if (state.isRunning && !state.controls.isRunning()) stop();
}

void run(unsigned long t) {
  if (!state.isRunning) state.start(t);
  if (state.shouldTick(t)) directWrite(state.tick());
}

void stop() {
  state.reset();
  directWrite(0);
}

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.clockBPM, (unsigned char *)characteristic.value(), characteristic.valueSize());
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.pending, (unsigned char *)characteristic.value(), characteristic.valueSize());
  if (state.controls.isChangePattern()) state.field = state.pending;
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char *)characteristic.value(), characteristic.valueSize());
}
