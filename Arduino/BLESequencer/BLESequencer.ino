#include "structs.h"
#include "ble.h"
#include "nrf.h"

static int pins[6] = { 4, 5, 30, 29, 31, 2 };
static int ledPin = 13;

void setup() {
  setupPins();

  initBLE();
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
}

void loop() {
  runClockIfNeeded(micros());
  loopBLE();
}

static void runClockIfNeeded(unsigned long t) {
  if (state.controls.isRunning() && state.controls.bpm) run(t);
  else if (state.isRunning && !state.controls.isRunning()) stop();
}

static void run(unsigned long t) {
  if (!state.isRunning) start(t);
  if (state.shouldTick(t)) directWrite(state.tick(t));
  if (state.hasExpiredTrigs(t)) directClear(state.consumeTrigs());
}

static void start(unsigned long t) {
  bool midi = state.controls.isMIDI();
  if (midi != state.midi) {
    state.midi = midi;
    if (midi) {
      setupPins();
      MIDISetup();
    } else {
      MIDIDeinit();
      setupPins();
    }
  }
  state.start(t);
}

static void stop() {
  state.stop();
  directWrite(0);
}

static int setupPins() {
  int activePins = 1 << ledPin;
  int pinsCount = state.midi ? 5 : 6;
  for (int i = 0; i < pinsCount; i++) activePins |= 1 << pins[i];

  NRF_P0->DIRSET = activePins;
  NRF_P0->DIRCLR = state.midi ? 1 << pins[5] : 0;
  if (state.midi) NRF_P0->OUTSET = 1 << pins[4];
}

static void directWrite(int value) {
  int clr = !isHigh(value, 5) << ledPin;
  int set = isHigh(value, 5) << ledPin;
  const int pinsCount = state.midi ? 4 : 5;
  for (int i = 0; i < pinsCount; i++) clr |= !isHigh(value, i) << pins[i];
  for (int i = 0; i < pinsCount; i++) set |= isHigh(value, i) << pins[i];
  if (clr) NRF_P0->OUTCLR = clr;
  if (set) NRF_P0->OUTSET = set;
}

static void directClear(int value) {
  int clr = isHigh(value, 5) << ledPin;
  const int pinsCount = state.midi ? 4 : 6;
  for (int i = 0; i < pinsCount; i++) clr |= isHigh(value, i) << pins[i];
  if (clr) NRF_P0->OUTCLR = clr;
}

static void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.pending, (unsigned char *)characteristic.value(), characteristic.valueSize());
  if (state.controls.isChangePattern()) state.quad = state.pending;
}

static void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char *)characteristic.value(), characteristic.valueSize());
}
