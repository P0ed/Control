#include "pwm.h"
#include "structs.h"
#include "ble.h"

State state = {
  .lastTick = 0,
  .clockBPM = 0,
  .idx = 0,
  .pattern = Pattern::empty,
  .nextPattern = Pattern::empty,
  .valueA = {0, 0, 0},
  .valueB = {0, 0, 0},
  .controls = {0}
};

void setup() {
//  Serial.begin(9600);

  initBLE();
  initPWM();

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
  valueACharacteristic.setEventHandler(BLEWritten, didChangeValueA);
  valueBCharacteristic.setEventHandler(BLEWritten, didChangeValueB);

//  Serial.println("did setup");
}

void loop() {
  const unsigned long clock = millis();
  runClockIfNeeded(clock);

//  static const auto pi = acos(-1);
//  static const float am = state.valueB;
//  static const float fm = 1;
//  static const float acA = sin(clock / oneTick() / pi / fm) * am;
  setPWM(state.valueA.offset, state.valueB.offset);
  
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
      digitalWrite(D6, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D5, patternValue && !isMuted ? HIGH : LOW);

      state.idx = (state.idx + 1) % (state.pattern.count * 2);
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
  
//  Serial.print("did change clock");
//  Serial.println(state.clockBPM);
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.nextPattern, (unsigned char*)characteristic.value(), characteristic.valueSize());

//  Serial.print("did change pattern ");
//  Serial.println(state.nextPattern.bits);
}

void didChangeValueA(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueA, (unsigned char*)characteristic.value(), characteristic.valueSize());
  
//  Serial.println("did change a");
}

void didChangeValueB(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueB, (unsigned char*)characteristic.value(), characteristic.valueSize());
  
//  Serial.println("did change b");
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char*)characteristic.value(), characteristic.valueSize());
  
//  Serial.print("did change ctrls ");
//  Serial.println(state.controls.bits);
}
