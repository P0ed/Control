#include "structs.h"
#include "ble.h"
#include "nrf.h"

static const int pinsCount = 7;
static const int pinsMask = 0x7F;
static const int pins[pinsCount] = { 4, 5, 30, 29, 31, 2, 13 };

void setup() {
  setupPins();

  initBLE();
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
}

void loop() {
  handleControls();
  runClockIfNeeded(micros());
  loopBLE();
}

static void handleControls() {
  if (state.changedControls) return;
  directWrite(state.controls.shapes(), pinsMask ^ (state.changedControls & 0xF));
  state.changedControls = 0;
}

static void runClockIfNeeded(unsigned long t) {
  if (state.controls.isRunning() && state.controls.bpm) run(t);
  else if (state.isRunning && !state.controls.isRunning()) stop();
}

static void run(unsigned long t) {
  if (!state.isRunning) start(t);
  if (state.shouldTick(t)) directWrite(state.tick(t), state.controls.shapes());
  if (state.hasExpiredTrigs(t)) directClear(state.consumeTrigs(), state.controls.shapes());
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
  directClear(0x7F, state.controls.shapes());
}

static int setupPins() {
  int activePins = 1 << pins[6];
  int pinsCount = state.midi ? 5 : 6;
  for (int i = 0; i < pinsCount; i++) activePins |= 1 << pins[i];

  NRF_P0->DIRSET = activePins;
  NRF_P0->DIRCLR = state.midi ? 1 << pins[5] : 0;
  if (state.midi) NRF_P0->OUTSET = 1 << pins[4];
}

static void setPins(int value, int excluding, volatile uint32_t *destination) {
  int set = 0;
  const int mask = pinsMask ^ (excluding | (state.midi ? (1 << 4) | (1 << 5) : 0));
  for (int i = 0; i < pinsCount; i++) set |= ((value & mask & (1 << i)) != 0) << pins[i];
  if (set) *destination = set;
}

static void directSet(int value, int excluding) { setPins(value, excluding, &NRF_P0->OUTSET); }
static void directClear(int value, int excluding) { setPins(value, excluding, &NRF_P0->OUTCLR); }
static void directWrite(int value, int excluding) { directClear(~value, excluding); directSet(value, excluding); }

static void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.pending, characteristic.value(), characteristic.valueSize());
  if (state.controls.isChangePattern()) state.quad = state.pending;
}

static void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  short last = state.controls.bits;
  memcpy(&state.controls, characteristic.value(), characteristic.valueSize());
  state.changedControls |= last ^ state.controls.bits;
}
