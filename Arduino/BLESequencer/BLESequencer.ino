#include <ArduinoBLE.h>
#include "nrfx_pwm.h"

// MARK: BLE
const char deviceName[] = "Nano 33 Ctrl";
BLEService ctrlService("E20A39F4-73F5-4BC4-A12F-17D1AD07A962");

BLEFloatCharacteristic clockBPMCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D5", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEShortCharacteristic patternCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D6", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueACharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D7", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEFloatCharacteristic valueBCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D8", BLERead | BLEWrite | BLEWriteWithoutResponse);
BLEShortCharacteristic controlsCharacteristic("08590F7E-DB05-467E-8757-72F6FAEB13D9", BLERead | BLEWrite | BLEWriteWithoutResponse);

// MARK: PWM
static nrfx_pwm_t pwm = NRFX_PWM_INSTANCE(0);
static nrf_pwm_values_individual_t seq_values[] = {0, 0, 0, 0};

static nrf_pwm_sequence_t seq = {
  .values = {
    .p_individual = seq_values
  },
  .length          = NRF_PWM_VALUES_LENGTH(seq_values),
  .repeats         = 1,
  .end_delay       = 0
};

// MARK: Patterns
struct Pattern {
  short bits;

  const static struct Pattern straight;
};

const struct Pattern Pattern::straight = {
  .bits = 1 << 0 | 1 << 4 | 1 << 8 | 1 << 12
};

// MARK: State
struct State {
  unsigned long lastTick;
  float clockBPM;
  char idx;
  Pattern pattern;
  Pattern nextPattern;
  float valueA;
  float valueB;
  char controls;
};

State state = {
  .lastTick = 0,
  .clockBPM = 120,
  .idx = 0,
  .pattern = Pattern::straight,
  .nextPattern = Pattern::straight,
  .valueA = 0,
  .valueB = 0,
  .controls = 0
};

BLEDevice central;

void setup() {
  Serial.begin(9600);

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


    central = BLE.central();
    central.connect();
  } else {
    Serial.println("starting BLE failed.");
    while (true);
  }

  initPWM();

  clockBPMCharacteristic.setEventHandler(BLEWritten, didChangeClockBPM);
  patternCharacteristic.setEventHandler(BLEWritten, didChangePattern);
  valueACharacteristic.setEventHandler(BLEWritten, didChangeValueA);
  valueBCharacteristic.setEventHandler(BLEWritten, didChangeValueB);
  controlsCharacteristic.setEventHandler(BLEWritten, didChangeControls);
}

void loop() {
  central.connected();
  runClockIfNeeded();
  setPWM(state.valueA, state.valueB);
}

void runClockIfNeeded() {
  if (state.clockBPM) {
    const unsigned long nextTick = state.lastTick + 60 * 1000 / state.clockBPM / 8;
    const unsigned long clock = millis();

    if (clock > nextTick) {
      state.lastTick = clock;
      if (state.idx == 0) {
        state.pattern = state.nextPattern;;
      }

      digitalWrite(LED_BUILTIN, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D2, state.idx % 2 ? HIGH : LOW);
      digitalWrite(D3, state.pattern.bits & 1 << (state.idx / 2) ? HIGH : LOW);

      state.idx = (state.idx + (state.clockBPM > 0 ? 1 : -1)) % 32;
    }
  } else {
    state.lastTick = 0;
    state.idx = 0;
    digitalWrite(LED_BUILTIN, LOW);
    digitalWrite(D2, LOW);
    digitalWrite(D3, LOW);
  }
}

void didChangeClockBPM(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.clockBPM, (unsigned char*)characteristic.value(), characteristic.valueSize());
  Serial.print("didChangeClockBPM: ");
  Serial.println(state.clockBPM);
}

void didChangePattern(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.nextPattern, (unsigned char*)characteristic.value(), characteristic.valueSize());
  Serial.println("didChangePattern");
}

void didChangeValueA(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueA, (unsigned char*)characteristic.value(), characteristic.valueSize());
  Serial.print("didChangeValueA: ");
  Serial.println(state.valueA);
}

void didChangeValueB(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.valueB, (unsigned char*)characteristic.value(), characteristic.valueSize());
  Serial.print("didChangeValueB: ");
  Serial.println(state.valueB);
}

void didChangeControls(BLEDevice central, BLECharacteristic characteristic) {
  memcpy(&state.controls, (unsigned char*)characteristic.value(), characteristic.valueSize());
  Serial.println("didChangeControls");
}

void initPWM() {
  nrfx_pwm_config_t config = {
    .output_pins  = {
      32 + 15, // Arduino pin 4
      32 + 13, // Arduino pin 5
      NRFX_PWM_PIN_NOT_USED,
      NRFX_PWM_PIN_NOT_USED,
    },
    .irq_priority = 7,
    .base_clock   = NRF_PWM_CLK_4MHz,
    .count_mode   = NRF_PWM_MODE_UP,
    .top_value    = 256,
    .load_mode    = NRF_PWM_LOAD_INDIVIDUAL,
    .step_mode    = NRF_PWM_STEP_AUTO,
  };
  nrfx_pwm_init(&pwm, &config, NULL);
}

void setPWM(float a, float b) {
  (*seq_values).channel_0 = a * 255;
  (*seq_values).channel_1 = b * 255;
  (void)nrfx_pwm_simple_playback(&pwm, &seq, 1, NRFX_PWM_FLAG_LOOP);
}
