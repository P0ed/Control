#include "nrfx_pwm.h"

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

static void initPWM() {
  nrfx_pwm_config_t config = {
    .output_pins  = {
      31, // A4
      2, // A5
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

static void setPWM(unsigned char a, unsigned char b) {
  (*seq_values).channel_0 = 255 - a;
  (*seq_values).channel_1 = 255 - b;
  (void)nrfx_pwm_simple_playback(&pwm, &seq, 1, NRFX_PWM_FLAG_LOOP);
}
